import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/guide_repository.dart';
import '../../services/bird_recognition/bird_recognition_service.dart';
import '../../services/bird_recognition/labels.dart';
import '../../services/species_guide/region_species_service.dart';
import '../../services/species_guide/species_guide.dart';

/// What the user picked on the download screen.
class EncyclopediaRequest {
  const EncyclopediaRequest({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.languages,
    required this.withPhotos,
  });

  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<GuideLanguage> languages;
  final bool withPhotos;

  /// Rough download size: ~0.6 KB of text per language and ~90 KB per photo.
  int estimateBytes(int species) =>
      species * (languages.length * 600 + (withPhotos ? 90000 : 0));
}

sealed class EncyclopediaJob {
  const EncyclopediaJob();
}

class JobIdle extends EncyclopediaJob {
  const JobIdle();
}

/// Running the geo model over the chosen area.
class JobFindingSpecies extends EncyclopediaJob {
  const JobFindingSpecies(this.progress);
  final double progress;
}

/// Species found; waiting for the user to confirm the download.
class JobPreview extends EncyclopediaJob {
  const JobPreview(this.request, this.species);
  final EncyclopediaRequest request;
  final List<ModelLabel> species;
}

class JobDownloading extends EncyclopediaJob {
  const JobDownloading(this.stage, this.done, this.total, {this.packId});
  final String stage;
  final int done;
  final int total;

  /// The saved area being updated; null for a new download.
  final int? packId;
  double get progress => total == 0 ? 0 : done / total;
}

class JobDone extends EncyclopediaJob {
  const JobDone(
    this.speciesCount, {
    required this.packId,
    this.failedPhotos = 0,
    this.updated = false,
  });
  final int speciesCount;

  /// The area that was downloaded or updated.
  final int packId;

  /// Photos that could not be downloaded (offline, HTTP error, …).
  final int failedPhotos;

  /// True when an existing area was updated rather than newly downloaded.
  final bool updated;
}

class JobFailed extends EncyclopediaJob {
  const JobFailed(this.message, {this.packId});
  final String message;

  /// The saved area whose update failed; null for a new download.
  final int? packId;
}

/// Finds the birds of an area and downloads their descriptions (chosen
/// languages) and photos for offline use.
class EncyclopediaDownloadController extends Notifier<EncyclopediaJob> {
  bool _cancelled = false;

  @override
  EncyclopediaJob build() => const JobIdle();

  bool get isBusy => state is JobFindingSpecies || state is JobDownloading;

  void reset() {
    if (!isBusy) state = const JobIdle();
  }

  void cancel() {
    _cancelled = true;
    state = const JobIdle();
  }

  Future<void> preview(EncyclopediaRequest request) async {
    _cancelled = false;
    if (ref.read(wikimediaUserAgentProvider) == null) {
      state = const JobFailed(
        'Online species info is not configured in this build (missing '
        'Wikimedia contact in AppConfig).',
      );
      return;
    }
    state = const JobFindingSpecies(0);
    try {
      final species = await ref
          .read(regionSpeciesServiceProvider)
          .speciesNear(
            latitude: request.latitude,
            longitude: request.longitude,
            radiusKm: request.radiusKm,
            onProgress: (p) {
              if (!_cancelled) state = JobFindingSpecies(p);
            },
          );
      if (_cancelled) return;
      state = JobPreview(request, species);
    } on ModelNotInstalledException {
      state = const JobFailed(
        'Download the bird sound model first (Listen tab) — the '
        'Encyclopedia uses its location model to find local birds.',
      );
    } catch (e) {
      state = JobFailed('Could not find species for this area: $e');
    }
  }

  Future<void> download() async {
    final preview = state;
    if (preview is! JobPreview) return;
    await _run(preview.request, [
      for (final s in preview.species)
        EncyclopediaSpecies(
          scientificName: s.scientificName,
          commonName: s.commonName,
        ),
    ]);
  }

