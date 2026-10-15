import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/tokens.dart';
import '../achievements/achievements.dart';
import 'progress.dart';
import 'rarity.dart';

/// Best rarity each collected species was saved with, by species id.
final collectedRarityProvider = Provider<Map<int, Rarity>>((ref) {
  final facts = ref.watch(sightingFactsProvider).value ?? const [];
  final best = <int, Rarity>{};
  for (final f in facts) {
    final r = Rarity.parse(f.rarity);
    if (r == null) continue;
    final prev = best[f.speciesId];
    if (prev == null || r.index > prev.index) best[f.speciesId] = r;
  }
  return best;
});

/// Small colored pill: "◆ Rare".
class RarityChip extends ConsumerWidget {
  const RarityChip(this.rarity, {super.key, this.dense = false});
  final Rarity rarity;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(guideLanguageProvider);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: rarity.color.withValues(alpha: 0.16),
        border: Border.all(color: rarity.color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rarity.icon, size: dense ? 11 : 14, color: rarity.color),
          const SizedBox(width: 4),
          Text(
            rarity.label(lang),
            style: TextStyle(
              color: rarity.color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rarity of a species in the user's region, or nothing while unknown.
class SpeciesRarityChip extends ConsumerWidget {
  const SpeciesRarityChip(this.scientificName, {super.key});
  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(regionProfileProvider)?.rarityOf(scientificName);
    if (r == null) return const SizedBox.shrink();
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    return Tooltip(
      message: ru
          ? 'Насколько птица редка в вашем регионе'
          : 'How rare it is in your region',
      child: RarityChip(r),
    );
  }
}

/// Level, XP bar, streak and today's quests at a glance; opens Progress.
class LevelCard extends ConsumerWidget {
  const LevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(playerLevelProvider);
    final quests = ref.watch(todayQuestsProvider);
    final streak = ref.watch(questStreakProvider);
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    if (level == null) return const SizedBox(height: 72);
    final theme = Theme.of(context);
    final done = quests?.where((q) => q.completed).length ?? 0;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => context.push('/progress'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.md,
            Space.sm,
            Space.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '${level.level}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            level.rank.name(lang),
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${level.xpIntoLevel} / ${level.xpForNext} XP',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: level.fraction,
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: streak > 0
                              ? Colors.deepOrange
                              : theme.disabledColor,
                        ),
                        Text(' $streak', style: theme.textTheme.bodySmall),
                        const SizedBox(width: Space.md),
                        Icon(
                          Icons.task_alt_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        Text(
                          ru
                              ? ' Задания $done/${quests?.length ?? 3}'
                              : ' Quests $done/${quests?.length ?? 3}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
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
