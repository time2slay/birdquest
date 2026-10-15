import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import 'app_config.dart';
import '../data/media_store.dart';
import '../data/models.dart';
import '../data/repositories/collection_repository.dart';
import '../data/repositories/guide_repository.dart';
import '../data/repositories/sighting_repository.dart';
import '../services/bird_recognition/bird_recognition_service.dart';
import '../services/bird_recognition/birdnet_service.dart';
import '../services/bird_recognition/demo_service.dart';
import '../services/bird_recognition/model_manager.dart';
import '../services/location_service.dart';
import '../services/species_guide/reference_photo_service.dart';
import '../services/species_guide/species_guide.dart';
import '../services/species_guide/wikipedia_client.dart';

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

  /// Cached Wikimedia Commons reference photos.
  Directory get speciesPhotosDir =>
      Directory(p.join(modelsDir.parent.path, 'species_photos'));

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

/// Light, dark or follow the system. Persisted; defaults to system.
class ThemeModeSetting extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(
  ThemeModeSetting.new,
);

/// Language for species names and descriptions: follow the phone, or force
/// English / Russian. Persisted.
enum GuideLanguageMode { auto, en, ru }

class GuideLanguageSetting extends Notifier<GuideLanguageMode> {
  static const _key = 'guide_language';

  @override
  GuideLanguageMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return GuideLanguageMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => GuideLanguageMode.auto,
    );
  }

  Future<void> set(GuideLanguageMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final guideLanguageModeProvider =
    NotifierProvider<GuideLanguageSetting, GuideLanguageMode>(
      GuideLanguageSetting.new,
    );

/// The phone's language; overridable in tests.
final deviceLanguageProvider = Provider<String>(
  (ref) => PlatformDispatcher.instance.locale.languageCode,
);

final guideLanguageProvider = Provider<GuideLanguage>((ref) {
  return switch (ref.watch(guideLanguageModeProvider)) {
    GuideLanguageMode.en => GuideLanguage.en,
    GuideLanguageMode.ru => GuideLanguage.ru,
    GuideLanguageMode.auto =>
      ref.watch(deviceLanguageProvider) == 'ru'
          ? GuideLanguage.ru
          : GuideLanguage.en,
  };
});

/// Bundled offline field guide (Wikipedia text, Commons photo credits).
final speciesGuideProvider = FutureProvider<SpeciesGuide>((ref) async {
  try {
    return await SpeciesGuide.loadAsset();
  } catch (_) {
    return SpeciesGuide.empty;
  }
});

/// Whether species photos and descriptions may be fetched from Wikimedia
/// on demand (each species at most once; cached afterwards).
class PhotoDownloadSetting extends Notifier<bool> {
  static const _key = 'download_species_photos';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final photoDownloadsEnabledProvider =
    NotifierProvider<PhotoDownloadSetting, bool>(PhotoDownloadSetting.new);

/// User-Agent for Wikimedia requests, or null when this build has no
/// contact configured (then nothing is fetched). Overridable in tests.
final wikimediaUserAgentProvider = Provider<String?>(
  (ref) => AppConfig.hasWikimediaContact ? AppConfig.userAgent : null,
);

final referencePhotoServiceProvider = Provider<ReferencePhotoService>((ref) {
  final service = ReferencePhotoService(
    ref.watch(appPathsProvider).speciesPhotosDir,
    userAgent: ref.watch(wikimediaUserAgentProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// A species' reference photo file plus its credit, or null when none is
/// available (no licensed photo, downloads off and not cached, or offline).
final referencePhotoProvider =
    FutureProvider.family<({File file, GuidePhoto photo})?, String>((
      ref,
      scientificName,
    ) async {
      final guide = await ref.watch(speciesGuideProvider.future);
      final photo = guide[scientificName]?.photo;
      if (photo == null) return null;
      final service = ref.watch(referencePhotoServiceProvider);
      final file = ref.watch(photoDownloadsEnabledProvider)
          ? await service.get(photo)
          : await service.cached(photo);
      return file == null ? null : (file: file, photo: photo);
    });

final wikipediaClientProvider = Provider<WikipediaClient>((ref) {
  final client = WikipediaClient(
    userAgent: ref.watch(wikimediaUserAgentProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

final guideRepositoryProvider = Provider<GuideRepository>(
  (ref) => GuideRepository(
    ref.watch(databaseProvider),
    ref.watch(wikipediaClientProvider),
  ),
);

/// Description for a species in the chosen language: cached, or fetched once
/// from Wikipedia when online species info is enabled.
final descriptionProvider =
    FutureProvider.family<GuideDescriptionData?, String>((
      ref,
      scientificName,
    ) async {
      final guide = await ref.watch(speciesGuideProvider.future);
      return ref
          .watch(guideRepositoryProvider)
          .description(
            scientificName,
            guide[scientificName],
            ref.watch(guideLanguageProvider),
            allowNetwork: ref.watch(photoDownloadsEnabledProvider),
          );
    });

/// Display name of a species in the chosen guide language.
final speciesNameProvider =
    Provider.family<String, ({String scientificName, String fallback})>((
      ref,
      key,
    ) {
      final guide = ref.watch(speciesGuideProvider).value ?? SpeciesGuide.empty;
      return guide.nameFor(
        key.scientificName,
        key.fallback,
        ref.watch(guideLanguageProvider),
      );
    });

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

final locatedSightingsProvider = StreamProvider<List<LocatedSighting>>(
  (ref) => ref.watch(sightingRepositoryProvider).watchLocatedSightings(),
);

final encounterProvider = StreamProvider.family<Encounter?, int>(
  (ref, sightingId) =>
      ref.watch(sightingRepositoryProvider).watchEncounter(sightingId),
);
