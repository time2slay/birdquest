import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../features/progress/rarity.dart';
import '../../services/species_guide/similar_species.dart';
import '../../services/species_guide/species_guide.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'bird_image.dart';
import 'common.dart';
import 'guide_description.dart';
import 'photo_credit.dart';

/// Facts below a species description: flight speed, seasonality in the
/// user's region and look-alike species. Each part hides itself when there
/// is no data.
class SpeciesExtras extends ConsumerStatefulWidget {
  const SpeciesExtras({super.key, required this.scientificName});

  final String scientificName;

  @override
  ConsumerState<SpeciesExtras> createState() => _SpeciesExtrasState();
}

class _SpeciesExtrasState extends ConsumerState<SpeciesExtras> {
  @override
  void initState() {
    super.initState();
    // Seasonality, rarity badges and local look-alikes need the region
    // profile; build it quietly if it is missing (cheap when cached).
    if (ref.read(regionProfileProvider) == null) {
      Future.microtask(
        () => ref.read(regionProfileProvider.notifier).ensureHere(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scientificName = widget.scientificName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlightSpeedTile(scientificName: scientificName),
        SeasonalityChart(scientificName: scientificName),
        SimilarSpeciesStrip(scientificName: scientificName),
      ],
    );
  }
}

String speedText(GuideSpeed s, {required bool ru}) {
  final kmh = ru ? 'км/ч' : 'km/h';
  final h = s.horizontal;
  final d = s.dive;
  if (s.source == SpeedSource.family && h != null) {
    return ru
        ? 'до ~$h $kmh · типично для семейства'
        : 'up to ~$h $kmh · typical of its family';
  }
  return [
    if (h != null) ru ? 'до $h $kmh в полёте' : 'up to $h $kmh in flight',
    if (d != null) ru ? 'в пике до $d $kmh' : 'up to $d $kmh in a dive',
  ].join(' · ');
}

class FlightSpeedTile extends ConsumerWidget {
  const FlightSpeedTile({super.key, required this.scientificName});

  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(speciesGuideProvider).value?[scientificName]?.speed;
    if (speed == null || speed.top == 0) return const SizedBox.shrink();
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: Material(
        color: context.nature.ochreContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => openExternal(context, speed.sourceUrl),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  color: context.nature.onOchreContainer,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ru ? 'Скорость полёта' : 'Flight speed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.nature.onOchreContainer,
                        ),
                      ),
                      Text(
                        speedText(speed, ru: ru),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: context.nature.onOchreContainer,
                        ),
                      ),
                      Text(
                        speed.source == SpeedSource.wikidata
                            ? 'Wikidata'
                            : ru
                            ? 'Википедия: список птиц по скорости полёта'
                            : 'Wikipedia: list of birds by flight speed',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: context.nature.onOchreContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 12 monthly bars from the BirdNET+ geo model for the user's region.
class SeasonalityChart extends ConsumerWidget {
  const SeasonalityChart({super.key, required this.scientificName, this.now});

  final String scientificName;

  /// Highlights this month; defaults to today.
  final DateTime? now;

  static const _en = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];
  static const _ru = [
    'Я',
    'Ф',
    'М',
    'А',
    'М',
    'И',
    'И',
    'А',
    'С',
    'О',
    'Н',
    'Д',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = ref.watch(seasonalityProvider(scientificName));
    if (months == null) return const SizedBox.shrink();
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final theme = Theme.of(context);
    final peak = months.fold<double>(0, (a, b) => b > a ? b : a);
    final current = (now ?? DateTime.now()).month - 1;
    final rarity = ref.watch(regionProfileProvider)?.rarityOf(scientificName);
    final color = rarity?.color ?? theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(ru ? 'Когда встречается здесь' : 'When it is here'),
        if (peak < 0.03)
          Text(
            ru
                ? 'В вашем районе не ожидается — встреча была бы редкостью.'
                : 'Not expected in your area — a sighting would be special.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var m = 0; m < 12; m++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Semantics(
                        label:
                            '${ru ? _ruMonth[m] : _enMonth[m]}: '
                            '${(months[m] * 100).round()}%',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: Motion.medium,
                              height: 4 + 52 * (months[m] / peak),
                              decoration: BoxDecoration(
                                color: m == current
                                    ? color
                                    : color.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (ru ? _ru : _en)[m],
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: m == current
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            ru
                ? 'Вероятность встречи по месяцам в вашем районе (модель BirdNET+)'
                : 'Chance to meet it each month in your area (BirdNET+ model)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  static const _enMonth = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _ruMonth = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', //
    'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];
}

/// Look-alikes to rule out: same genus, then family, then order.
final similarSpeciesProvider = Provider.family<List<SimilarSpecies>, String>((
  ref,
  scientificName,
) {
  final guide = ref.watch(speciesGuideProvider).value;
  if (guide == null) return const [];
  final profile = ref.watch(regionProfileProvider);
  final collection = ref.watch(collectionProvider).value ?? const [];
  return similarSpecies(
    scientificName,
    guide,
    regional: profile?.species.keys.toSet() ?? const {},
    collected: {for (final c in collection) c.scientificName},
    orderOf: {
      for (final s in profile?.species.values ?? const <RegionSpecies>[])
        s.scientificName: s.taxonOrder,
    },
  );
});

/// English name for a species we only know by its scientific name.
String englishNameFor(WidgetRef ref, String scientificName) {
  final profile = ref.watch(regionProfileProvider);
  final fromProfile = profile?.species[scientificName]?.commonName;
  if (fromProfile != null) return fromProfile;
  final collection = ref.watch(collectionProvider).value ?? const [];
  for (final c in collection) {
    if (c.scientificName == scientificName) return c.commonName;
  }
  final title = ref
      .watch(speciesGuideProvider)
      .value?[scientificName]
      ?.text(GuideLanguage.en)
      ?.articleTitle;
  if (title == null) return scientificName;
  return title[0].toUpperCase() + title.substring(1);
}

class SimilarSpeciesStrip extends ConsumerWidget {
  const SimilarSpeciesStrip({super.key, required this.scientificName});

  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(similarSpeciesProvider(scientificName));
    if (similar.isEmpty) return const SizedBox.shrink();
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final theme = Theme.of(context);
    final profile = ref.watch(regionProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(ru ? 'Похожие виды' : 'Similar species'),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (context, i) {
              final s = similar[i];
              final en = englishNameFor(ref, s.scientificName);
              final name = speciesDisplayName(ref, s.scientificName, en);
              final local =
                  profile?.species.containsKey(s.scientificName) ?? false;
              return SizedBox(
                width: 116,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.push(
                      '/guide/species/${Uri.encodeComponent(s.scientificName)}'
                      '?name=${Uri.encodeQueryComponent(en)}',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 84,
                          width: double.infinity,
                          child: BirdImage(
                            name: en,
                            scientificName: s.scientificName,
                            showPlaceholderLabel: false,
                            cacheWidth: 240,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            local
                                ? (ru ? 'есть рядом' : 'found nearby')
                                : switch (s.kinship) {
                                    Kinship.genus =>
                                      ru ? 'тот же род' : 'same genus',
                                    Kinship.family =>
                                      ru ? 'то же семейство' : 'same family',
                                    Kinship.order =>
                                      ru ? 'тот же отряд' : 'same order',
                                  },
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: local
                                  ? theme.colorScheme.primary
                                  : context.nature.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
