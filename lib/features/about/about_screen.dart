import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/bird_recognition/model_manager.dart';
import '../../shared/theme/tokens.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(modelStatusProvider).value;
    final manager = ref.read(modelManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & about')),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text('Recognition model', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Powered by BirdNET',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Space.xs),
                  const Text(
                    '${BirdNetModelSpec.name}\n'
                    'Developed by the K. Lisa Yang Center for Conservation '
                    'Bioacoustics (Cornell University), Chemnitz University of '
                    'Technology and Museum für Naturkunde Berlin.\n\n'
                    'Licensed under ${BirdNetModelSpec.license} '
                    '(creativecommons.org/licenses/by-sa/4.0). '
                    'Used unmodified; downloaded from ${BirdNetModelSpec.recordUrl}.\n\n'
                    'Kahl, S., Wood, C. M., Eibl, M., & Klinck, H. (2021). '
                    'BirdNET: A deep learning solution for avian diversity '
                    'monitoring. Ecological Informatics, 61, 101236.\n\n'
                    'The model is a developer preview provided "as is". '
                    'Identifications can be wrong — always use your own judgement.',
                  ),
                  const SizedBox(height: Space.md),
                  Text(switch (status) {
                    ModelInstalled() => 'Status: installed on this device',
                    ModelDownloading(:final progress) =>
                      'Status: downloading ${(progress * 100).round()}%',
                    ModelFailed(:final message) => 'Status: $message',
                    _ => 'Status: not downloaded',
                  }, style: theme.textTheme.labelLarge),
                  const SizedBox(height: Space.sm),
                  if (status is ModelInstalled)
                    OutlinedButton(
                      onPressed: manager.remove,
                      child: const Text('Remove models (frees ~81 MB)'),
                    )
                  else if (status is! ModelDownloading)
                    FilledButton(
                      onPressed: manager.download,
                      child: const Text('Download model'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: ref.watch(geoFilterEnabledProvider),
                  onChanged: (v) =>
                      ref.read(geoFilterEnabledProvider.notifier).set(v),
                  title: const Text('Filter by my location'),
                  subtitle: const Text(
                    'Hide species that do not occur near you at this time of '
                    'year. Uses your approximate location, on-device only.',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
                  child: Text(
                    '${GeoModelSpec.name}, licensed under '
                    '${GeoModelSpec.license}. ${GeoModelSpec.releaseUrl}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          Text('Appearance', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded),
                label: Text('Day'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded),
                label: Text('Night'),
              ),
            ],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: Space.xl),
          Text('Species guide', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          Text('Names and descriptions', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          SegmentedButton<GuideLanguageMode>(
            segments: const [
              ButtonSegment(value: GuideLanguageMode.auto, label: Text('Auto')),
              ButtonSegment(
                value: GuideLanguageMode.en,
                label: Text('English'),
              ),
              ButtonSegment(
                value: GuideLanguageMode.ru,
                label: Text('Русский'),
              ),
            ],
            selected: {ref.watch(guideLanguageModeProvider)},
            onSelectionChanged: (s) =>
                ref.read(guideLanguageModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Auto uses Russian when your phone is set to Russian, otherwise '
            'English.',
            style: theme.textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: ref.watch(photoDownloadsEnabledProvider),
            onChanged: (v) =>
                ref.read(photoDownloadsEnabledProvider.notifier).set(v),
            title: const Text('Download species photos'),
            subtitle: const Text(
              'Fetches one reference photo per species from Wikimedia '
              'Commons when you first see it, then keeps it on the phone. '
              'This tells Wikimedia which species you looked at.',
            ),
          ),
          const _PhotoCacheRow(),
          const SizedBox(height: Space.sm),
          Text(
            'Descriptions: Wikipedia (English, Russian), CC BY-SA 4.0. '
            'Names: Wikidata, CC0. Photos: Wikimedia Commons; the author '
            'and license are shown on each photo.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.xl),
          Text('Privacy', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          const Text(
            'Audio, photos and locations stay on this phone. BirdQuest has no '
            'account, no cloud sync and no analytics. The only network '
            'request is the one-time model download you start yourself. '
            'The location filter reads your approximate position on the '
            'phone and never stores or sends it. If species photos are on, '
            'the app also requests one photo per species from Wikimedia.',
          ),
          const SizedBox(height: Space.xl),
          Text('Images & code', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          const Text(
            'Bird pictures marked "Placeholder" are generated illustrations, '
            'not photographs, until licensed reference images are added. '
            'The audio pipeline design follows the BirdNET Live app '
            '(github.com/birdnet-team/birdnet-live-app, MIT License).',
          ),
          const SizedBox(height: Space.lg),
          OutlinedButton(
            onPressed: () =>
                showLicensePage(context: context, applicationName: 'BirdQuest'),
            child: const Text('Open-source licenses'),
          ),
          const SizedBox(height: Space.xl),
          Text('Demo data', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          const Text(
            'Encounters saved while demo mode was on are marked DEMO. '
            'You can remove all of them at once.',
          ),
          const SizedBox(height: Space.sm),
          OutlinedButton(
            onPressed: () async {
              await ref.read(sightingRepositoryProvider).deleteDemoData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo encounters deleted')),
                );
              }
            },
            child: const Text('Delete all demo encounters'),
          ),
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }
}

class _PhotoCacheRow extends ConsumerStatefulWidget {
  const _PhotoCacheRow();

  @override
  ConsumerState<_PhotoCacheRow> createState() => _PhotoCacheRowState();
}

class _PhotoCacheRowState extends ConsumerState<_PhotoCacheRow> {
  late Future<int> _size = ref.read(referencePhotoServiceProvider).cacheSize();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _size,
      builder: (context, snap) {
        final mb = ((snap.data ?? 0) / 1e6).toStringAsFixed(1);
        return Row(
          children: [
            Expanded(
              child: Text(
                'Cached photos: $mb MB',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: (snap.data ?? 0) == 0
                  ? null
                  : () async {
                      await ref
                          .read(referencePhotoServiceProvider)
                          .clearCache();
                      ref.invalidate(referencePhotoProvider);
                      setState(() {
                        _size = ref
                            .read(referencePhotoServiceProvider)
                            .cacheSize();
                      });
                    },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
