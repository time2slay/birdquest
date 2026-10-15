import 'package:birdquest/data/models.dart';
import 'package:birdquest/features/achievements/achievements.dart';
import 'package:birdquest/features/map/area_grouping.dart';
import 'package:birdquest/services/species_guide/region_species_service.dart';
import 'package:flutter_test/flutter_test.dart';

LocatedSighting _ls(
  int species,
  double lat,
  double lon,
  DateTime at, {
  bool demo = false,
}) => LocatedSighting(
  sightingId: at.millisecondsSinceEpoch,
  speciesId: species,
  scientificName: 'Sp $species',
  commonName: 'Bird $species',
  latitude: lat,
  longitude: lon,
  confirmedAt: at,
  isDemo: demo,
);

SightingFact _f(
  int species,
  DateTime at, {
  String? order,
  int? session,
  double? lat,
  double? lon,
}) => SightingFact(
  speciesId: species,
  scientificName: 'Sp $species',
  taxonOrder: order,
  confirmedAt: at,
  sessionId: session,
  latitude: lat,
  longitude: lon,
);

void main() {
  group('area grouping', () {
    test('same species within ~1 km is one pin, even across grid lines', () {
      final groups = groupByArea([
        _ls(1, 52.5201, 13.4051, DateTime(2026, 5, 1)),
        _ls(1, 52.5205, 13.4049, DateTime(2026, 5, 3)),
        _ls(1, 52.5199, 13.4060, DateTime(2026, 5, 2)),
        _ls(1, 48.1, 11.5, DateTime(2026, 6, 1)), // another city
        _ls(2, 52.5201, 13.4051, DateTime(2026, 5, 1)), // other species
      ]);
      expect(groups, hasLength(3));
      final berlin1 = groups.first;
      expect(berlin1.speciesId, 1);
      expect(berlin1.count, 3);
      expect(berlin1.firstSeen, DateTime(2026, 5, 1));
      expect(berlin1.lastSeen, DateTime(2026, 5, 3));
      expect(berlin1.latitude, closeTo(52.5202, 1e-3));
    });

    test('demo flag is only set when every sighting is demo', () {
      final g = groupByArea([
        _ls(1, 1, 1, DateTime(2026), demo: true),
        _ls(1, 1, 1, DateTime(2026), demo: false),
      ]).single;
      expect(g.allDemo, isFalse);
    });
  });

  group('achievement stats', () {
    test('counts species, time-of-day, orders, sessions, areas, streaks', () {
      final s = AchievementStats.compute([
        _f(
          1,
          DateTime(2026, 5, 1, 5, 30),
          order: 'Passeriformes',
          session: 1,
          lat: 52.52,
          lon: 13.40,
        ),
        _f(
          2,
          DateTime(2026, 5, 1, 6),
          order: 'Strigiformes',
          session: 1,
          lat: 52.52,
          lon: 13.40,
        ),
        _f(
          3,
          DateTime(2026, 5, 2, 22),
          order: 'Strigiformes',
          session: 2,
          lat: 48.1,
          lon: 11.5,
        ),
        _f(1, DateTime(2026, 5, 3, 12), order: 'Passeriformes', session: 3),
        _f(4, DateTime(2026, 5, 5, 12), order: 'Accipitriformes', session: 4),
      ], 3);
      expect(s.species, 4);
      expect(s.encounters, 5);
      expect(s.photos, 3);
      expect(s.earlyEncounters, 2);
      expect(s.nightEncounters, 1);
      expect(s.owlSpecies, 2);
      expect(s.raptorSpecies, 1);
      expect(s.songbirdSpecies, 1);
      expect(s.bestSessionSpecies, 2);
      expect(s.areas, 2);
      expect(s.longestStreakDays, 3, reason: 'May 1–3 consecutive');
    });

    test('catalog unlocks match thresholds', () {
      final stats = AchievementStats.compute([
        _f(1, DateTime(2026, 5, 1, 12)),
      ], 0);
      final unlocked = {
        for (final a in achievementCatalog)
          if (a.measure(stats) >= a.target) a.id,
      };
      expect(unlocked, {'first_song'});
      expect(
        achievementCatalog.map((a) => a.id).toSet().length,
        achievementCatalog.length,
        reason: 'ids are unique',
      );
    });

    test('empty history unlocks nothing', () {
      final stats = AchievementStats.compute(const [], 0);
      expect(
        achievementCatalog.where((a) => a.measure(stats) >= a.target),
        isEmpty,
      );
    });
  });

  test('region sampling covers center and two rings within the radius', () {
    final pts = RegionSpeciesService.samplePoints(52.5, 13.4, 100);
    expect(pts, hasLength(17));
    expect(pts.first, (lat: 52.5, lon: 13.4));
    for (final p in pts) {
      expect((p.lat - 52.5).abs(), lessThanOrEqualTo(100 / 111 + 1e-9));
    }
    final dateline = RegionSpeciesService.samplePoints(0, 179.9, 300);
    expect(dateline.every((p) => p.lon >= -180 && p.lon <= 180), isTrue);
  });
}
