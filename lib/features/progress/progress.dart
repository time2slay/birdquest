import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/species_guide/species_guide.dart';
import '../achievements/achievements.dart';
import 'rarity.dart';

// ---------------------------------------------------------------- XP rules

/// XP for discovering a new species, by its rarity where it was found.
int newSpeciesXp(Rarity? r) => switch (r) {
  Rarity.common => 50,
  Rarity.uncommon => 100,
  Rarity.rare => 250,
  Rarity.legendary => 500,
  null => 75,
};

/// Extra XP for meeting an already-known species again.
int repeatBonusXp(Rarity? r) => switch (r) {
  Rarity.common || null => 0,
  Rarity.uncommon => 5,
  Rarity.rare => 15,
  Rarity.legendary => 30,
};

const encounterXp = 10;
const photoXp = 20;
const gpsXp = 5;
const achievementXp = 100;

/// XP earned by each saved (non-demo) sighting, in save order. Derived
/// entirely from saved data, so deleting a sighting removes its XP.
int sightingsXp(List<SightingFact> facts) {
  final sorted = [...facts]
    ..sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
  final seen = <int>{};
  var xp = 0;
  for (final f in sorted) {
    final rarity = Rarity.parse(f.rarity);
    xp += encounterXp;
    xp += seen.add(f.speciesId) ? newSpeciesXp(rarity) : repeatBonusXp(rarity);
    if (f.photoCount > 0) xp += photoXp;
    if (f.hasLocation) xp += gpsXp;
  }
  return xp;
}

// ------------------------------------------------------------ Levels/ranks

/// XP needed to go from [level] to the next one.
int xpForNextLevel(int level) => 100 + 50 * (level - 1);

class Rank {
  const Rank(this.minLevel, this.en, this.ru, this.icon);
  final int minLevel;
  final String en;
  final String ru;
  final IconData icon;
  String name(GuideLanguage l) => l == GuideLanguage.ru ? ru : en;
}

const ranks = [
  Rank(1, 'Fledgling', 'Птенец', Icons.egg_outlined),
  Rank(3, 'Birdwatcher', 'Наблюдатель', Icons.visibility_outlined),
  Rank(6, 'Naturalist', 'Натуралист', Icons.eco_outlined),
  Rank(10, 'Tracker', 'Следопыт', Icons.explore_outlined),
  Rank(15, 'Ornithologist', 'Орнитолог', Icons.school_outlined),
  Rank(22, 'Songmaster', 'Мастер пения', Icons.queue_music_rounded),
  Rank(30, 'Legend of the forest', 'Легенда леса', Icons.forest_rounded),
];

class PlayerLevel {
  const PlayerLevel({
    required this.totalXp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNext,
  });

  factory PlayerLevel.fromXp(int totalXp) {
    var level = 1, left = totalXp;
    while (left >= xpForNextLevel(level)) {
      left -= xpForNextLevel(level);
      level++;
    }
    return PlayerLevel(
      totalXp: totalXp,
      level: level,
      xpIntoLevel: left,
      xpForNext: xpForNextLevel(level),
    );
  }

  final int totalXp;
  final int level;
  final int xpIntoLevel;
  final int xpForNext;

  double get fraction => xpIntoLevel / xpForNext;
  Rank get rank => ranks.lastWhere((r) => level >= r.minLevel);
}

// ------------------------------------------------------------ Daily quests

/// What the user did on one day (non-demo only).
class DayStats {
  const DayStats({
    this.encounters = 0,
    this.newSpecies = 0,
    this.species = 0,
    this.photos = 0,
    this.withGps = 0,
    this.dawn = 0,
    this.evening = 0,
    this.songbirdSpecies = 0,
    this.uncommonOrRarer = 0,
    this.listeningMinutes = 0,
  });

  factory DayStats.compute(
    List<SightingFact> facts,
    DateTime day, {
    int listeningSeconds = 0,
  }) {
    bool sameDay(DateTime t) =>
        t.year == day.year && t.month == day.month && t.day == day.day;
    final firstSeen = <int, DateTime>{};
    for (final f in facts) {
      final prev = firstSeen[f.speciesId];
      if (prev == null || f.confirmedAt.isBefore(prev)) {
        firstSeen[f.speciesId] = f.confirmedAt;
      }
    }
    final today = facts.where((f) => sameDay(f.confirmedAt)).toList();
    return DayStats(
      encounters: today.length,
      newSpecies: firstSeen.values.where(sameDay).length,
      species: {for (final f in today) f.speciesId}.length,
      photos: today.where((f) => f.photoCount > 0).length,
      withGps: today.where((f) => f.hasLocation).length,
      dawn: today.where((f) => f.confirmedAt.hour < 8).length,
      evening: today.where((f) => f.confirmedAt.hour >= 18).length,
      songbirdSpecies: {
        for (final f in today)
          if (f.taxonOrder == 'Passeriformes') f.speciesId,
      }.length,
      uncommonOrRarer: today
          .where(
            (f) => const {'uncommon', 'rare', 'legendary'}.contains(f.rarity),
          )
          .length,
      listeningMinutes: listeningSeconds ~/ 60,
    );
  }

