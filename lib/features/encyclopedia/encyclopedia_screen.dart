import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/guide_repository.dart';
import '../../services/species_guide/species_guide.dart';
import '../../app/providers.dart';
import '../../shared/theme/illustrations.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/theme_toggle.dart';
import 'encyclopedia_download_controller.dart';

/// Optional offline field guide: only shows content the user chose to
/// download (area + languages).
class EncyclopediaScreen extends ConsumerStatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  ConsumerState<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends ConsumerState<EncyclopediaScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(encyclopediaPacksProvider).value ?? const [];
    final species = ref.watch(encyclopediaSpeciesProvider).value ?? const [];
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? species
        : species.where((s) {
            final local = speciesDisplayName(
              ref,
              s.scientificName,
              s.commonName,
            );
            return s.commonName.toLowerCase().contains(q) ||
                s.scientificName.toLowerCase().contains(q) ||
                local.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(ru ? 'Энциклопедия' : 'Encyclopedia'),
        actions: [
          const ThemeToggleButton(),
          if (packs.isNotEmpty)
            IconButton(
              tooltip: ru ? 'Скачать ещё область' : 'Download another area',
              icon: const Icon(Icons.add_location_alt_outlined),
              onPressed: () => context.push('/guide/download'),
            ),
        ],
      ),
      body: packs.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.menu_book_outlined,
                  illustration: Illustrations.offlineModel,
                  title: ru
                      ? 'Энциклопедия по желанию'
                      : 'Your field guide, on demand',
                  message: ru
                      ? 'Выберите область на карте и языки — BirdQuest '
                            'скачает описания и фото всех птиц, которые там '
                            'встречаются, для работы без интернета.'
                      : 'Pick an area on the map and the languages you want. '
                            'BirdQuest downloads descriptions and photos of '
                            'every bird that lives there, for offline use.',
                  action: FilledButton.icon(
                    onPressed: () => context.push('/guide/download'),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(ru ? 'Выбрать область' : 'Choose an area'),
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.sm,
                    Space.lg,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: packs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: Space.sm),
                          itemBuilder: (_, i) => _PackCard(pack: packs[i]),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: ru
                              ? 'Поиск среди ${species.length} птиц'
                              : 'Search ${species.length} birds',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.xxl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Space.sm),
                    itemBuilder: (_, i) => _SpeciesTile(species: filtered[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PackCard extends ConsumerWidget {
  const _PackCard({required this.pack});
  final EncyclopediaPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(Space.md),
      decoration: forestCardDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pack.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pack.speciesCount} ${ru ? 'видов' : 'species'} · '
                  '${pack.languages.map((l) => l.name.toUpperCase()).join('+')}'
                  ' · ${pack.radiusKm.round()} km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: ru ? 'Удалить' : 'Delete area',
            color: Colors.white70,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(ru ? 'Удалить область?' : 'Delete this area?'),
                  content: Text(
                    ru
                        ? 'Виды из других скачанных областей останутся.'
                        : 'Species that are also in other downloaded areas '
                              'stay available.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(ru ? 'Отмена' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(ru ? 'Удалить' : 'Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(guideRepositoryProvider).deletePack(pack.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SpeciesTile extends ConsumerWidget {
  const _SpeciesTile({required this.species});
  final EncyclopediaSpecies species;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = speciesDisplayName(
      ref,
      species.scientificName,
      species.commonName,
    );
    return Card(
      child: InkWell(
        onTap: () => context.push(
          '/guide/species/${Uri.encodeComponent(species.scientificName)}'
          '?name=${Uri.encodeQueryComponent(species.commonName)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: BirdImage(
                  name: species.commonName,
                  scientificName: species.scientificName,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  showPlaceholderLabel: false,
                  cacheWidth: 168,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall),
                    Text(
                      species.scientificName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
