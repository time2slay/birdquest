import 'dart:convert';
import 'dart:io';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/models.dart';
import 'package:birdquest/data/repositories/sighting_repository.dart';
import 'package:birdquest/features/encyclopedia/encyclopedia_download_controller.dart';
import 'package:birdquest/features/encyclopedia/encyclopedia_screen.dart';
import 'package:birdquest/features/map/sightings_map_screen.dart';
import 'package:birdquest/services/bird_recognition/labels.dart';
import 'package:birdquest/services/bird_recognition/model_manager.dart';
import 'package:birdquest/services/species_guide/reference_photo_service.dart';
import 'package:birdquest/services/species_guide/reference_voice_service.dart';
import 'package:birdquest/services/species_guide/region_species_service.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:birdquest/services/species_guide/wikipedia_client.dart';
import 'package:birdquest/shared/theme/app_theme.dart';
import 'package:birdquest/shared/widgets/bird_map.dart';
import 'package:birdquest/shared/widgets/guide_description.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

const _ua = 'BirdQuest/1.0 (test@example.org; offline bird field guide)';

final _guide = SpeciesGuide({
  'Turdus merula': const GuideEntry(
    texts: {
      GuideLanguage.en: GuideText(articleTitle: 'Common blackbird'),
      GuideLanguage.ru: GuideText(
        articleTitle: 'Чёрный дрозд',
        name: 'Чёрный дрозд',
      ),
    },
    photo: GuidePhoto(
      fileName: 'Turdus_merula_2.jpg',
      author: 'Andreas Trepte',
      license: 'CC BY-SA 2.5',
    ),
    voices: [
      GuideVoice(
        fileName: 'Turdus_merula_song.ogg',
        author: 'Diana Tudor',
        license: 'CC BY 4.0',
      ),
      GuideVoice(
        fileName: 'Turdus_merula_call.ogg',
        author: 'Diana Tudor',
        license: 'CC BY 4.0',
      ),
    ],
  ),
  // English article only, no photo.
  'Erithacus rubecula': const GuideEntry(
    texts: {GuideLanguage.en: GuideText(articleTitle: 'European robin')},
  ),
});

const _labels = [
  ModelLabel(
    index: 0,
    id: 'eurbla',
    scientificName: 'Turdus merula',
    commonName: 'Common Blackbird',
    taxonClass: 'Aves',
    taxonOrder: 'Passeriformes',
  ),
  ModelLabel(
    index: 1,
    id: 'eurrob1',
    scientificName: 'Erithacus rubecula',
    commonName: 'European Robin',
    taxonClass: 'Aves',
    taxonOrder: 'Passeriformes',
  ),
];

/// Stands in for the geo model: the same two birds everywhere.
class _FakeRegion extends RegionSpeciesService {
  _FakeRegion() : super(ModelManager(Directory.systemTemp));

