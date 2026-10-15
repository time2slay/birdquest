import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../collection/cover_picker.dart';

/// A species' personal discovery history.
class SpeciesHistoryScreen extends ConsumerWidget {
  const SpeciesHistoryScreen({super.key, required this.speciesId});

  final int speciesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(collectionEntryProvider(speciesId));
    final encounters = ref.watch(encountersProvider(speciesId));
    final theme = Theme.of(context);

    return entry.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No encounters left',
              message:
                  'All encounters for this species were deleted, so it '
                  'is no longer in your collection.',
            ),
          );
        }
        final fmt = DateFormat.yMMMd();
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF2F5D3A),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    tooltip: 'Choose cover photo',
                    icon: const Icon(Icons.wallpaper_rounded),
                    onPressed: () => showCoverPicker(context, ref, entry),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'collection-${entry.speciesId}',
                    child: BirdImage(
                      name: entry.commonName,
                      scientificName: entry.scientificName,
                      showCredit: entry.coverPhotoPath == null,
                      coverPhotoPath: entry.coverPhotoPath,
                      referenceImage: entry.referenceImage,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(Space.lg),
                sliver: SliverList.list(
                  children: [
                    Text(
                      entry.commonName,
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(
                      entry.scientificName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: context.nature.inkMuted,
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Row(
                      children: [
                        _Fact(
                          label: 'Encounters',
                          value: '${entry.encounterCount}',
                        ),
                        _Fact(
                          label: 'First seen',
                          value: fmt.format(entry.firstSeen),
                        ),
                        _Fact(
                          label: 'Last seen',
                          value: fmt.format(entry.lastSeen),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    GuideDescription(
                      scientificName: entry.scientificName,
                      fallback: entry.description,
                    ),
                    const SectionHeader('Encounters'),
                  ],
                ),
              ),
              encounters.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(child: Text('$e')),
                data: (list) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Space.sm),
                    itemBuilder: (context, i) => _EncounterTile(
                      encounter: list[i],
                      number: list.length - i,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EncounterTile extends StatelessWidget {
  const _EncounterTile({required this.encounter, required this.number});

  final Encounter encounter;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat.yMMMEd().add_Hm().format(encounter.confirmedAt);
    return Card(
      child: InkWell(
        onTap: () => context.push('/encounter/${encounter.id}'),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: context.nature.mossContainer,
                    child: Text(
                      '#$number',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(when, style: theme.textTheme.titleSmall),
                  ),
                  if (encounter.isDemo) const DemoBadge(),
                ],
              ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.md,
                runSpacing: Space.xs,
                children: [
                  if (encounter.modelScore != null)
                    ScoreChip(score: encounter.modelScore!, dense: true),
                  _Meta(
                    icon: Icons.photo_library_outlined,
                    text: '${encounter.photos.length}',
                  ),
                  if (encounter.clipPath != null)
                    const _Meta(icon: Icons.graphic_eq_rounded, text: 'Sound'),
                  if (encounter.hasLocation)
                    _Meta(
                      icon: Icons.place_outlined,
                      text:
                          '${encounter.latitude!.toStringAsFixed(3)}, '
                          '${encounter.longitude!.toStringAsFixed(3)}',
                    ),
                ],
              ),
              if (encounter.photos.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: encounter.photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: SizedBox.square(
                        dimension: 72,
                        child: MediaPhoto(
                          path: encounter.photos[i].path,
                          cacheWidth: 216,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: context.nature.inkMuted),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
