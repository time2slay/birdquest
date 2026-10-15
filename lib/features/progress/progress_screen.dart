import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import '../achievements/achievements.dart';
import 'progress.dart';
import 'progress_widgets.dart';
import 'rarity.dart';

/// Level, daily quests, streak, regional checklist and how XP works.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Fill in the regional checklist if it has not been computed yet.
    if (ref.read(regionProfileProvider) == null) {
      ref.read(regionProfileProvider.notifier).ensureHere();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final level = ref.watch(playerLevelProvider);
    final quests = ref.watch(todayQuestsProvider);
    final streak = ref.watch(questStreakProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(ru ? 'Прогресс' : 'Progress')),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          if (level != null) _LevelHero(level: level, lang: lang),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  ru ? 'Задания на сегодня' : 'Today\'s quests',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Icon(
                Icons.local_fire_department_rounded,
                color: streak > 0 ? Colors.deepOrange : theme.disabledColor,
              ),
              Text(
                ru ? ' $streak дн. подряд' : ' $streak-day streak',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            ru
                ? 'Новые задания каждый день. Выполняйте хотя бы одно, чтобы не '
                      'прервать серию.'
                : 'New quests every day. Complete at least one to keep your '
                      'streak going.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Space.md),
          for (final q in quests ?? const <QuestProgress>[])
            _QuestTile(progress: q, lang: lang),
          const SizedBox(height: Space.lg),
          const _ChecklistSummary(),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: () => context.push('/achievements'),
            icon: const Icon(Icons.emoji_events_outlined),
            label: Text(ru ? 'Достижения' : 'Achievements'),
          ),
          const SizedBox(height: Space.xl),
          Text(
            ru ? 'Как получать опыт' : 'How to earn XP',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: Space.sm),
          _XpRules(lang: lang),
        ],
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({required this.level, required this.lang});
  final PlayerLevel level;
  final GuideLanguage lang;

  @override
  Widget build(BuildContext context) {
    final ru = lang == GuideLanguage.ru;
    final next = ranks.where((r) => r.minLevel > level.level).firstOrNull;
    final onForest = Colors.white;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: forestCardDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  level.rank.icon,
                  size: 30,
                  color: const Color(0xFF2F5D3A),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ru ? 'Уровень ${level.level}' : 'Level ${level.level}',
                      style: TextStyle(
                        color: onForest.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      level.rank.name(lang),
                      style: TextStyle(
                        color: onForest,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level.fraction,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: const Color(0xFFE7C26A),
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(
            ru
                ? '${level.xpIntoLevel} / ${level.xpForNext} XP до уровня '
                      '${level.level + 1} · всего ${level.totalXp} XP'
                : '${level.xpIntoLevel} / ${level.xpForNext} XP to level '
                      '${level.level + 1} · ${level.totalXp} XP total',
            style: TextStyle(color: onForest.withValues(alpha: 0.9)),
          ),
          if (next != null)
            Text(
              ru
                  ? 'Следующее звание: ${next.ru} (уровень ${next.minLevel})'
                  : 'Next rank: ${next.en} (level ${next.minLevel})',
              style: TextStyle(color: onForest.withValues(alpha: 0.75)),
            ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({required this.progress, required this.lang});
  final QuestProgress progress;
  final GuideLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = progress.quest;
    final done = progress.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : q.icon,
              color: done ? theme.colorScheme.primary : null,
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title(lang),
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${q.xp} XP',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: done
                        ? theme.colorScheme.primary
                        : context.nature.inkMuted,
                  ),
                ),
                Text(
                  '${progress.value.clamp(0, q.target)}/${q.target}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistSummary extends ConsumerWidget {
  const _ChecklistSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final profile = ref.watch(regionProfileProvider);
    final facts = ref.watch(sightingFactsProvider).value ?? const [];
    final theme = Theme.of(context);
    if (profile == null) {
      return NoticeCard(
        icon: Icons.checklist_rounded,
        title: ru ? 'Птицы вашего региона' : 'Birds of your region',
        message: ru
            ? 'Список появится, когда будет скачана модель BirdNET и '
                  'известно ваше местоположение.'
            : 'The list appears once the BirdNET model is downloaded and '
                  'your location is known.',
      );
    }
    final found = {for (final f in facts) f.scientificName};
    final total = profile.species.length;
    final got = profile.species.keys.where(found.contains).length;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => context.push('/checklist'),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: total == 0 ? 0 : got / total,
                      strokeWidth: 6,
                      backgroundColor: context.nature.mossContainer,
                    ),
                    Center(
                      child: Text(
                        total == 0 ? '0%' : '${(got * 100 / total).floor()}%',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ru ? 'Птицы вашего региона' : 'Birds of your region',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      ru ? 'Найдено $got из $total' : 'Found $got of $total',
                      style: theme.textTheme.bodyMedium,
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

class _XpRules extends StatelessWidget {
  const _XpRules({required this.lang});
  final GuideLanguage lang;

  @override
  Widget build(BuildContext context) {
    final ru = lang == GuideLanguage.ru;
    final theme = Theme.of(context);
    Widget row(Widget lead, String text, String xp) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Align(alignment: Alignment.centerLeft, child: lead),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          Text(xp, style: theme.textTheme.labelLarge),
        ],
      ),
    );
    return Column(
      children: [
        for (final r in Rarity.values)
          row(
            RarityChip(r),
            ru ? 'Новый вид' : 'New species',
            '+${newSpeciesXp(r)}',
          ),
        row(
          const Icon(Icons.bookmark_added_outlined, size: 20),
          ru ? 'Каждая встреча' : 'Every encounter',
          '+$encounterXp',
        ),
        row(
          const Icon(Icons.photo_camera_outlined, size: 20),
          ru ? 'Встреча с фото' : 'Encounter with a photo',
          '+$photoXp',
        ),
        row(
          const Icon(Icons.place_outlined, size: 20),
          ru ? 'Встреча с GPS' : 'Encounter with GPS',
          '+$gpsXp',
        ),
        row(
          const Icon(Icons.emoji_events_outlined, size: 20),
          ru ? 'Достижение' : 'Achievement',
          '+$achievementXp',
        ),
        const SizedBox(height: Space.sm),
        Text(
          ru
              ? 'Редкость считается по модели BirdNET для места, где вы нашли '
                    'птицу. Демо-режим опыт не даёт.'
              : 'Rarity comes from the BirdNET geo model for the place where '
                    'you found the bird. Demo mode earns no XP.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
