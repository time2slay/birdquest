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
      appBar: AppBar(title: const Text('About & licenses')),
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
          Text('Privacy', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          const Text(
            'Audio, photos and locations stay on this phone. BirdQuest has no '
            'account, no cloud sync and no analytics. The only network '
            'request is the one-time model download you start yourself. '
            'The location filter reads your approximate position on the '
            'phone and never stores or sends it.',
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
