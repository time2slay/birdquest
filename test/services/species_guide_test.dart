import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/services/species_guide/reference_photo_service.dart';
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
}