  final int encounters;
  final int newSpecies;
  final int species;
  final int photos;
  final int withGps;
  final int dawn;
  final int evening;
  final int songbirdSpecies;
  final int uncommonOrRarer;
  final int listeningMinutes;
}

class Quest {
  const Quest({
    required this.id,
    required this.icon,
    required this.en,
    required this.ru,
    required this.target,
    required this.xp,
    required this.measure,
    this.easy = false,
  });

  final String id;
  final IconData icon;
  final String en;
  final String ru;
  final int target;
  final int xp;
  final int Function(DayStats) measure;

  /// One easy quest is always offered, so every day is winnable.
  final bool easy;

  String title(GuideLanguage l) => l == GuideLanguage.ru ? ru : en;
}

final questPool = <Quest>[
  Quest(
    id: 'save_2',
    icon: Icons.bookmark_add_outlined,
    en: 'Save 2 encounters',
    ru: 'Сохраните 2 встречи',
    target: 2,
    xp: 40,
    easy: true,
    measure: (s) => s.encounters,
  ),
  Quest(
    id: 'listen_10',
    icon: Icons.hearing_rounded,
    en: 'Listen for 10 minutes',
    ru: 'Слушайте 10 минут',
    target: 10,
    xp: 40,
    easy: true,
    measure: (s) => s.listeningMinutes,
  ),
  Quest(
    id: 'gps_2',
    icon: Icons.place_outlined,
    en: 'Save 2 encounters with GPS',
    ru: 'Сохраните 2 встречи с GPS',
    target: 2,
    xp: 40,
    easy: true,
    measure: (s) => s.withGps,
  ),
  Quest(
    id: 'save_4',
    icon: Icons.library_add_outlined,
    en: 'Save 4 encounters',
    ru: 'Сохраните 4 встречи',
    target: 4,
    xp: 70,
    measure: (s) => s.encounters,
  ),
  Quest(
    id: 'new_1',
    icon: Icons.fiber_new_outlined,
    en: 'Discover a new species',
    ru: 'Найдите новый вид',
    target: 1,
    xp: 60,
    measure: (s) => s.newSpecies,
  ),
  Quest(
    id: 'photo_1',
    icon: Icons.photo_camera_outlined,
    en: 'Photograph a bird',
    ru: 'Сфотографируйте птицу',
    target: 1,
    xp: 50,
    measure: (s) => s.photos,
  ),
  Quest(
    id: 'dawn_1',
    icon: Icons.wb_twilight_rounded,
    en: 'Save a bird before 08:00',
    ru: 'Сохраните птицу до 08:00',
    target: 1,
    xp: 60,
    measure: (s) => s.dawn,
  ),
  Quest(
    id: 'evening_1',
    icon: Icons.nights_stay_outlined,
    en: 'Save a bird after 18:00',
    ru: 'Сохраните птицу после 18:00',
    target: 1,
    xp: 50,
    measure: (s) => s.evening,
  ),
  Quest(
    id: 'species_3',
    icon: Icons.diversity_3_outlined,
    en: 'Save 3 different species',
    ru: 'Сохраните 3 разных вида',
    target: 3,
    xp: 70,
    measure: (s) => s.species,
  ),
  Quest(
    id: 'songbird_2',
    icon: Icons.music_note_outlined,
    en: 'Save 2 songbird species',
    ru: 'Сохраните 2 вида певчих птиц',
    target: 2,
    xp: 50,
    measure: (s) => s.songbirdSpecies,
  ),
  Quest(
    id: 'uncommon_1',
    icon: Icons.diamond_outlined,
    en: 'Find an uncommon or rarer bird',
    ru: 'Найдите необычную или более редкую птицу',
    target: 1,
    xp: 80,
    measure: (s) => s.uncommonOrRarer,
  ),
];

/// Three quests for [day]: one easy plus two others, the same all day.
List<Quest> questsFor(DateTime day) {
  final rng = math.Random(day.year * 10000 + day.month * 100 + day.day);
  final easy = questPool.where((q) => q.easy).toList()..shuffle(rng);
  final other = questPool.where((q) => !q.easy).toList()..shuffle(rng);
  return [easy.first, ...other.take(2)];
}

