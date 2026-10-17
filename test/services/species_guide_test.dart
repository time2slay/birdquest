import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/services/species_guide/commons_http.dart';
import 'package:birdquest/services/species_guide/reference_photo_service.dart';
import 'package:birdquest/services/species_guide/reference_voice_service.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _bundle(Map<String, dynamic> species) => Uint8List.fromList(
  gzip.encode(utf8.encode(jsonEncode({'version': 1, 'species': species}))),
);

final _guide = SpeciesGuide.decode(
  _bundle({
    'Turdus merula': {
      'en': {
        'd': 'The common blackbird is a true thrush.',
        't': 'Common blackbird',
      },
      'ru': {
        'd': 'Чёрный дрозд — вид птиц.',
        't': 'Чёрный дрозд',
        'n': 'Чёрный дрозд',
      },
      'img': {
        'f': 'Common_Blackbird.jpg',
        'a': 'Andreas Trepte',
        'l': 'CC BY-SA 2.5',
        'u': 'https://creativecommons.org/licenses/by-sa/2.5',
      },
      'fam': 'Turdidae',
      'snd': [
        {
          'f': 'Common_Blackbird_song_(Turdus_merula).ogg',
          'a': 'Diana Tudor',
          'l': 'CC BY 4.0',
          'u': 'https://creativecommons.org/licenses/by/4.0',
          'd': 70.0,
        },
        {'f': 'Turdus_merula_XC1.mp3', 'a': 'X', 'l': 'CC BY-SA 4.0'},
      ],
      'spd': {'h': 50, 'fam': 1},
    },
    'Turdus pilaris': {'fam': 'Turdidae'},
    'Falco peregrinus': {
      'fam': 'Falconidae',
      'spd': {'h': 160, 'd': 389},
    },
    'Rara avis': {
      'en': {'d': 'Only English text.', 't': 'Rara avis'},
    },
  }),
);

