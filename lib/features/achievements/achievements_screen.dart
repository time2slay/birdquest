import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/common.dart';
import 'achievements.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final items = ref.watch(achievementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(ru ? 'Достижения' : 'Achievements')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    Space.sm,
                    Space.lg,
                    Space.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(Space.lg),
                      decoration: forestCardDecoration(
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFE0B65A),
                            size: 40,
                          ),
                          const SizedBox(width: Space.md),
                          Expanded(
                            child: Text(
                              ru
                                  ? 'Открыто ${items.where((i) => i.unlocked).length} из ${items.length}'
                                  : '${items.where((i) => i.unlocked).length} of ${items.length} unlocked',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: Space.md,
                          crossAxisSpacing: Space.md,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _Badge(item: items[i], lang: lang),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: NoticeCard(
                      icon: Icons.leaderboard_rounded,
                      tone: NoticeTone.info,
                      title: ru
                          ? 'Таблица лидеров — скоро'
                          : 'Leaderboard — coming later',
                      message: ru
                          ? 'Соревнования с другими игроками появятся вместе с '
                                'онлайн-функциями. Достижения считаются только '
                                'по настоящим (не демо) находкам на этом телефоне.'
                          : 'Competing with other players arrives with online '
                                'features. Achievements count only real (non-demo) '
                                'sightings on this phone.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.item, required this.lang});
  final AchievementProgress item;
  final GuideLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nature = context.nature;
    final a = item.achievement;
    final unlocked = item.unlocked;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? nature.ochreContainer : nature.canvas,
                border: Border.all(
                  color: unlocked ? nature.ochre : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: Icon(
                unlocked ? a.icon : Icons.lock_outline_rounded,
                size: 30,
                color: unlocked ? nature.onOchreContainer : nature.inkMuted,
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              a.titleIn(lang),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              a.descriptionIn(lang),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            if (unlocked)
              Text(
                item.unlockedAt == null
                    ? '✓'
                    : DateFormat.yMMMd(lang.name).format(item.unlockedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: nature.ochre,
                ),
              )
            else ...[
              LinearProgressIndicator(value: item.fraction, minHeight: 5),
              const SizedBox(height: 2),
              Text(
                '${item.value} / ${a.target}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Watches achievement progress and announces newly unlocked ones.
/// Achievements already unlocked on first load are recorded silently.
class AchievementAnnouncer extends ConsumerStatefulWidget {
  const AchievementAnnouncer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AchievementAnnouncer> createState() =>
      _AchievementAnnouncerState();
}

class _AchievementAnnouncerState extends ConsumerState<AchievementAnnouncer> {
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<AchievementProgress>?>(
      achievementsProvider,
      (_, next) => _onChange(next),
      fireImmediately: true,
    );
  }

  void _onChange(List<AchievementProgress>? next) {
    if (next == null) return;
    final fresh = ref
        .read(achievementLogProvider.notifier)
        .record(next.where((i) => i.unlocked).map((i) => i.achievement.id));
    if (!_primed) {
      // Achievements earned before this launch are recorded silently.
      _primed = true;
      return;
    }
    if (!mounted) return;
    final lang = ref.read(guideLanguageProvider);
    for (final id in fresh) {
      final a = achievementCatalog.firstWhere((x) => x.id == id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFE0B65A)),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  '${lang == GuideLanguage.ru ? 'Достижение' : 'Achievement unlocked'}: '
                  '${a.titleIn(lang)}',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
