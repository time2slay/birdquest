import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../services/location_service.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_map.dart';
import '../../shared/widgets/common.dart';
import 'encyclopedia_download_controller.dart';

/// Choose an area (tap the map) and languages, preview how many birds live
/// there, then download their descriptions and photos.
class EncyclopediaDownloadScreen extends ConsumerStatefulWidget {
  const EncyclopediaDownloadScreen({super.key});

  @override
  ConsumerState<EncyclopediaDownloadScreen> createState() =>
      _EncyclopediaDownloadScreenState();
}

class _EncyclopediaDownloadScreenState
    extends ConsumerState<EncyclopediaDownloadScreen> {
  static const _radii = [25.0, 100.0, 300.0];
  final _map = MapController();
  final _name = TextEditingController();
  LatLng _center = const LatLng(50, 10);
  double _radiusKm = 100;
  late final Set<GuideLanguage> _langs = {ref.read(guideLanguageProvider)};
  bool _photos = true;
  bool _voices = false;
  bool _located = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(encyclopediaDownloadProvider.notifier).reset(),
    );
    _locate();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final pos = await LocationService.coarsePosition();
    if (!mounted || pos == null) return;
    setState(() {
      _center = LatLng(pos.latitude, pos.longitude);
      _located = true;
    });
    _map.move(_center, 7);
  }

  bool get _ru => ref.read(guideLanguageProvider) == GuideLanguage.ru;

  String get _defaultName =>
      '${_ru ? 'Область' : 'Area'} '
      '${_center.latitude.toStringAsFixed(1)}°, '
      '${_center.longitude.toStringAsFixed(1)}°';

  EncyclopediaRequest _request() => EncyclopediaRequest(
    name: _name.text.trim().isEmpty ? _defaultName : _name.text.trim(),
    latitude: _center.latitude,
    longitude: _center.longitude,
    radiusKm: _radiusKm,
    languages: GuideLanguage.values.where(_langs.contains).toList(),
    withPhotos: _photos,
    withVoices: _voices,
  );

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(encyclopediaDownloadProvider);
    final controller = ref.read(encyclopediaDownloadProvider.notifier);
    final theme = Theme.of(context);
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final busy = job is JobFindingSpecies || job is JobDownloading;
    final scheme = theme.colorScheme;

    ref.listen(encyclopediaDownloadProvider, (_, next) {
      if (next is JobDone && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              [
                ru
                    ? 'Скачано: ${next.speciesCount} видов'
                    : 'Downloaded ${next.speciesCount} species',
                if (next.failedPhotos > 0)
                  failedPhotosText(next.failedPhotos, ru: ru),
                if (next.failedVoices > 0)
                  failedVoicesText(next.failedVoices, ru: ru),
              ].join('. '),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(ru ? 'Скачать энциклопедию' : 'Download encyclopedia'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: BirdMap(
              controller: _map,
              initialCenter: _center,
              initialZoom: 4,
              onTap: busy
                  ? null
                  : (_, p) {
                      setState(() => _center = p);
                      controller.reset();
                    },
              layers: [
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _center,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderColor: scheme.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 40,
                        color: scheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Space.lg),
              children: [
                Text(
                  _located
                      ? (ru
                            ? 'Нажмите на карту, чтобы выбрать центр области.'
                            : 'Tap the map to move the area.')
                      : (ru
                            ? 'Нажмите на карту, чтобы выбрать область.'
                            : 'Tap the map to choose your area.'),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.md),
                Text(
                  ru ? 'Радиус' : 'Radius',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Space.xs),
                SegmentedButton<double>(
                  segments: [
                    for (final r in _radii)
                      ButtonSegment(value: r, label: Text('${r.round()} km')),
                  ],
                  selected: {_radiusKm},
                  onSelectionChanged: busy
                      ? null
                      : (s) {
                          setState(() => _radiusKm = s.first);
                          controller.reset();
                        },
                ),
                const SizedBox(height: Space.md),
                Text(
                  ru ? 'Языки' : 'Languages',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    for (final (lang, label) in const [
                      (GuideLanguage.en, 'English'),
                      (GuideLanguage.ru, 'Русский'),
                    ])
                      FilterChip(
                        label: Text(label),
                        selected: _langs.contains(lang),
                        onSelected: busy
                            ? null
                            : (on) {
                                setState(() {
                                  if (on) {
                                    _langs.add(lang);
                                  } else if (_langs.length > 1) {
                                    _langs.remove(lang);
                                  }
                                });
                                controller.reset();
                              },
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _photos,
                  onChanged: busy
                      ? null
                      : (v) {
                          setState(() => _photos = v);
                          controller.reset();
                        },
                  title: Text(ru ? 'Фотографии' : 'Photos'),
                  subtitle: Text(
                    ru
                        ? 'Одно фото на вид с Wikimedia Commons'
                        : 'One photo per species from Wikimedia Commons',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _voices,
                  onChanged: busy
                      ? null
                      : (v) {
                          setState(() => _voices = v);
                          controller.reset();
                        },
                  title: Text(ru ? 'Голоса' : 'Voices'),
                  subtitle: Text(
                    ru
                        ? 'Одна эталонная запись на вид (~0,7 МБ), для '
                              'прослушивания и викторины офлайн'
                        : 'One reference recording per species (~0.7 MB), '
                              'for listening and the quiz offline',
                  ),
                ),
                TextField(
                  controller: _name,
                  enabled: !busy,
                  decoration: InputDecoration(
                    labelText: ru
                        ? 'Название (необязательно)'
                        : 'Name (optional)',
                    hintText: _defaultName,
                  ),
                ),
                const SizedBox(height: Space.lg),
                _JobPanel(
                  job: job,
                  guide: ref.watch(speciesGuideProvider).value,
                  ru: ru,
                  onFind: () => controller.preview(_request()),
                  onDownload: controller.download,
                  onCancel: controller.cancel,
                ),
                const SizedBox(height: Space.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobPanel extends StatelessWidget {
  const _JobPanel({
    required this.job,
    required this.guide,
    required this.ru,
    required this.onFind,
    required this.onDownload,
    required this.onCancel,
  });

  final EncyclopediaJob job;

  /// For the size estimate (how many species have a recording).
  final SpeciesGuide? guide;
  final bool ru;
  final VoidCallback onFind;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  String _mb(EncyclopediaRequest request, Iterable<String> species) {
    final g = guide;
    final withVoice = g == null
        ? 0
        : species.where((s) => g[s]?.voices.isNotEmpty ?? false).length;
    final bytes = request.estimateBytes(
      species.length,
      withVoiceCount: withVoice,
    );
    return (bytes / 1e6).toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (job) {
      JobIdle() || JobDone() => FilledButton.icon(
        onPressed: onFind,
        icon: const Icon(Icons.travel_explore_rounded),
        label: Text(ru ? 'Найти птиц в области' : 'Find birds in this area'),
      ),
      JobFindingSpecies(:final progress) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ru ? 'Ищем местных птиц…' : 'Finding local birds…'),
          const SizedBox(height: Space.sm),
          LinearProgressIndicator(value: progress),
        ],
      ),
      JobPreview(:final request, :final species) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ru
                ? '${species.length} видов птиц · около '
                      '${_mb(request, species.map((x) => x.scientificName))} МБ'
                : '${species.length} bird species · about '
                      '${_mb(request, species.map((x) => x.scientificName))} MB',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(
            ru
                ? 'Тексты: Википедия (CC BY-SA 4.0). Фото: Wikimedia Commons.'
                : 'Text: Wikipedia (CC BY-SA 4.0). Photos: Wikimedia Commons.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: species.isEmpty ? null : onDownload,
            icon: const Icon(Icons.download_rounded),
            label: Text(ru ? 'Скачать' : 'Download'),
          ),
        ],
      ),
      JobDownloading(
        :final stage,
        :final done,
        :final total,
        :final progress,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$stage · $done / $total'),
            const SizedBox(height: Space.sm),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: Space.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text(ru ? 'Отмена' : 'Cancel'),
              ),
            ),
          ],
        ),
      JobFailed(:final message) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NoticeCard(
            icon: Icons.error_outline_rounded,
            tone: NoticeTone.error,
            title: ru ? 'Не получилось' : 'Something went wrong',
            message: message,
          ),
          const SizedBox(height: Space.sm),
          FilledButton(
            onPressed: onFind,
            child: Text(ru ? 'Попробовать снова' : 'Try again'),
          ),
        ],
      ),
    };
  }
}