  @override
  Future<List<ModelLabel>> speciesNear({
    required double latitude,
    required double longitude,
    required double radiusKm,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return _labels;
  }
}

const _extracts = {
  'Common blackbird': 'The common blackbird is a species of true thrush.',
  'European robin': 'The European robin is a small insectivorous bird.',
  'Чёрный дрозд': 'Чёрный дрозд — певчая птица семейства дроздовых.',
};

/// Fake Wikipedia (TextExtracts) and Commons (thumbnails). Records requests.
/// Commons answers HTTP 503 while [commonsDown] returns true.
MockClient _wikimedia(List<http.Request> log, {bool Function()? commonsDown}) =>
    MockClient((req) async {
      log.add(req);
      if (req.url.host.endsWith('wikipedia.org')) {
        final titles = req.url.queryParameters['titles']!.split('|');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'query': {
                'pages': [
                  for (final t in titles) {'title': t, 'extract': _extracts[t]},
                ],
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (req.url.host == 'commons.wikimedia.org') {
        if (commonsDown?.call() ?? false) return http.Response('', 503);
        final audio = req.url.path.endsWith('.ogg');
        return http.Response.bytes(
          List.filled(64, 1),
          200,
          headers: {'content-type': audio ? 'audio/ogg' : 'image/jpeg'},
        );
      }
      return http.Response('', 404);
    });

void main() {
  late AppDatabase db;
  late Directory root;
  late AppPaths paths;
  late SharedPreferences prefs;
  late List<http.Request> requests;
  late bool commonsDown;

  // main() does this in the app.
  setUpAll(initializeDateFormatting);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = memoryDatabase();
    requests = [];
    commonsDown = false;
    root = Directory.systemTemp.createTempSync('birdquest_flows_');
    paths = AppPaths(
      mediaRoot: Directory('${root.path}/media')..createSync(),
      modelsDir: Directory('${root.path}/models')..createSync(),
      tempDir: Directory('${root.path}/tmp')..createSync(),
    );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  List overrides({String? userAgent = _ua, String language = 'en'}) => [
    appPathsProvider.overrideWithValue(paths),
    databaseProvider.overrideWithValue(db),
    sharedPreferencesProvider.overrideWithValue(prefs),
    deviceLanguageProvider.overrideWithValue(language),
    speciesGuideProvider.overrideWith((ref) async => _guide),
    wikimediaUserAgentProvider.overrideWithValue(userAgent),
    wikipediaClientProvider.overrideWith(
      (ref) =>
          WikipediaClient(userAgent: userAgent, client: _wikimedia(requests)),
    ),
    referencePhotoServiceProvider.overrideWith(
      (ref) => ReferencePhotoService(
        paths.speciesPhotosDir,
        userAgent: userAgent,
        client: _wikimedia(requests, commonsDown: () => commonsDown),
      ),
    ),
    referenceVoiceServiceProvider.overrideWith(
      (ref) => ReferenceVoiceService(
        paths.speciesVoicesDir,
        userAgent: userAgent,
        client: _wikimedia(requests, commonsDown: () => commonsDown),
      ),
    ),
    regionSpeciesServiceProvider.overrideWith((ref) => _FakeRegion()),
    mapStyleProvider.overrideWith(
      (ref, _) async => throw const SocketException('offline in tests'),
    ),
  ];

  group('Encyclopedia download', () {
    test(
      'downloads EN + RU descriptions and photos, then saves the pack',
      () async {
        final c = ProviderContainer(overrides: [...overrides()]);
        addTearDown(c.dispose);
        final job = c.read(encyclopediaDownloadProvider.notifier);
        final states = <EncyclopediaJob>[];
        c.listen(encyclopediaDownloadProvider, (_, s) => states.add(s));

        await job.preview(
          const EncyclopediaRequest(
            name: 'Home',
            latitude: 52.52,
            longitude: 13.40,
            radiusKm: 25,
            languages: [GuideLanguage.en, GuideLanguage.ru],
            withPhotos: true,
          ),
        );
        final preview = c.read(encyclopediaDownloadProvider);
        expect(preview, isA<JobPreview>());
        expect((preview as JobPreview).species, hasLength(2));

        await job.download();
        final done = c.read(encyclopediaDownloadProvider);
        expect(done, isA<JobDone>(), reason: '$done');
        expect((done as JobDone).speciesCount, 2);
        expect(states.whereType<JobDownloading>().map((s) => s.stage).toSet(), {
          'Descriptions · English',
          'Descriptions · Русский',
          'Photos',
        });

        final repo = c.read(guideRepositoryProvider);
        expect(
          (await repo.cachedDescription(
            'Turdus merula',
            GuideLanguage.ru,
          ))!.text,
          _extracts['Чёрный дрозд'],
        );
        expect(
          (await repo.cachedDescription(
            'Erithacus rubecula',
            GuideLanguage.en,
          ))!.text,
          _extracts['European robin'],
        );
        expect(
          await repo.cachedDescription('Erithacus rubecula', GuideLanguage.ru),
          isNull,
          reason: 'no Russian article for the robin',
        );

        final photo = await c
            .read(referencePhotoServiceProvider)
            .cached(_guide['Turdus merula']!.photo!);
        expect(photo, isNotNull, reason: 'photo cached for offline use');

        final pack = (await repo.watchPacks().first).single;
        expect(pack.name, 'Home');
        expect(pack.speciesCount, 2);
        expect(pack.languages, [GuideLanguage.en, GuideLanguage.ru]);
        expect(pack.withPhotos, isTrue);

        expect(requests.map((r) => r.url.host).toSet(), {
          'en.wikipedia.org',
          'ru.wikipedia.org',
          'commons.wikimedia.org',
        });
        expect(
          requests.every((r) => r.headers['User-Agent'] == _ua),
          isTrue,
          reason: 'Wikimedia rejects requests without a contact User-Agent',
        );

        // A second download of the same area needs no Wikipedia requests.
        requests.clear();
        await job.preview(preview.request);
        await job.download();
        expect(c.read(encyclopediaDownloadProvider), isA<JobDone>());
        expect(
          requests.where((r) => r.url.host.endsWith('wikipedia.org')),
          isEmpty,
        );
      },
    );

    test('with Voices it keeps the best recording of each species', () async {
      final c = ProviderContainer(overrides: [...overrides()]);
      addTearDown(c.dispose);
      final job = c.read(encyclopediaDownloadProvider.notifier);
      final states = <EncyclopediaJob>[];
      c.listen(encyclopediaDownloadProvider, (_, s) => states.add(s));
      const request = EncyclopediaRequest(
        name: 'Home',
        latitude: 52.52,
        longitude: 13.40,
        radiusKm: 25,
        languages: [GuideLanguage.en],
        withPhotos: false,
        withVoices: true,
      );
      expect(
        request.estimateBytes(2, withVoiceCount: 1),
        2 * 600 + EncyclopediaRequest.voiceBytes,
      );
      await job.preview(request);
      await job.download();
      final done = c.read(encyclopediaDownloadProvider);
      expect(done, isA<JobDone>(), reason: '$done');
      expect((done as JobDone).failedVoices, 0);
      expect(
        states.whereType<JobDownloading>().map((s) => s.stage),
        contains('Voices'),
      );
      final voices = c.read(referenceVoiceServiceProvider);
      final entry = _guide['Turdus merula']!;
      expect(await voices.cached(entry.voices.first), isNotNull);
      expect(
        await voices.cached(entry.voices.last),
        isNull,
        reason: 'only the best recording per species, to keep areas small',
      );
      final pack =
          (await c.read(guideRepositoryProvider).watchPacks().first).single;
      expect(pack.withVoices, isTrue);
    });

    test('without a Wikimedia contact it stops before any request', () async {
      final c = ProviderContainer(overrides: [...overrides(userAgent: null)]);
      addTearDown(c.dispose);
      await c
          .read(encyclopediaDownloadProvider.notifier)
          .preview(
            const EncyclopediaRequest(
              name: 'Home',
              latitude: 52.52,
              longitude: 13.40,
              radiusKm: 25,
              languages: [GuideLanguage.en],
              withPhotos: false,
            ),
          );
      expect(c.read(encyclopediaDownloadProvider), isA<JobFailed>());
      expect(requests, isEmpty);
    });
  });

  group('Encyclopedia update', () {
    const request = EncyclopediaRequest(
      name: 'Home',
      latitude: 52.52,
      longitude: 13.40,
      radiusKm: 25,
      languages: [GuideLanguage.en, GuideLanguage.ru],
      withPhotos: true,
    );

    test('counts failed photos, and Update retries them in place', () async {
      final c = ProviderContainer(overrides: [...overrides()]);
      addTearDown(c.dispose);
      final job = c.read(encyclopediaDownloadProvider.notifier);
      final repo = c.read(guideRepositoryProvider);
      final photos = c.read(referencePhotoServiceProvider);
      final blackbird = _guide['Turdus merula']!.photo!;

      commonsDown = true;
      await job.preview(request);
      await job.download();
      final done = c.read(encyclopediaDownloadProvider);
      expect(done, isA<JobDone>(), reason: '$done');
      expect((done as JobDone).failedPhotos, 1);
      expect(done.updated, isFalse);
      expect(await photos.cached(blackbird), isNull);
      final pack = (await repo.watchPacks().first).single;
      expect(done.packId, pack.id);

      // Commons is back; the failed photo is retried this session.
      commonsDown = false;
      requests.clear();
      await job.update(pack);
      final updated = c.read(encyclopediaDownloadProvider);
      expect(updated, isA<JobDone>(), reason: '$updated');
      expect((updated as JobDone).failedPhotos, 0);
      expect(updated.updated, isTrue);
      expect(updated.packId, pack.id);
      expect(updated.speciesCount, 2);
      expect(await photos.cached(blackbird), isNotNull);

      final packs = await repo.watchPacks().first;
      expect(packs, hasLength(1), reason: 'no duplicate pack');
      expect(packs.single.speciesCount, 2);
      expect(packs.single.languages, [GuideLanguage.en, GuideLanguage.ru]);
      expect(requests.map((r) => r.url.host), [
        'commons.wikimedia.org',
      ], reason: 'cached descriptions are not fetched again');

      // Nothing left to fetch: a second update makes no requests at all.
      requests.clear();
      await job.update(packs.single);
      expect(c.read(encyclopediaDownloadProvider), isA<JobDone>());
      expect(requests, isEmpty);
    });

    testWidgets('Encyclopedia shows failed photos and retries with Update', (
      tester,
    ) async {
      final c = ProviderContainer(overrides: [...overrides()]);
      addTearDown(c.dispose);
      commonsDown = true;
      await tester.runAsync(() async {
        final job = c.read(encyclopediaDownloadProvider.notifier);
        await job.preview(request);
        await job.download();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const EncyclopediaScreen(),
          ),
        ),
      );
      // Waits for real async work (database, fake network) until [done].
      Future<void> settle(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
      }

      await settle(
        () => find
            .textContaining('could not be downloaded')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('1 photo could not be downloaded — tap Update to retry'),
        findsOneWidget,
      );

      commonsDown = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await settle(() => find.text('Area updated').evaluate().isNotEmpty);
      expect(find.textContaining('could not be downloaded'), findsNothing);
      expect(find.text('Area updated'), findsOneWidget);
      expect(
        await tester.runAsync(
          () => c
              .read(referencePhotoServiceProvider)
              .cached(_guide['Turdus merula']!.photo!),
        ),
        isNotNull,
      );

      // The same action is in each area's menu.
      await tester.tap(find.byTooltip('Area actions'));
      await tester.pumpAndSettle();
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Delete area'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('Russian phone shows the Russian name and Wikipedia text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides(language: 'ru')],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  Text(
                    speciesDisplayName(
                      ref,
                      'Turdus merula',
                      'Common Blackbird',
                    ),
                  ),
                  const GuideDescription(scientificName: 'Turdus merula'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(find.text('Чёрный дрозд'), findsOneWidget);
    expect(find.text(_extracts['Чёрный дрозд']!), findsOneWidget);
    expect(find.text('Wikipedia (RU) · CC BY-SA 4.0'), findsOneWidget);
    expect(find.text('Читать'), findsOneWidget);
    expect(requests.single.url.host, 'ru.wikipedia.org');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('saved sightings with GPS become one map pin per area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final media = (await tester.runAsync(tempMediaStore))!;
    final sightings = SightingRepository(db, media);
    await tester.runAsync(() async {
      // Two visits to the same park, a few metres apart, on different days.
      await sightings.saveEncounter(
        EncounterDraft(
          species: blackbird,
          confirmedAt: DateTime(2026, 5, 1, 7),
          latitude: 52.5201,
          longitude: 13.4051,
        ),
      );
      await sightings.saveEncounter(
        EncounterDraft(
          species: blackbird,
          confirmedAt: DateTime(2026, 5, 4, 7),
          latitude: 52.5203,
          longitude: 13.4049,
        ),
      );
      // Saved without GPS: counts in the collection, not on the map.
      await sightings.saveEncounter(
        EncounterDraft(species: robin, confirmedAt: DateTime(2026, 5, 4, 8)),
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overrides(userAgent: null)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SightingsMapScreen(),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    final pin = find.bySemanticsLabel(
      // The placeholder image's label is merged in after the pin's own.
      RegExp(r'^Common Blackbird, 2 sightings'),
    );
    expect(pin, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('European Robin')), findsNothing);
    expect(find.text('Your sightings appear here'), findsNothing);
    expect(
      find.textContaining('Map tiles need an internet connection'),
      findsOneWidget,
      reason: 'pins still show when tiles are offline',
    );

    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(find.text('Spotted 2 times in this area'), findsOneWidget);
    expect(
      find.text('By BirdQuest players · currently your sightings only'),
      findsOneWidget,
    );
    expect(find.text('May 1, 2026 – May 4, 2026'), findsOneWidget);
    expect(find.text('Turdus merula'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => media.root.delete(recursive: true));
    semantics.dispose();
  });
}