  /// Re-runs the download of a saved area in place: same species, languages
  /// and photo choice. Cached descriptions and photos are skipped, and photos
  /// that failed earlier are tried again.
  Future<void> update(EncyclopediaPack pack) async {
    if (isBusy) return;
    if (ref.read(wikimediaUserAgentProvider) == null) {
      state = JobFailed(
        'Online species info is not configured in this build (missing '
        'Wikimedia contact in AppConfig).',
        packId: pack.id,
      );
      return;
    }
    final species = await ref
        .read(guideRepositoryProvider)
        .packSpecies(pack.id);
    await _run(
      EncyclopediaRequest(
        name: pack.name,
        latitude: pack.latitude,
        longitude: pack.longitude,
        radiusKm: pack.radiusKm,
        languages: pack.languages,
        withPhotos: pack.withPhotos,
      ),
      species,
      packId: pack.id,
    );
  }

  /// Downloads descriptions and photos for [species]; saves a new pack unless
  /// [packId] names an existing one being updated.
  Future<void> _run(
    EncyclopediaRequest request,
    List<EncyclopediaSpecies> species, {
    int? packId,
  }) async {
    _cancelled = false;
    final guide = await ref.read(speciesGuideProvider.future);
    final repo = ref.read(guideRepositoryProvider);
    final photos = ref.read(referencePhotoServiceProvider);
    var failedPhotos = 0;
    try {
      for (final lang in request.languages) {
        final items = [
          for (final s in species)
            if (guide[s.scientificName]?.text(lang)?.articleTitle
                case final title?)
              (scientificName: s.scientificName, title: title),
        ];
        final label = lang == GuideLanguage.ru ? 'Русский' : 'English';
        final stage = 'Descriptions · $label';
        state = JobDownloading(stage, 0, items.length, packId: packId);
        await repo.downloadDescriptions(
          items,
          lang,
          isCancelled: () => _cancelled,
          onProgress: (done) {
            if (!_cancelled) {
              state = JobDownloading(stage, done, items.length, packId: packId);
            }
          },
        );
        if (_cancelled) return;
      }

      if (request.withPhotos) {
        final withPhoto = [
          for (final s in species) ?guide[s.scientificName]?.photo,
        ];
        var done = 0;
        state = JobDownloading('Photos', 0, withPhoto.length, packId: packId);
        // An explicit download is worth retrying photos that failed earlier.
        photos.forgetFailures();
        // A few parallel downloads; each photo is fetched at most once.
        final queue = [...withPhoto];
        Future<void> worker() async {
          while (queue.isNotEmpty && !_cancelled) {
            if (await photos.get(queue.removeLast()) == null) failedPhotos++;
            done++;
            if (!_cancelled) {
              state = JobDownloading(
                'Photos',
                done,
                withPhoto.length,
                packId: packId,
              );
            }
          }
        }

        await Future.wait([worker(), worker(), worker()]);
        if (_cancelled) return;
        ref.invalidate(referencePhotoProvider);
      }

      final id =
          packId ??
          await repo.createPack(
            name: request.name,
            latitude: request.latitude,
            longitude: request.longitude,
            radiusKm: request.radiusKm,
            languages: request.languages,
            withPhotos: request.withPhotos,
            species: species,
          );
      ref.invalidate(descriptionProvider);
      state = JobDone(
        species.length,
        packId: id,
        failedPhotos: failedPhotos,
        updated: packId != null,
      );
    } catch (e) {
      state = JobFailed(
        'Download stopped: $e. Already downloaded items are kept; '
        '${packId == null ? 'try again' : 'tap Update'} to continue.',
        packId: packId,
      );
    }
  }
}

/// "12 photos could not be downloaded — tap Update to retry".
String failedPhotosText(int count, {required bool ru}) => ru
    ? '$count фото не удалось скачать — нажмите «Обновить», чтобы повторить'
    : '$count ${count == 1 ? 'photo' : 'photos'} could not be downloaded — '
          'tap Update to retry';

final regionSpeciesServiceProvider = Provider<RegionSpeciesService>(
  (ref) => RegionSpeciesService(ref.read(modelManagerProvider)),
);

final encyclopediaDownloadProvider =
    NotifierProvider<EncyclopediaDownloadController, EncyclopediaJob>(
      EncyclopediaDownloadController.new,
    );

final encyclopediaPacksProvider = StreamProvider<List<EncyclopediaPack>>(
  (ref) => ref.watch(guideRepositoryProvider).watchPacks(),
);

final encyclopediaSpeciesProvider = StreamProvider<List<EncyclopediaSpecies>>(
  (ref) => ref.watch(guideRepositoryProvider).watchEncyclopediaSpecies(),
);
