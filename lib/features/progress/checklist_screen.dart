import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../achievements/achievements.dart';
import 'progress_widgets.dart';
import 'rarity.dart';

/// Friendly names for the most common bird orders.
const _orderNames = <String, ({String en, String ru})>{
  'Passeriformes': (en: 'Songbirds', ru: 'Воробьинообразные'),
  'Accipitriformes': (en: 'Hawks & eagles', ru: 'Ястребообразные'),
  'Falconiformes': (en: 'Falcons', ru: 'Соколообразные'),
  'Strigiformes': (en: 'Owls', ru: 'Совы'),
  'Piciformes': (en: 'Woodpeckers', ru: 'Дятлообразные'),
  'Anseriformes': (en: 'Ducks, geese & swans', ru: 'Гусеобразные'),
  'Charadriiformes': (en: 'Shorebirds & gulls', ru: 'Ржанкообразные'),
  'Columbiformes': (en: 'Pigeons & doves', ru: 'Голубеобразные'),
  'Cuculiformes': (en: 'Cuckoos', ru: 'Кукушкообразные'),
  'Pelecaniformes': (en: 'Herons & pelicans', ru: 'Пеликанообразные'),
  'Gruiformes': (en: 'Rails & cranes', ru: 'Журавлеобразные'),
  'Galliformes': (en: 'Gamebirds', ru: 'Курообразные'),
  'Coraciiformes': (en: 'Kingfishers & rollers', ru: 'Ракшеобразные'),
  'Apodiformes': (en: 'Swifts', ru: 'Стрижеобразные'),
  'Caprimulgiformes': (en: 'Nightjars', ru: 'Козодоеобразные'),
  'Psittaciformes': (en: 'Parrots', ru: 'Попугаеобразные'),
  'Bucerotiformes': (en: 'Hornbills & hoopoes', ru: 'Птицы-носороги'),
  'Podicipediformes': (en: 'Grebes', ru: 'Поганкообразные'),
  'Suliformes': (en: 'Cormorants', ru: 'Олушеобразные'),
  'Ciconiiformes': (en: 'Storks', ru: 'Аистообразные'),
};

String orderName(String order, GuideLanguage lang) {
  final n = _orderNames[order];
  if (n == null) return order;
  return lang == GuideLanguage.ru ? n.ru : n.en;
}

enum _Filter { all, found, missing }

/// Every bird of the user's region, grouped by order, with what they found.
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  _Filter _filter = _Filter.all;
  Rarity? _rarity;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(regionProfileProvider) == null) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await ref.read(regionProfileProvider.notifier).ensureHere();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final profile = ref.watch(regionProfileProvider);
    final facts = ref.watch(sightingFactsProvider).value ?? const [];
    final found = {for (final f in facts) f.scientificName};
    final theme = Theme.of(context);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(ru ? 'Птицы региона' : 'Regional checklist'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : NoticeCard(
                  icon: Icons.location_off_outlined,
                  title: ru ? 'Список недоступен' : 'Checklist unavailable',
                  message: ru
                      ? 'Нужны модель BirdNET (вкладка «Listen») и доступ к '
                            'местоположению.'
                      : 'Needs the BirdNET model (Listen tab) and location '
                            'access.',
                  actions: [
                    FilledButton(
                      onPressed: _refresh,
                      child: Text(ru ? 'Повторить' : 'Try again'),
                    ),
                  ],
                ),
        ),
      );
    }

    final all = profile.species.values.toList();
    final visible = all.where((s) {
      final has = found.contains(s.scientificName);
      if (_filter == _Filter.found && !has) return false;
      if (_filter == _Filter.missing && has) return false;
      if (_rarity != null && s.rarity != _rarity) return false;
      return true;
    }).toList();
    final byOrder = <String, List<RegionSpecies>>{};
    for (final s in visible) {
      (byOrder[s.taxonOrder] ??= []).add(s);
    }
    final orders = byOrder.keys.toList()
      ..sort((a, b) => byOrder[b]!.length.compareTo(byOrder[a]!.length));
    for (final list in byOrder.values) {
      list.sort((a, b) => b.mean.compareTo(a.mean));
    }
    final got = all.where((s) => found.contains(s.scientificName)).length;

    return Scaffold(
      appBar: AppBar(title: Text(ru ? 'Птицы региона' : 'Regional checklist')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  ru
                      ? 'Найдено $got из ${all.length}'
                      : 'Found $got of ${all.length}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  ru
                      ? 'Птицы, которые бывают рядом с вами хотя бы в один '
                            'месяц года (по модели BirdNET).'
                      : 'Birds that occur near you in at least one month of '
                            'the year (BirdNET geo model).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Space.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: all.isEmpty ? 0 : got / all.length,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: Space.md),
                SegmentedButton<_Filter>(
                  segments: [
                    ButtonSegment(
                      value: _Filter.all,
                      label: Text(ru ? 'Все' : 'All'),
                    ),
                    ButtonSegment(
                      value: _Filter.found,
                      label: Text(ru ? 'Найдены' : 'Found'),
                    ),
                    ButtonSegment(
                      value: _Filter.missing,
                      label: Text(ru ? 'Не найдены' : 'Missing'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: Space.sm),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    for (final r in Rarity.values.take(3))
                      FilterChip(
                        label: Text(
                          '${r.label(lang)} · '
                          '${all.where((s) => s.rarity == r).length}',
                        ),
                        avatar: Icon(r.icon, size: 16, color: r.color),
                        selected: _rarity == r,
                        onSelected: (on) =>
                            setState(() => _rarity = on ? r : null),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
              ],
            ),
          ),
          for (final order in orders) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  '${orderName(order, lang)} · '
                  '${byOrder[order]!.where((s) => found.contains(s.scientificName)).length}'
                  '/${byOrder[order]!.length}',
                ),
              ),
            ),
            SliverList.builder(
              itemCount: byOrder[order]!.length,
              itemBuilder: (context, i) {
                final s = byOrder[order]![i];
                final has = found.contains(s.scientificName);
                return ListTile(
                  leading: Icon(
                    has
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: has
                        ? theme.colorScheme.primary
                        : context.nature.inkMuted,
                  ),
                  title: Text(
                    speciesDisplayName(ref, s.scientificName, s.commonName),
                  ),
                  subtitle: Text(
                    s.scientificName,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  trailing: RarityChip(s.rarity, dense: true),
                  onTap: () => context.push(
                    '/guide/species/${Uri.encodeComponent(s.scientificName)}'
                    '?name=${Uri.encodeQueryComponent(s.commonName)}',
                  ),
                );
              },
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
        ],
      ),
    );
  }
}