void main() {
  group('SpeciesGuide', () {
    test('decodes names, descriptions, links and photo credits', () {
      final e = _guide['Turdus merula']!;
      expect(e.text(GuideLanguage.ru)!.name, 'Чёрный дрозд');
      expect(e.photo!.credit, 'Andreas Trepte · CC BY-SA 2.5');
      expect(
        e.photo!.thumbnailUri(800).toString(),
        'https://commons.wikimedia.org/wiki/Special:FilePath/'
        'Common_Blackbird.jpg?width=800',
      );
      expect(
        e.text(GuideLanguage.en)!.articleUrl(GuideLanguage.en),
        'https://en.wikipedia.org/wiki/Common_blackbird',
      );
    });

    test('decodes voices, families and flight speeds', () {
      final e = _guide['Turdus merula']!;
      expect(e.family, 'Turdidae');
      expect(e.voices, hasLength(2));
      final v = e.voices.first;
      expect(v.kind, 'song');
      expect(v.seconds, 70);
      expect(v.credit, 'Diana Tudor · CC BY 4.0');
      expect(
        v.downloadUri.toString(),
        'https://commons.wikimedia.org/wiki/Special:FilePath/'
        'Common_Blackbird_song_(Turdus_merula).ogg',
      );
      expect(e.voices.last.kind, isNull);
      expect(e.speed!.source, SpeedSource.family);
      final f = _guide['Falco peregrinus']!.speed!;
      expect(f.source, SpeedSource.species);
      expect((f.horizontal, f.dive, f.top), (160, 389, 389));
      expect(_guide['Rara avis']!.voices, isEmpty);
      expect(_guide['Rara avis']!.speed, isNull);
    });

    test('indexes genera and families', () {
      expect(SpeciesGuide.genusOf('Turdus merula'), 'Turdus');
      expect(
        _guide.genusMembers('Turdus'),
        unorderedEquals(['Turdus merula', 'Turdus pilaris']),
      );
      expect(_guide.familyMembers('Falconidae'), ['Falco peregrinus']);
      expect(_guide.familyMembers('Nope'), isEmpty);
    });

    test('localized names fall back to the model name', () {
      expect(
        _guide.nameFor('Turdus merula', 'Common Blackbird', GuideLanguage.ru),
        'Чёрный дрозд',
      );
      expect(
        _guide.nameFor('Turdus merula', 'Common Blackbird', GuideLanguage.en),
        'Common Blackbird',
      );
      expect(
        _guide.nameFor('Unknown bird', 'Fallback', GuideLanguage.ru),
        'Fallback',
      );
    });

    test('descriptions fall back to the other language', () {
      final d = _guide['Rara avis']!.description(GuideLanguage.ru)!;
      expect(d.lang, GuideLanguage.en);
      expect(d.text, 'Only English text.');
      expect(
        _guide['Turdus merula']!.description(GuideLanguage.ru)!.lang,
        GuideLanguage.ru,
      );
    });
  });

  group('guide language', () {
    Future<ProviderContainer> container(String deviceLang) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceLanguageProvider.overrideWithValue(deviceLang),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('auto follows the phone language', () async {
      expect(
        (await container('ru')).read(guideLanguageProvider),
        GuideLanguage.ru,
      );
      expect(
        (await container('de')).read(guideLanguageProvider),
        GuideLanguage.en,
      );
    });

    test('explicit choice overrides the phone and persists', () async {
      final c = await container('ru');
      await c
          .read(guideLanguageModeProvider.notifier)
          .set(GuideLanguageMode.en);
      expect(c.read(guideLanguageProvider), GuideLanguage.en);
      expect(
        c.read(sharedPreferencesProvider).getString('guide_language'),
        'en',
      );
    });
  });

  group('ReferencePhotoService', () {
    late Directory dir;
    final photo = _guide['Turdus merula']!.photo!;

    setUp(() => dir = Directory.systemTemp.createTempSync('birdquest_photos_'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('downloads once with a User-Agent, then serves from cache', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        expect(req.headers['User-Agent'], contains('BirdQuest'));
        expect(req.url.queryParameters['width'], '800');
        return http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      });
      final service = ReferencePhotoService(
        dir,
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      );
      expect(await service.cached(photo), isNull);
      final f = await service.get(photo);
      expect(f!.readAsBytesSync(), [1, 2, 3]);
      await service.get(photo);
      expect(calls, 1);
      expect(await service.cached(photo), isNotNull);
      expect(await service.cacheSize(), 3);
      await service.clearCache();
      expect(await service.cacheSize(), 0);
    });

    test('keeps the User-Agent on every redirect hop', () async {
      // Commons: FilePath -> Special:Redirect -> upload.wikimedia.org. A hop
      // without the contact User-Agent gets HTTP 403.
      final hops = <String>[];
      final client = MockClient((req) async {
        hops.add(req.url.host);
        if (req.headers['User-Agent'] != 'BirdQuest/1.0 (test@example.org)') {
          return http.Response('robot policy', 403);
        }
        return switch (hops.length) {
          1 => http.Response(
            '',
            302,
            headers: {
              'location': '/w/index.php?title=Special:Redirect/file/x.jpg',
            },
          ),
          2 => http.Response(
            '',
            301,
            headers: {'location': 'https://upload.wikimedia.org/x.jpg'},
          ),
          _ => http.Response.bytes(
            [9],
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
        };
      });
      final service = ReferencePhotoService(
        dir,
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      );
      expect((await service.get(photo))!.readAsBytesSync(), [9]);
      expect(hops, [
        'commons.wikimedia.org',
        'commons.wikimedia.org',
        'upload.wikimedia.org',
      ]);
    });

    test('failures and non-images are not cached or retried', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(
          '<html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });
      final service = ReferencePhotoService(
        dir,
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      );
      expect(await service.get(photo), isNull);
      expect(await service.get(photo), isNull);
      expect(calls, 1);
      expect(await service.cacheSize(), 0);
    });

    test('concurrent requests share one download', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response.bytes(
          [9],
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      });
      final service = ReferencePhotoService(
        dir,
        userAgent: 'BirdQuest/1.0 (test@example.org)',
        client: client,
      );
      final results = await Future.wait([
        service.get(photo),
        service.get(photo),
      ]);
      expect(results.every((f) => f != null), isTrue);
      expect(calls, 1);
    });
  });

  group('ReferenceVoiceService', () {
    late Directory dir;
    final voice = _guide['Turdus merula']!.voices.first;
    const ua = 'BirdQuest/1.0 (test@example.org)';

    setUp(() => dir = Directory.systemTemp.createTempSync('birdquest_voices_'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('downloads the original through redirects, keeping the UA', () async {
      final hops = <String>[];
      final client = MockClient((req) async {
        hops.add(req.url.host);
        if (req.headers['User-Agent'] != ua) {
          return http.Response('robot policy', 403);
        }
        return hops.length == 1
            ? http.Response(
                '',
                302,
                headers: {'location': 'https://upload.wikimedia.org/a.ogg'},
              )
            : http.Response.bytes(
                [7, 7],
                200,
                headers: {'content-type': 'application/ogg'},
              );
      });
      final service = ReferenceVoiceService(dir, userAgent: ua, client: client);
      final f = await service.get(voice);
      expect(f!.readAsBytesSync(), [7, 7]);
      expect(f.path, endsWith('.ogg'));
      expect(hops, ['commons.wikimedia.org', 'upload.wikimedia.org']);
      expect(await service.cached(voice), isNotNull);
      await service.get(voice);
      expect(hops, hasLength(2), reason: 'served from cache');
    });

    test('non-audio answers are not cached and not retried', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(
          '<html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });
      final service = ReferenceVoiceService(dir, userAgent: ua, client: client);
      expect(await service.get(voice), isNull);
      expect(await service.get(voice), isNull);
      expect(calls, 1);
      service.forgetFailures();
      expect(await service.get(voice), isNull);
      expect(calls, 2);
      expect(await service.cacheSize(), 0);
    });

    test('without a User-Agent only the cache is used', () async {
      final service = ReferenceVoiceService(
        dir,
        client: MockClient((_) async => fail('no network without a UA')),
      );
      expect(await service.get(voice), isNull);
    });
  });

  group('wikimediaGet', () {
    test('waits out HTTP 429 using Retry-After, then gives up', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = MockClient((req) async {
        calls++;
        return calls < 3
            ? http.Response('slow down', 429, headers: {'retry-after': '11'})
            : http.Response('ok', 200);
      });
      final res = await wikimediaGet(
        client,
        Uri.parse('https://upload.wikimedia.org/a.ogg'),
        'ua',
        wait: (d) async => waits.add(d),
      );
      expect(res.statusCode, 200);
      expect(waits, [const Duration(seconds: 11), const Duration(seconds: 11)]);

      final always429 = MockClient(
        (_) async => http.Response('', 429, headers: {'retry-after': '99'}),
      );
      waits.clear();
      final gaveUp = await wikimediaGet(
        always429,
        Uri.parse('https://upload.wikimedia.org/a.ogg'),
        'ua',
        wait: (d) async => waits.add(d),
      );
      expect(gaveUp.statusCode, 429);
      expect(waits, List.filled(4, const Duration(seconds: 30)));
    });
  });
}
