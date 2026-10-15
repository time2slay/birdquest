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
  const JobDownloading(this.stage, this.done, this.total);
  final String stage;
  final int done;
  final int total;
  double get progress => total == 0 ? 0 : done / total;
}

class JobDone extends EncyclopediaJob {
  const JobDone(this.speciesCount);
  final int speciesCount;
}

class JobFailed extends EncyclopediaJob {
  const JobFailed(this.message);
  final String message;
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
    final request = preview.request;
    final species = preview.species;
    _cancelled = false;
    final guide = await ref.read(speciesGuideProvider.future);
    final repo = ref.read(guideRepositoryProvider);
    final photos = ref.read(referencePhotoServiceProvider);
    try {
      for (final lang in request.languages) {
        final items = [
          for (final s in species)
            if (guide[s.scientificName]?.text(lang)?.articleTitle
                case final title?)
              (scientificName: s.scientificName, title: title),
        ];
        final label = lang == GuideLanguage.ru ? 'Русский' : 'English';
        state = JobDownloading('Descriptions · $label', 0, items.length);
        await repo.downloadDescriptions(
          items,
          lang,
          isCancelled: () => _cancelled,
          onProgress: (done) {
            if (!_cancelled) {
              state = JobDownloading(
                'Descriptions · $label',
                done,
                items.length,
              );
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
        state = JobDownloading('Photos', 0, withPhoto.length);
        // A few parallel downloads; each photo is fetched at most once.
        final queue = [...withPhoto];
        Future<void> worker() async {
          while (queue.isNotEmpty && !_cancelled) {
            await photos.get(queue.removeLast());
            done++;
            if (!_cancelled) {
              state = JobDownloading('Photos', done, withPhoto.length);
            }
          }
        }

        await Future.wait([worker(), worker(), worker()]);
        if (_cancelled) return;
        ref.invalidate(referencePhotoProvider);
      }

      await repo.createPack(
        name: request.name,
        latitude: request.latitude,
        longitude: request.longitude,
        radiusKm: request.radiusKm,
        languages: request.languages,
        withPhotos: request.withPhotos,
        species: [
          for (final s in species)
            EncyclopediaSpecies(
              scientificName: s.scientificName,
              commonName: s.commonName,
            ),
        ],
      );
      ref.invalidate(descriptionProvider);
      state = JobDone(species.length);
    } catch (e) {
      state = JobFailed(
        'Download stopped: $e. Already downloaded items are kept; try '
        'again to continue.',
      );
    }
  }
}

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
