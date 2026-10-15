import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../services/species_guide/species_guide.dart';
import '../map/area_grouping.dart';

/// Aggregates over the user's real (non-demo) sightings.
class AchievementStats {
  const AchievementStats({
    required this.species,
    required this.encounters,
    required this.photos,
    required this.nightEncounters,
    required this.earlyEncounters,
    required this.owlSpecies,
    required this.raptorSpecies,
    required this.waterfowlSpecies,
    required this.songbirdSpecies,
    required this.bestSessionSpecies,
    required this.areas,
    required this.longestStreakDays,
  });

  static const empty = AchievementStats(
    species: 0,
    encounters: 0,
    photos: 0,
    nightEncounters: 0,
    earlyEncounters: 0,
    owlSpecies: 0,
    raptorSpecies: 0,
    waterfowlSpecies: 0,
    songbirdSpecies: 0,
    bestSessionSpecies: 0,
    areas: 0,
    longestStreakDays: 0,
  );

  final int species;
  final int encounters;
  final int photos;
  final int nightEncounters;
  final int earlyEncounters;
  final int owlSpecies;
  final int raptorSpecies;
  final int waterfowlSpecies;
  final int songbirdSpecies;
  final int bestSessionSpecies;
  final int areas;
  final int longestStreakDays;

  factory AchievementStats.compute(List<SightingFact> facts, int photos) {
    Set<int> speciesInOrders(Set<String> orders) => {
      for (final f in facts)
        if (orders.contains(f.taxonOrder)) f.speciesId,
    };

    final perSession = <int, Set<int>>{};
    for (final f in facts) {
      if (f.sessionId != null) {
        (perSession[f.sessionId!] ??= {}).add(f.speciesId);
      }
    }

    final days = {
      for (final f in facts)
        DateTime(f.confirmedAt.year, f.confirmedAt.month, f.confirmedAt.day),
    }.toList()..sort();
    var streak = days.isEmpty ? 0 : 1, best = streak;
    for (var i = 1; i < days.length; i++) {
      streak = days[i].difference(days[i - 1]).inDays == 1 ? streak + 1 : 1;
      if (streak > best) best = streak;
    }

    return AchievementStats(
      species: {for (final f in facts) f.speciesId}.length,
      encounters: facts.length,
      photos: photos,
      nightEncounters: facts
          .where((f) => f.confirmedAt.hour >= 21 || f.confirmedAt.hour < 4)
          .length,
      earlyEncounters: facts
          .where((f) => f.confirmedAt.hour >= 4 && f.confirmedAt.hour < 7)
          .length,
      owlSpecies: speciesInOrders({'Strigiformes'}).length,
      raptorSpecies: speciesInOrders({'Accipitriformes', 'Falconiformes'})
          .length,
      waterfowlSpecies: speciesInOrders({'Anseriformes'}).length,
      songbirdSpecies: speciesInOrders({'Passeriformes'}).length,
      bestSessionSpecies: perSession.values.fold(
        0,
        (m, s) => s.length > m ? s.length : m,
      ),
      areas: {
        for (final f in facts)
          if (f.latitude != null && f.longitude != null)
            areaCellKey(f.latitude!, f.longitude!),
      }.length,
      longestStreakDays: best,
    );
  }
}

class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.target,
    required this.measure,
  });

  final String id;
  final IconData icon;
  final ({String en, String ru}) title;
  final ({String en, String ru}) description;
  final int target;
  final int Function(AchievementStats) measure;

  String titleIn(GuideLanguage l) =>
      l == GuideLanguage.ru ? title.ru : title.en;
  String descriptionIn(GuideLanguage l) =>
      l == GuideLanguage.ru ? description.ru : description.en;
}

