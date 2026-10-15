import 'dart:convert';
import 'dart:io';

import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/repositories/guide_repository.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:birdquest/services/species_guide/wikipedia_client.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers.dart';

const _entry = GuideEntry(
  texts: {
    GuideLanguage.en: GuideText(articleTitle: 'Common blackbird'),
    GuideLanguage.ru: GuideText(
      articleTitle: 'Чёрный дрозд',
      name: 'Чёрный дрозд',
    ),
  },
);

http.Response _extracts(Map<String, String> byTitle, {List<Map>? normalized}) =>
    http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'query': {
            'normalized': ?normalized,
            'pages': [
              for (final e in byTitle.entries)
                {'title': e.key, 'extract': e.value},
            ],
          },
        }),
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('description is fetched once, cached, and served offline', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      expect(req.url.host, 'ru.wikipedia.org');
      return _extracts({'Чёрный дрозд': 'Чёрный дрозд — вид птиц.'});
    });
    final repo = GuideRepository(
      db,
      WikipediaClient(
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      ),
    );

    final d = await repo.description(
      'Turdus merula',
      _entry,
      GuideLanguage.ru,
      allowNetwork: true,
    );
    expect(d!.text, 'Чёрный дрозд — вид птиц.');
    expect(d.articleUrl, startsWith('https://ru.wikipedia.org/wiki/'));

    final offline = await repo.description(
      'Turdus merula',
      _entry,
      GuideLanguage.ru,
      allowNetwork: false,
    );
    expect(offline!.text, d.text);
    expect(calls, 1);
  });

  test(
    'a cached English text does not hide a downloadable Russian one',
    () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return req.url.host == 'ru.wikipedia.org'
            ? _extracts({'Чёрный дрозд': 'Русский текст.'})
            : _extracts({'Common blackbird': 'English text.'});
      });
      final repo = GuideRepository(
        db,
        WikipediaClient(
          userAgent: 'BirdQuest/1.0 (test@example.org)',
          client: client,
        ),
      );
      await repo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.en,
        allowNetwork: true,
      );
      final ru = await repo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.ru,
        allowNetwork: true,
      );
      expect(ru!.text, 'Русский текст.');
      expect(calls, 2);

      // Offline, with only English cached: English is shown as a fallback.
      final offlineRepo = GuideRepository(
        db,
        WikipediaClient(
          userAgent: 'BirdQuest/1.0 (test@example.org)',
          client: MockClient((_) async => throw 'offline'),
        ),
      );
      await db.delete(db.guideDescriptions).go();
      await repo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.en,
        allowNetwork: true,
      );
      final fallback = await offlineRepo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.ru,
        allowNetwork: true,
      );
      expect(fallback!.lang, GuideLanguage.en);
    },
  );

  test('no network and nothing cached returns null', () async {
    final repo = GuideRepository(
      db,
      WikipediaClient(
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: MockClient((_) async => throw 'offline'),
      ),
    );
    expect(
      await repo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.en,
        allowNetwork: false,
      ),
      isNull,
    );
    expect(
      await repo.description(
        'Turdus merula',
        _entry,
        GuideLanguage.en,
        allowNetwork: true,
      ),
      isNull,
      reason: 'network errors are swallowed and retried later',
    );
  });

  test('batch download maps normalized titles back and skips cached', () async {
    final requested = <String>[];
    final client = MockClient((req) async {
      requested.add(req.url.queryParameters['titles']!);
      return _extracts(
        {'Common blackbird': 'A thrush.', 'European robin': 'A chat.'},
        normalized: [
          {'from': 'European_robin', 'to': 'European robin'},
        ],
      );
    });
    final repo = GuideRepository(
      db,
      WikipediaClient(
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      ),
    );
    final items = [
      (scientificName: 'Turdus merula', title: 'Common blackbird'),
      (scientificName: 'Erithacus rubecula', title: 'European_robin'),
    ];
    final progress = <int>[];
    await repo.downloadDescriptions(
      items,
      GuideLanguage.en,
      onProgress: progress.add,
      pause: Duration.zero,
    );
    expect(progress.last, 2);
    expect(
      (await repo.cachedDescription(
        'Erithacus rubecula',
        GuideLanguage.en,
      ))!.text,
      'A chat.',
    );

    await repo.downloadDescriptions(
      items,
      GuideLanguage.en,
      pause: Duration.zero,
    );
    expect(requested, hasLength(1), reason: 'second run is fully cached');
  });

  test(
    'packs list species once across overlapping areas; delete cascades',
    () async {
      final repo = GuideRepository(
        db,
        WikipediaClient(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      );
      const a = EncyclopediaSpecies(
        scientificName: 'Turdus merula',
        commonName: 'Common Blackbird',
      );
      const b = EncyclopediaSpecies(
        scientificName: 'Erithacus rubecula',
        commonName: 'European Robin',
      );
      final p1 = await repo.createPack(
        name: 'Home',
        latitude: 52.5,
        longitude: 13.4,
        radiusKm: 25,
        languages: [GuideLanguage.en, GuideLanguage.ru],
        withPhotos: true,
        species: [a, b],
      );
      await repo.createPack(
        name: 'Trip',
        latitude: 48,
        longitude: 11,
        radiusKm: 100,
        languages: [GuideLanguage.ru],
        withPhotos: false,
        species: [a],
      );
      final packs = await repo.watchPacks().first;
      expect(packs.map((p) => p.speciesCount), unorderedEquals([2, 1]));
      expect(packs.firstWhere((p) => p.name == 'Home').languages, [
        GuideLanguage.en,
        GuideLanguage.ru,
      ]);
      expect(await repo.watchEncyclopediaSpecies().first, hasLength(2));

      await repo.deletePack(p1);
      final left = await repo.watchEncyclopediaSpecies().first;
      expect(left.single.scientificName, 'Turdus merula');
    },
  );

  test(
    'Wikipedia client retries after HTTP 429 and honours Retry-After',
    () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        if (calls == 1) {
          return http.Response('', 429, headers: {'retry-after': '1'});
        }
        return _extracts({'Common blackbird': 'A thrush.'});
      });
      final wiki = WikipediaClient(
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      );
      final got = await wiki.intros(GuideLanguage.en, ['Common blackbird']);
      expect(got['Common blackbird'], 'A thrush.');
      expect(calls, 2);
    },
  );

  test(
    'without a contact User-Agent the client never hits the network',
    () async {
      var calls = 0;
      final wiki = WikipediaClient(
        client: MockClient((_) async {
          calls++;
          return http.Response('', 200);
        }),
      );
      await expectLater(
        wiki.intros(GuideLanguage.en, ['Common blackbird']),
        throwsA(isA<WikipediaException>()),
      );
      expect(calls, 0);
    },
  );

  test(
    'trimIntro collapses whitespace, strips stress marks, cuts at a sentence',
    () {
      expect(
        WikipediaClient.trimIntro('Красноло́бая  портниха\n— птица.'),
        'Краснолобая портниха — птица.',
      );
      final long = List.filled(80, 'Birds sing at dawn.').join(' ');
      final t = WikipediaClient.trimIntro(long);
      expect(t.length, lessThanOrEqualTo(WikipediaClient.maxChars));
      expect(t, endsWith('.'));
    },
  );

  test(
    'migrating a v1 database adds the guide, encyclopedia and quest tables',
    () async {
      final dir = Directory.systemTemp.createTempSync('birdquest_mig_');
      final file = File('${dir.path}/db.sqlite');
      // Build a v1-shaped database: current schema minus the v2 tables.
      var v1 = AppDatabase(NativeDatabase(file));
      await v1.sightingRepositoryProbe();
      await v1.customStatement('DROP TABLE encyclopedia_pack_species');
      await v1.customStatement('DROP TABLE encyclopedia_packs');
      await v1.customStatement('DROP TABLE guide_descriptions');
      await v1.customStatement('DROP TABLE quest_completions');
      await v1.customStatement('ALTER TABLE sightings DROP COLUMN rarity');
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      final repo = GuideRepository(
        upgraded,
        WikipediaClient(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      );
      expect(await repo.watchPacks().first, isEmpty);
      final species = await upgraded.select(upgraded.species).get();
      expect(
        species.single.scientificName,
        'Turdus merula',
        reason: 'existing data survives the migration',
      );
      // v3: rarity column and quest table exist after the upgrade.
      await upgraded.customSelect('SELECT rarity FROM sightings').get();
      expect(await upgraded.select(upgraded.questCompletions).get(), isEmpty);
      await upgraded.close();
      dir.deleteSync(recursive: true);
    },
  );
}

extension on AppDatabase {
  /// Writes one species row so the migration test can check data survives.
  Future<void> sightingRepositoryProbe() => into(species).insert(
    SpeciesCompanion.insert(
      scientificName: 'Turdus merula',
      commonName: 'Common Blackbird',
    ),
  );
}
