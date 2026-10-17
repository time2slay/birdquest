import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../progress/progress_widgets.dart';
import '../progress/rarity.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/illustrations.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/theme_toggle.dart';
import 'cover_picker.dart';
import '../export/export_sheet.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);
    final stats =
        ref.watch(collectionStatsProvider).value ?? CollectionStats.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bird Collection'),
        actions: [
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push('/achievements'),
          ),
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => showExportSheet(context),
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: collection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load your collection',
            message: '$e',
          ),
        ),
        data: (entries) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.lg,
              ),
              sliver: SliverToBoxAdapter(child: _StatsHeader(stats: stats)),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.auto_stories_outlined,
                  illustration: Illustrations.emptyCollection,
                  title: 'Your field journal is empty',
                  message:
                      'Birds appear here after you confirm an encounter. '
                      'Listen for birds, tap one you heard, then Save discovery.',
                  action: FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Start listening'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  0,
                  Space.lg,
                  Space.xxl,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: Space.md,
                    crossAxisSpacing: Space.md,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, i) =>
                      _CollectionCard(entry: entries[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});
  final CollectionStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Space.lg,
        horizontal: Space.sm,
      ),
      decoration: forestCardDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        colors: const [Color(0xFF1E3F27), Color(0xFF2F5D3A)],
      ),
      child: Row(
        children: [
          _Stat(value: stats.uniqueSpecies, label: 'Species'),
          _divider(),
          _Stat(value: stats.encounters, label: 'Encounters'),
          _divider(),
          _Stat(value: stats.photos, label: 'Photos'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white24);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: Motion.slow,
            builder: (_, v, _) => Text(
              '$v',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  const _CollectionCard({required this.entry});
  final CollectionEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rarity = ref.watch(collectedRarityProvider)[entry.speciesId];
    return Card(
      shape: rarity == null || rarity == Rarity.common
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              side: BorderSide(color: rarity.color, width: 2.5),
            ),
      child: InkWell(
        onTap: () => context.push('/species/${entry.speciesId}'),
        onLongPress: () => showCoverPicker(context, ref, entry),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'collection-${entry.speciesId}',
                    child: BirdImage(
                      name: entry.commonName,
                      scientificName: entry.scientificName,
                      coverPhotoPath: entry.coverPhotoPath,
                      referenceImage: entry.referenceImage,
                      cacheWidth: 480,
                    ),
                  ),
                  if (entry.allDemo)
                    const Positioned(top: 8, right: 8, child: DemoBadge()),
                  if (rarity != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: RarityChip(rarity, dense: true),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.md,
                Space.md,
                Space.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speciesDisplayName(
                      ref,
                      entry.scientificName,
                      entry.commonName,
                    ),
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discovered ${entry.encounterCount} '
                    '${entry.encounterCount == 1 ? 'time' : 'times'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: context.nature.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.photoCount} '
                        '${entry.photoCount == 1 ? 'photo' : 'photos'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