class QuestProgress {
  const QuestProgress(this.quest, this.value, this.completed);
  final Quest quest;
  final int value;

  /// Recorded in the database (XP awarded).
  final bool completed;
  bool get reached => value >= quest.target;
  double get fraction => (value / quest.target).clamp(0.0, 1.0);
}

/// Consecutive days, ending today or yesterday, with a completed quest.
int questStreak(Iterable<String> completedDays, DateTime today) {
  final days = completedDays.toSet();
  var d = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(dayKey(d))) {
    streak++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return streak;
}

// --------------------------------------------------------------- Providers

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

final questCompletionsProvider = StreamProvider<List<QuestCompletion>>(
  (ref) => ref.watch(progressRepositoryProvider).watchCompletions(),
);

/// Today's date; overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final _listeningTodayProvider = StreamProvider<int>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(progressRepositoryProvider)
      .watchListeningSeconds(DateTime(now.year, now.month, now.day));
});

final todayQuestsProvider = Provider<List<QuestProgress>?>((ref) {
  final facts = ref.watch(sightingFactsProvider).value;
  final done = ref.watch(questCompletionsProvider).value;
  final seconds = ref.watch(_listeningTodayProvider).value;
  if (facts == null || done == null || seconds == null) return null;
  final now = ref.watch(clockProvider)();
  final stats = DayStats.compute(facts, now, listeningSeconds: seconds);
  final today = dayKey(now);
  final doneIds = {
    for (final c in done)
      if (c.day == today) c.questId,
  };
  return [
    for (final q in questsFor(now))
      QuestProgress(q, q.measure(stats), doneIds.contains(q.id)),
  ];
});

final questStreakProvider = Provider<int>((ref) {
  final done = ref.watch(questCompletionsProvider).value ?? const [];
  return questStreak(done.map((c) => c.day), ref.watch(clockProvider)());
});

final playerLevelProvider = Provider<PlayerLevel?>((ref) {
  final facts = ref.watch(sightingFactsProvider).value;
  final done = ref.watch(questCompletionsProvider).value;
  final achievements = ref.watch(achievementsProvider);
  if (facts == null || done == null || achievements == null) return null;
  final xp =
      sightingsXp(facts) +
      done.fold<int>(0, (sum, c) => sum + c.xp) +
      achievements.where((a) => a.unlocked).length * achievementXp;
  return PlayerLevel.fromXp(xp);
});

/// Records quests the moment they are reached and announces XP gains and
/// level-ups app-wide.
class ProgressAnnouncer extends ConsumerStatefulWidget {
  const ProgressAnnouncer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ProgressAnnouncer> createState() => _ProgressAnnouncerState();
}

class _ProgressAnnouncerState extends ConsumerState<ProgressAnnouncer> {
  final _questNames = <String>[];

  @override
  void initState() {
    super.initState();
    ref.listenManual<List<QuestProgress>?>(
      todayQuestsProvider,
      (_, quests) => _recordQuests(quests),
      fireImmediately: true,
    );
    ref.listenManual<PlayerLevel?>(playerLevelProvider, (prev, next) {
      // The first value is the starting point, not a gain.
      if (prev == null || next == null || next.totalXp <= prev.totalXp) {
        _questNames.clear();
        return;
      }
      _announce(prev, next);
    });
  }

  Future<void> _recordQuests(List<QuestProgress>? quests) async {
    if (quests == null) return;
    final repo = ref.read(progressRepositoryProvider);
    final today = dayKey(ref.read(clockProvider)());
    final lang = ref.read(guideLanguageProvider);
    for (final q in quests) {
      if (q.reached && !q.completed) {
        if (await repo.recordCompletion(today, q.quest.id, q.quest.xp)) {
          _questNames.add(q.quest.title(lang));
        }
      }
    }
  }

  void _announce(PlayerLevel prev, PlayerLevel next) {
    final ru = ref.read(guideLanguageProvider) == GuideLanguage.ru;
    final gained = next.totalXp - prev.totalXp;
    final parts = <String>[
      if (next.level > prev.level)
        ru
            ? 'Уровень ${next.level} · ${next.rank.ru}!'
            : 'Level ${next.level} · ${next.rank.en}!',
      for (final q in _questNames)
        ru ? 'Задание выполнено: $q' : 'Quest complete: $q',
      '+$gained XP',
    ];
    _questNames.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              next.level > prev.level
                  ? Icons.military_tech_rounded
                  : Icons.bolt_rounded,
              color: Colors.amber,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(parts.join(' · '))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
