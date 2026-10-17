import 'dart:io';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/models.dart';
import 'package:birdquest/data/repositories/progress_repository.dart';
import 'package:birdquest/data/repositories/sighting_repository.dart';
import 'package:birdquest/features/achievements/achievements.dart';
import 'package:birdquest/features/progress/progress.dart';
import 'package:birdquest/features/progress/rarity.dart';
import 'package:birdquest/services/bird_recognition/geo_filter.dart';
import 'package:birdquest/services/bird_recognition/labels.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

SightingFact _f(
  int species,
  DateTime at, {
  String? rarity,
  int photos = 0,
  bool gps = false,
  String? order,
}) => SightingFact(
  speciesId: species,
  scientificName: 'Sp $species',
  confirmedAt: at,
  rarity: rarity,
  photoCount: photos,
  latitude: gps ? 1 : null,
  longitude: gps ? 1 : null,
  taxonOrder: order,
);

ModelLabel _label(String sci, {String cls = 'Aves'}) => ModelLabel(
  index: 0,
  id: sci,
  scientificName: sci,
  commonName: sci,
  taxonClass: cls,
  taxonOrder: 'Passeriformes',
);

void main() {
  group('rarity', () {
    test('tiers follow the yearly geo-model average', () {
      expect(Rarity.fromMean(0.98), Rarity.common);
      expect(Rarity.fromMean(0.33), Rarity.common);
      expect(Rarity.fromMean(0.19), Rarity.uncommon);
      expect(Rarity.fromMean(0.03), Rarity.rare);
    });

    test('region profile: present, vagrant and unknown species', () {
      final labels = [
        _label('Turdus merula'),
        _label('Bubo bubo'),
        _label('Copsychus saularis'),
        _label('Unknownus avis'),
        _label('Canis lupus', cls: 'Mammalia'),
      ];
      const geoLabels = ['Turdus merula', 'Bubo bubo', 'Copsychus saularis'];
      SpeciesRange range(List<double> p) => SpeciesRange.fromScores(
        context: const GeoContext(latitude: 52.5, longitude: 13.4, week: 1),
        probabilities: p,
        geoLabels: geoLabels,
        audioLabels: labels,
      );
      final profile = RegionProfile.fromRanges(
        latitude: 52.5,
        longitude: 13.4,
        // Blackbird all year; eagle owl scarce and in one of two months.
        ranges: [
          range([0.99, 0.12, 0.0]),
          range([0.97, 0.0, 0.0]),
        ],
        labels: labels,
      );
      expect(profile.species.keys, {'Turdus merula', 'Bubo bubo'});
      expect(profile.rarityOf('Turdus merula'), Rarity.common);
      expect(profile.rarityOf('Bubo bubo'), Rarity.rare);
      expect(profile.rarityOf('Copsychus saularis'), Rarity.legendary);
      expect(profile.rarityOf('Unknownus avis'), isNull);

      final copy = RegionProfile.fromJson(profile.toJson());
      expect(copy.rarityOf('Bubo bubo'), Rarity.rare);
      expect(copy.rarityOf('Unknownus avis'), isNull);
      expect(copy.species['Turdus merula']!.mean, closeTo(0.98, 1e-9));
    });

    test('a full year keeps monthly values through the cache', () {
      final labels = [_label('Hirundo rustica')];
      SpeciesRange range(double p) => SpeciesRange.fromScores(
        context: const GeoContext(latitude: 52.5, longitude: 13.4, week: 1),
        probabilities: [p],
        geoLabels: const ['Hirundo rustica'],
        audioLabels: labels,
      );
      // A summer visitor: absent in winter, peaks in June.
      const year = [
        0.0,
        0.0,
        0.1,
        0.4,
        0.8,
        0.9,
        0.85,
        0.7,
        0.4,
        0.1,
        0.0,
        0.0,
      ];
      final profile = RegionProfile.fromRanges(
        latitude: 52.5,
        longitude: 13.4,
        ranges: [for (final p in year) range(p)],
        labels: labels,
      );
      final swallow = profile.species['Hirundo rustica']!;
      expect(swallow.monthly, year);
      final copy = RegionProfile.fromJson(profile.toJson());
      expect(copy.species['Hirundo rustica']!.monthly, year);
      // A profile cached before seasonality (4-field rows) still loads.
      final old = RegionProfile.fromJson({
        'lat': 1,
        'lon': 2,
        'species': [
          ['Hirundo rustica', 'Barn Swallow', 'Passeriformes', 0.4],
        ],
        'unknown': [],
      });
      expect(old.species['Hirundo rustica']!.monthly, isEmpty);
    });
  });

  group('XP and levels', () {
    test('new species pay by rarity; repeats, photos and GPS add up', () {
      final xp = sightingsXp([
        _f(1, DateTime(2026, 5, 1), rarity: 'common', gps: true), // 10+50+5
        _f(1, DateTime(2026, 5, 2), rarity: 'common', photos: 2), // 10+0+20
        _f(2, DateTime(2026, 5, 3), rarity: 'rare'), // 10+250
        _f(2, DateTime(2026, 5, 4), rarity: 'rare'), // 10+15
        _f(3, DateTime(2026, 5, 5)), // unknown rarity: 10+75
      ]);
      expect(xp, 65 + 30 + 260 + 25 + 85);
    });

    test('order of saving decides which encounter is the new species', () {
      final a = sightingsXp([
        _f(1, DateTime(2026, 5, 2), rarity: 'legendary'),
        _f(1, DateTime(2026, 5, 1), rarity: 'legendary'),
      ]);
      expect(a, 10 + 500 + 10 + 30);
    });

    test('levels need 100, 150, 200 … XP', () {
      expect(PlayerLevel.fromXp(0).level, 1);
      expect(PlayerLevel.fromXp(99).level, 1);
      final l2 = PlayerLevel.fromXp(100);
      expect((l2.level, l2.xpIntoLevel, l2.xpForNext), (2, 0, 150));
      expect(PlayerLevel.fromXp(250).level, 3);
      expect(PlayerLevel.fromXp(250).rank.en, 'Birdwatcher');
      expect(PlayerLevel.fromXp(100000).rank.en, 'Legend of the forest');
    });
  });

  group('daily quests', () {
    test('three distinct quests per day, one easy, same all day', () {
      for (var d = 1; d <= 60; d++) {
        final day = DateTime(2026, 1, d);
        final q = questsFor(day);
        expect(q, hasLength(3));
        expect(q.map((x) => x.id).toSet(), hasLength(3));
        expect(q.first.easy, isTrue);
        expect(
          questsFor(DateTime(day.year, day.month, day.day, 23))
              .map((x) => x.id),
          q.map((x) => x.id),
        );
      }
      final ids = {
        for (var d = 1; d <= 60; d++)
          for (final q in questsFor(DateTime(2026, 1, d))) q.id,
      };
      expect(ids, hasLength(questPool.length), reason: 'every quest appears');
    });

    test('day stats count only that day and spot new species', () {
      final day = DateTime(2026, 5, 2);
      final s = DayStats.compute(
        [
          _f(1, DateTime(2026, 5, 1, 9)),
          _f(1, DateTime(2026, 5, 2, 6), gps: true, order: 'Passeriformes'),
          _f(2, DateTime(2026, 5, 2, 19), photos: 1, rarity: 'rare'),
          _f(3, DateTime(2026, 5, 3, 9)),
        ],
        day,
        listeningSeconds: 11 * 60 + 30,
      );
      expect(s.encounters, 2);
      expect(s.newSpecies, 1, reason: 'species 1 was first seen on May 1');
      expect(s.species, 2);
      expect(s.photos, 1);
      expect(s.withGps, 1);
      expect(s.dawn, 1);
      expect(s.evening, 1);
      expect(s.songbirdSpecies, 1);
      expect(s.uncommonOrRarer, 1);
      expect(s.listeningMinutes, 11);
    });

    test('streak counts back from today, or yesterday if today is open', () {
      final today = DateTime(2026, 5, 10, 15);
      expect(questStreak(['2026-05-08', '2026-05-09', '2026-05-10'], today), 3);
      expect(questStreak(['2026-05-08', '2026-05-09'], today), 2);
      expect(questStreak(['2026-05-07', '2026-05-09'], today), 1);
      expect(questStreak(['2026-05-07'], today), 0);
      expect(
        questStreak(['2026-02-28', '2026-03-01'], DateTime(2026, 3, 1)),
        2,
      );
    });

    test('achievements count rare finds, quests and quest streaks', () {
      final s = AchievementStats.compute(
        [
          _f(1, DateTime(2026, 5, 1), rarity: 'rare'),
          _f(2, DateTime(2026, 5, 1), rarity: 'legendary'),
          _f(3, DateTime(2026, 5, 1), rarity: 'common'),
        ],
        0,
        quests: [
          for (final d in ['2026-05-01', '2026-05-02', '2026-05-04'])
            QuestCompletion(day: d, questId: 'save_2', xp: 40),
        ],
      );
      expect(s.rareSpecies, 2);
      expect(s.legendarySpecies, 1);
      expect(s.questsCompleted, 3);
      expect(s.longestQuestStreak, 2);
    });
  });

  group('with a database', () {
    late AppDatabase db;
    late SharedPreferences prefs;
    late Directory root;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = memoryDatabase();
      root = Directory.systemTemp.createTempSync('birdquest_progress_');
    });
    tearDown(() async {
      await db.close();
      root.deleteSync(recursive: true);
    });

    // A day whose quests include "save 2 encounters".
    final questDay = [for (var d = 1; d <= 60; d++) DateTime(2026, 6, d, 12)]
        .firstWhere((d) => questsFor(d).any((q) => q.id == 'save_2'));

    testWidgets('saving birds completes a quest once and announces XP', (
      tester,
    ) async {
      final media = (await tester.runAsync(tempMediaStore))!;
      final sightings = SightingRepository(db, media);
      final paths = AppPaths(
        mediaRoot: Directory('${root.path}/media')..createSync(),
        modelsDir: Directory('${root.path}/models')..createSync(),
        tempDir: Directory('${root.path}/tmp')..createSync(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPathsProvider.overrideWithValue(paths),
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            deviceLanguageProvider.overrideWithValue('en'),
            speciesGuideProvider.overrideWith(
              (ref) async => SpeciesGuide.empty,
            ),
            clockProvider.overrideWithValue(() => questDay),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProgressAnnouncer(child: SizedBox())),
          ),
        ),
      );
      Future<void> settle(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<List<QuestCompletionRow>> completions() async =>
          (await tester.runAsync(() => db.select(db.questCompletions).get()))!;

      // Let the starting level load first: gains are announced relative to it.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      await settle(() => container.read(playerLevelProvider) != null);

      for (final species in [blackbird, robin]) {
        await tester.runAsync(
          () => sightings.saveEncounter(
            EncounterDraft(
              species: species,
              confirmedAt: questDay,
              rarity: 'common',
            ),
          ),
        );
      }
      await settle(
        () => find.textContaining('Quest complete').evaluate().isNotEmpty,
      );

      final done = await completions();
      expect(done.map((c) => c.questId), contains('save_2'));
      expect(done.where((c) => c.questId == 'save_2'), hasLength(1));
      expect(
        find.textContaining('Quest complete: Save 2 encounters'),
        findsOneWidget,
      );

      // A third save does not record the same quest again.
      await tester.runAsync(
        () => sightings.saveEncounter(
          EncounterDraft(species: kingfisher, confirmedAt: questDay),
        ),
      );
      await settle(() => false);
      expect(
        (await completions()).where((c) => c.questId == 'save_2'),
        hasLength(1),
      );

      // Demo encounters never count.
      final before = (await completions()).length;
      await tester.runAsync(
        () => sightings.saveEncounter(
          EncounterDraft(
            species: blackbird,
            confirmedAt: questDay,
            isDemo: true,
          ),
        ),
      );
      await settle(() => false);
      expect((await completions()).length, before);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() => media.root.delete(recursive: true));
    });

    test('region profile is cached and only recomputed far away', () async {
      var computed = 0;
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          regionProfileComputerProvider.overrideWithValue((lat, lon) async {
            computed++;
            return RegionProfile(
              latitude: lat,
              longitude: lon,
              species: const {},
              unknown: const {},
            );
          }),
        ],
      );
      addTearDown(c.dispose);
      final n = c.read(regionProfileProvider.notifier);
      await n.ensureNear(52.5, 13.4);
      await n.ensureNear(52.6, 13.5); // ~13 km away
      expect(computed, 1);
      await n.ensureNear(48.1, 11.6); // Munich
      expect(computed, 2);
      expect(prefs.getString('region_profile_v2'), contains('48.1'));

      final reloaded = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(reloaded.dispose);
      expect(reloaded.read(regionProfileProvider)!.latitude, 48.1);
    });
  });
}