/// The catalog. Order is display order.
final achievementCatalog = <Achievement>[
  Achievement(
    id: 'first_song',
    icon: Icons.music_note_rounded,
    title: (en: 'First song', ru: 'Первая песня'),
    description: (
      en: 'Confirm your first bird',
      ru: 'Подтвердите первую птицу',
    ),
    target: 1,
    measure: (s) => s.species,
  ),
  for (final n in const [10, 25, 50, 100])
    Achievement(
      id: 'species_$n',
      icon: Icons.collections_bookmark_rounded,
      title: (en: '$n species', ru: '$n видов'),
      description: (
        en: 'Discover $n different species',
        ru: 'Найдите $n разных видов',
      ),
      target: n,
      measure: (s) => s.species,
    ),
  for (final n in const [25, 100])
    Achievement(
      id: 'encounters_$n',
      icon: Icons.hearing_rounded,
      title: (en: '$n encounters', ru: '$n встреч'),
      description: (en: 'Confirm $n encounters', ru: 'Подтвердите $n встреч'),
      target: n,
      measure: (s) => s.encounters,
    ),
  Achievement(
    id: 'photo_1',
    icon: Icons.photo_camera_rounded,
    title: (en: 'Snapshot', ru: 'Снимок'),
    description: (
      en: 'Photograph a bird you heard',
      ru: 'Сфотографируйте услышанную птицу',
    ),
    target: 1,
    measure: (s) => s.photos,
  ),
  Achievement(
    id: 'photo_25',
    icon: Icons.camera_rounded,
    title: (en: 'Wildlife photographer', ru: 'Фотоохотник'),
    description: (en: 'Take 25 bird photos', ru: 'Сделайте 25 фото птиц'),
    target: 25,
    measure: (s) => s.photos,
  ),
  Achievement(
    id: 'night_owl',
    icon: Icons.dark_mode_rounded,
    title: (en: 'Night owl', ru: 'Ночная сова'),
    description: (
      en: 'An encounter between 21:00 and 04:00',
      ru: 'Встреча между 21:00 и 04:00',
    ),
    target: 1,
    measure: (s) => s.nightEncounters,
  ),
  Achievement(
    id: 'early_bird',
    icon: Icons.wb_twilight_rounded,
    title: (en: 'Dawn chorus', ru: 'Утренний хор'),
    description: (
      en: 'An encounter between 04:00 and 07:00',
      ru: 'Встреча между 04:00 и 07:00',
    ),
    target: 1,
    measure: (s) => s.earlyEncounters,
  ),
  Achievement(
    id: 'owls_2',
    icon: Icons.nightlight_round,
    title: (en: 'Parliament of owls', ru: 'Совиный совет'),
    description: (en: 'Discover 2 owl species', ru: 'Найдите 2 вида сов'),
    target: 2,
    measure: (s) => s.owlSpecies,
  ),
  Achievement(
    id: 'raptor_1',
    icon: Icons.flight_rounded,
    title: (en: 'Bird of prey', ru: 'Хищная птица'),
    description: (
      en: 'Discover a hawk, eagle or falcon',
      ru: 'Найдите ястреба, орла или сокола',
    ),
    target: 1,
    measure: (s) => s.raptorSpecies,
  ),
  Achievement(
    id: 'waterfowl_3',
    icon: Icons.water_rounded,
    title: (en: 'By the water', ru: 'У воды'),
    description: (
      en: 'Discover 3 ducks, geese or swans',
      ru: 'Найдите 3 вида уток, гусей или лебедей',
    ),
    target: 3,
    measure: (s) => s.waterfowlSpecies,
  ),
  Achievement(
    id: 'songbirds_20',
    icon: Icons.queue_music_rounded,
    title: (en: 'Songbird scholar', ru: 'Знаток певчих'),
    description: (
      en: 'Discover 20 songbird species',
      ru: 'Найдите 20 видов певчих птиц',
    ),
    target: 20,
    measure: (s) => s.songbirdSpecies,
  ),
  Achievement(
    id: 'chorus_5',
    icon: Icons.graphic_eq_rounded,
    title: (en: 'Full chorus', ru: 'Полный хор'),
    description: (
      en: 'Save 5 species in one session',
      ru: 'Сохраните 5 видов за одну сессию',
    ),
    target: 5,
    measure: (s) => s.bestSessionSpecies,
  ),
  Achievement(
    id: 'explorer_5',
    icon: Icons.explore_rounded,
    title: (en: 'Explorer', ru: 'Исследователь'),
    description: (
      en: 'Find birds in 5 different areas',
      ru: 'Найдите птиц в 5 разных местах',
    ),
    target: 5,
    measure: (s) => s.areas,
  ),
  Achievement(
    id: 'streak_7',
    icon: Icons.local_fire_department_rounded,
    title: (en: 'Week of birdsong', ru: 'Неделя птичьих песен'),
    description: (
      en: 'Encounters 7 days in a row',
      ru: 'Встречи 7 дней подряд',
    ),
    target: 7,
    measure: (s) => s.longestStreakDays,
  ),
];

class AchievementProgress {
  const AchievementProgress(this.achievement, this.value, this.unlockedAt);
  final Achievement achievement;
  final int value;
  final DateTime? unlockedAt;
  bool get unlocked => value >= achievement.target;
  double get fraction => (value / achievement.target).clamp(0.0, 1.0);
}

final _sightingFactsProvider = StreamProvider<List<SightingFact>>(
  (ref) => ref.watch(sightingRepositoryProvider).watchSightingFacts(),
);
final _realPhotoCountProvider = StreamProvider<int>(
  (ref) => ref.watch(sightingRepositoryProvider).watchRealPhotoCount(),
);

final achievementStatsProvider = Provider<AchievementStats?>((ref) {
  final facts = ref.watch(_sightingFactsProvider).value;
  final photos = ref.watch(_realPhotoCountProvider).value;
  if (facts == null || photos == null) return null;
  return AchievementStats.compute(facts, photos);
});

/// Remembers when each achievement was first unlocked (local only).
class AchievementLog extends Notifier<Map<String, DateTime>> {
  static const _key = 'achievements_unlocked';

  @override
  Map<String, DateTime> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const {};
    return {
      for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
        e.key: DateTime.parse(e.value as String),
    };
  }

  /// Records newly unlocked ids; returns the ones that were new.
  List<String> record(Iterable<String> unlockedIds) {
    final fresh = unlockedIds.where((id) => !state.containsKey(id)).toList();
    if (fresh.isEmpty) return const [];
    final now = DateTime.now();
    state = {...state, for (final id in fresh) id: now};
    ref
        .read(sharedPreferencesProvider)
        .setString(
          _key,
          jsonEncode({
            for (final e in state.entries) e.key: e.value.toIso8601String(),
          }),
        );
    return fresh;
  }
}

final achievementLogProvider =
    NotifierProvider<AchievementLog, Map<String, DateTime>>(AchievementLog.new);

final achievementsProvider = Provider<List<AchievementProgress>?>((ref) {
  final stats = ref.watch(achievementStatsProvider);
  if (stats == null) return null;
  final log = ref.watch(achievementLogProvider);
  return [
    for (final a in achievementCatalog)
      AchievementProgress(a, a.measure(stats), log[a.id]),
  ];
});
