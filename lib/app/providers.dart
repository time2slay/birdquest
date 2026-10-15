import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/media_store.dart';
import '../data/models.dart';
import '../data/repositories/collection_repository.dart';
import '../data/repositories/sighting_repository.dart';
import '../services/bird_recognition/bird_recognition_service.dart';
import '../services/bird_recognition/birdnet_service.dart';
import '../services/bird_recognition/demo_service.dart';
import '../services/bird_recognition/model_manager.dart';
import '../services/location_service.dart';

/// Filesystem locations used by the app. Resolved once in `main`.
class AppPaths {
  const AppPaths({
    required this.mediaRoot,
    required this.modelsDir,
    required this.tempDir,
  });

  /// User photos and saved clips (backed up with the app's documents).
  final Directory mediaRoot;

  /// Downloaded recognition model files.
  final Directory modelsDir;

  /// Unsaved photos and clips from the current session.
  final Directory tempDir;

  static Future<AppPaths> resolve() async {
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final cache = await getTemporaryDirectory();
    final paths = AppPaths(
      mediaRoot: Directory(p.join(docs.path, 'media')),
      modelsDir: Directory(p.join(support.path, 'models')),
      tempDir: Directory(p.join(cache.path, 'birdquest')),
    );
    for (final d in [paths.mediaRoot, paths.modelsDir, paths.tempDir]) {
      await d.create(recursive: true);
    }
    return paths;
  }
}

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('Override appPathsProvider in main()'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

/// Whether predictions are limited to species plausible at the user's
/// approximate location and week. On by default; persisted.
class GeoFilterSetting extends Notifier<bool> {
  static const _key = 'geo_filter_enabled';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final geoFilterEnabledProvider = NotifierProvider<GeoFilterSetting, bool>(
  GeoFilterSetting.new,
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final mediaStoreProvider = Provider<MediaStore>(
  (ref) => MediaStore(ref.watch(appPathsProvider).mediaRoot),
);

final sightingRepositoryProvider = Provider<SightingRepository>(
  (ref) => SightingRepository(
    ref.watch(databaseProvider),
    ref.watch(mediaStoreProvider),
  ),
);

final collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => CollectionRepository(ref.watch(databaseProvider)),
);

final modelManagerProvider = Provider<ModelManager>((ref) {
  final manager = ModelManager(ref.watch(appPathsProvider).modelsDir);
  ref.onDispose(manager.dispose);
  return manager;
});

final modelStatusProvider = StreamProvider<ModelStatus>((ref) async* {
  final manager = ref.watch(modelManagerProvider);
  yield await manager.refresh();
  yield* manager.statusStream;
});

/// Whether the simulated recognizer is active. Off by default.
class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(
  DemoModeNotifier.new,
);

final recognitionServiceProvider = Provider<BirdRecognitionService>((ref) {
  final BirdRecognitionService service = ref.watch(demoModeProvider)
      ? DemoRecognitionService()
      : BirdNetRecognitionService(
          modelManager: ref.watch(modelManagerProvider),
          geoFilterEnabled: ref.watch(geoFilterEnabledProvider),
          locate: LocationService.coarsePosition,
        );
  ref.onDispose(service.dispose);
  return service;
});

final collectionProvider = StreamProvider<List<CollectionEntry>>(
  (ref) => ref.watch(collectionRepositoryProvider).watchCollection(),
);

final collectionStatsProvider = StreamProvider<CollectionStats>(
  (ref) => ref.watch(collectionRepositoryProvider).watchStats(),
);

final collectionEntryProvider = StreamProvider.family<CollectionEntry?, int>(
  (ref, speciesId) =>
      ref.watch(collectionRepositoryProvider).watchEntry(speciesId),
);

final encountersProvider = StreamProvider.family<List<Encounter>, int>(
  (ref, speciesId) =>
      ref.watch(sightingRepositoryProvider).watchEncounters(speciesId),
);

final encounterProvider = StreamProvider.family<Encounter?, int>(
  (ref, sightingId) =>
      ref.watch(sightingRepositoryProvider).watchEncounter(sightingId),
);
