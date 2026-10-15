import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/models.dart';
import 'package:birdquest/features/scanner/scanner_controller.dart';
import 'package:birdquest/services/bird_recognition/bird_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Recognizer driven manually by the test.
class FakeRecognizer implements BirdRecognitionService {
  StreamController<RecognitionEvent>? controller;
  Object? startError;

  @override
  bool get isDemo => false;

  @override
  String get modelName => 'fake';

  @override
  Future<Stream<RecognitionEvent>> start() async {
    if (startError != null) throw startError!;
    controller = StreamController<RecognitionEvent>();
    return controller!.stream;
  }

  void emit(SpeciesInfo s, double score, {Float32List? window}) =>
      controller!.add(
        PredictionEvent(
          at: DateTime.now(),
          predictions: [Prediction(species: s, score: score)],
          window: window,
        ),
      );

  @override
  Future<void> stop() async {
    await controller?.close();
    controller = null;
  }

  @override
  Future<void> dispose() => stop();
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeRecognizer recognizer;
  late Directory root;

  setUp(() async {
    db = memoryDatabase();
    recognizer = FakeRecognizer();
    root = await Directory.systemTemp.createTemp('birdquest_ctrl_');
    final paths = AppPaths(
      mediaRoot: Directory('${root.path}/media')..createSync(),
      modelsDir: Directory('${root.path}/models')..createSync(),
      tempDir: Directory('${root.path}/tmp')..createSync(),
    );
    container = ProviderContainer(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        databaseProvider.overrideWithValue(db),
        recognitionServiceProvider.overrideWithValue(recognizer),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await root.delete(recursive: true);
  });

  ScannerController ctrl() =>
      container.read(scannerControllerProvider.notifier);
  ScannerState state() => container.read(scannerControllerProvider);
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<CollectionStats> stats() =>
      container.read(collectionRepositoryProvider).watchStats().first;

  test(
    'repeated detections of one species form one suggested encounter',
    () async {
      await ctrl().start();
      expect(state().isListening, isTrue);
      for (var i = 0; i < 10; i++) {
        recognizer.emit(kingfisher, 0.5 + i * 0.03);
      }
      recognizer.emit(robin, 0.42);
      await pump();

      expect(state().groups, hasLength(2));
      final group = state().groups[kingfisher.scientificName]!;
      expect(group.hits, 10);
      expect(group.bestScore, closeTo(0.77, 1e-9));
      expect(state().groups[robin.scientificName]!.isUncertain, isTrue);
    },
  );

  test('saving a group twice in one session counts once unless the user '
      'asks for a separate encounter', () async {
    await ctrl().start();
    for (var i = 0; i < 10; i++) {
      recognizer.emit(kingfisher, 0.8);
    }
    await pump();

    final first = await ctrl().saveEncounter(kingfisher.scientificName);
    final again = await ctrl().saveEncounter(kingfisher.scientificName);
    expect(again, first);
    expect((await stats()).encounters, 1);

    await ctrl().saveEncounter(kingfisher.scientificName, separate: true);
    expect((await stats()).encounters, 2);
    expect((await stats()).uniqueSpecies, 1);
  });

  test('a new session can add a new encounter of the same species', () async {
    await ctrl().start();
    recognizer.emit(kingfisher, 0.8);
    await pump();
    await ctrl().saveEncounter(kingfisher.scientificName);

    await ctrl().newSession();
    expect(state().groups, isEmpty);
    await ctrl().start();
    recognizer.emit(kingfisher, 0.7);
    await pump();
    await ctrl().saveEncounter(kingfisher.scientificName);

    expect((await stats()).encounters, 2);
  });

  test('pending photos and the best audio window are saved with the '
      'encounter', () async {
    await ctrl().start();
    recognizer.emit(robin, 0.6, window: Float32List(96000));
    recognizer.emit(
      robin,
      0.9,
      window: Float32List.fromList(List.filled(96000, 0.1)),
    );
    await pump();

    final photo = await fakePhoto(root);
    ctrl().addPendingPhoto(robin.scientificName, photo);
    final id = await ctrl().saveEncounter(robin.scientificName);

    final encounter = (await container
        .read(sightingRepositoryProvider)
        .watchEncounter(id)
        .first)!;
    expect(encounter.photos, hasLength(1));
    expect(encounter.clipPath, isNotNull);
    expect(encounter.modelScore, closeTo(0.9, 1e-9));
    expect(state().groups[robin.scientificName]!.pendingPhotos, isEmpty);
  });

  test(
    'pausing for the camera releases and then resumes the recognizer',
    () async {
      await ctrl().start();
      await ctrl().pauseForCamera();
      expect(state().status, ScannerStatus.paused);
      expect(recognizer.controller, isNull);

      await ctrl().resumeAfterCamera();
      expect(state().isListening, isTrue);
      expect(recognizer.controller, isNotNull);
    },
  );

  test('activating the location filter drops earlier out-of-range '
      'suggestions but keeps saved or photographed ones', () async {
    await ctrl().start();
    recognizer.emit(robin, 0.8);
    recognizer.emit(kingfisher, 0.8);
    recognizer.emit(blackbird, 0.8);
    await pump();
    await ctrl().saveEncounter(kingfisher.scientificName);
    ctrl().addPendingPhoto(blackbird.scientificName, await fakePhoto(root));

    recognizer.controller!.add(
      GeoFilterEvent(GeoFilterActive(1, (sci) => sci == 'Nobody here')),
    );
    await pump();

    expect(
      state().groups.keys,
      unorderedEquals([kingfisher.scientificName, blackbird.scientificName]),
    );
    expect(state().geoFilter, isA<GeoFilterActive>());
  });

  test(
    'missing permission and missing model are reported, not thrown',
    () async {
      recognizer.startError = const MicrophonePermissionException(
        permanentlyDenied: true,
      );
      await ctrl().start();
      expect(state().permissionDenied, isTrue);
      expect(state().permanentlyDenied, isTrue);
      expect(state().isListening, isFalse);

      recognizer.startError = const ModelNotInstalledException();
      await ctrl().start();
      expect(state().modelMissing, isTrue);
      expect(state().permissionDenied, isFalse);
    },
  );
}
