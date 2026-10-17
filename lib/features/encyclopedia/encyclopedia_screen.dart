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

    ref.listen(encyclopediaDownloadProvider, (_, next) {
      if (next is JobDone &&
          next.updated &&
          next.failedPhotos == 0 &&
          next.failedVoices == 0 &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ru ? 'Область обновлена' : 'Area updated')),
        );
        ref.read(encyclopediaDownloadProvider.notifier).reset();
      }
    });

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
          IconButton(
            tooltip: ru ? 'Угадай по голосу' : 'Guess by voice',
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => context.push('/quiz'),
          ),
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
                      _JobStatus(packs: packs, ru: ru),
                      SizedBox(
                        height: 96,
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
    final job = ref.watch(encyclopediaDownloadProvider);
    final busy = job is JobFindingSpecies || job is JobDownloading;
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_PackAction>(
            tooltip: ru ? 'Действия' : 'Area actions',
            iconColor: Colors.white70,
            onSelected: (action) => switch (action) {
              _PackAction.update =>
                ref.read(encyclopediaDownloadProvider.notifier).update(pack),
              _PackAction.delete => _delete(context, ref, ru),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _PackAction.update,
                enabled: !busy,
                child: ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: Text(ru ? 'Обновить' : 'Update'),
                  subtitle: Text(
                    ru ? 'Докачать недостающее' : 'Download what is missing',
                  ),
                ),
              ),
              PopupMenuItem(
                value: _PackAction.delete,
                enabled: !busy,
                child: ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(ru ? 'Удалить' : 'Delete area'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, bool ru) async {
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
  }
}

enum _PackAction { update, delete }

/// Progress of an area update, and what is left to retry after a download.
class _JobStatus extends ConsumerWidget {
  const _JobStatus({required this.packs, required this.ru});
  final List<EncyclopediaPack> packs;
  final bool ru;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(encyclopediaDownloadProvider);
    final controller = ref.read(encyclopediaDownloadProvider.notifier);
    EncyclopediaPack? packOf(int? id) =>
        packs.where((p) => p.id == id).firstOrNull;

    Widget actions(EncyclopediaPack? pack) => Wrap(
      spacing: Space.sm,
      children: [
        if (pack != null)
          FilledButton.icon(
            onPressed: () => controller.update(pack),
            icon: const Icon(Icons.sync_rounded),
            label: Text(ru ? 'Обновить' : 'Update'),
          ),
        TextButton(
          onPressed: controller.reset,
          child: Text(ru ? 'Скрыть' : 'Dismiss'),
        ),
      ],
    );

    final Widget? card = switch (job) {
      JobDownloading(
        :final packId?,
        :final stage,
        :final done,
        :final total,
        :final progress,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${ru ? 'Обновление' : 'Updating'} '
              '${packOf(packId)?.name ?? ''} · $stage · $done / $total',
            ),
            const SizedBox(height: Space.sm),
            LinearProgressIndicator(value: progress),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.cancel,
                child: Text(ru ? 'Отмена' : 'Cancel'),
              ),
            ),
          ],
        ),
      JobDone(:final packId, :final failedPhotos, :final failedVoices)
          when failedPhotos > 0 || failedVoices > 0 =>
        NoticeCard(
          icon: Icons.cloud_off_rounded,
          title: packOf(packId)?.name ?? (ru ? 'Область' : 'Area'),
          message: [
            if (failedPhotos > 0) failedPhotosText(failedPhotos, ru: ru),
            if (failedVoices > 0) failedVoicesText(failedVoices, ru: ru),
          ].join('. '),
          actions: [actions(packOf(packId))],
        ),
      JobFailed(:final packId?, :final message) => NoticeCard(
        icon: Icons.error_outline_rounded,
        tone: NoticeTone.error,
        title: ru ? 'Не удалось обновить' : 'Update failed',
        message: message,
        actions: [actions(packOf(packId))],
      ),
      _ => null,
    };
    if (card == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: card,
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
