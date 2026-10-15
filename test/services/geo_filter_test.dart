import 'package:birdquest/services/bird_recognition/geo_filter.dart';
import 'package:birdquest/services/bird_recognition/labels.dart';
import 'package:birdquest/services/bird_recognition/post_processor.dart';
import 'package:flutter_test/flutter_test.dart';

const _audioCsv =
    'idx;id;sci_name;com_name;class;order\n'
    '0;3;Turdus merula;Common Blackbird;Aves;Passeriformes\n'
    '1;4;Myophonus horsfieldii;Malabar Whistling Thrush;Aves;Passeriformes\n'
    '2;5;Rara avis;Unknown To Geo;Aves;Passeriformes\n'
    '3;6;Rana temporaria;Common Frog;Amphibia;Anura\n';

const _geoTxt =
    '﻿100\tMyophonus horsfieldii\tMalabar Whistling Thrush\n'
    '200\tTurdus merula\tCommon Blackbird\n'
    '300\tRana temporaria\tCommon Frog\n';

const _berlin = GeoContext(latitude: 52.5, longitude: 13.4, week: 40);

void main() {
  final audio = parseLabels(_audioCsv);
  final geo = parseGeoLabels(_geoTxt);

  test('BirdNET week numbering is 1..48, four per month', () {
    expect(birdnetWeek(DateTime(2026, 1, 1)), 1);
    expect(birdnetWeek(DateTime(2026, 1, 8)), 2);
    expect(birdnetWeek(DateTime(2026, 1, 31)), 4);
    expect(birdnetWeek(DateTime(2026, 10, 15)), 39);
    expect(birdnetWeek(DateTime(2026, 12, 31)), 48);
  });

  test('geo labels are parsed by scientific name in output order', () {
    expect(geo, ['Myophonus horsfieldii', 'Turdus merula', 'Rana temporaria']);
  });

  test('out-of-range birds are blocked; unknown species stay allowed', () {
    final range = SpeciesRange.fromScores(
      context: _berlin,
      probabilities: [0.0, 0.98, 0.5],
      geoLabels: geo,
      audioLabels: audio,
    );
    expect(range.allows('Turdus merula'), isTrue);
    expect(range.allows('Myophonus horsfieldii'), isFalse);
    expect(range.allows('Rara avis'), isTrue, reason: 'not in geo model');
    expect(range.plausibleCount, 1, reason: 'only birds are counted');
  });

  test('threshold boundary and NaN handling', () {
    final range = SpeciesRange.fromScores(
      context: _berlin,
      probabilities: [0.03, double.nan, 0],
      geoLabels: geo,
      audioLabels: audio,
    );
    expect(range.allows('Myophonus horsfieldii'), isTrue);
    expect(range.allows('Turdus merula'), isTrue, reason: 'NaN never blocks');
  });

  test('mismatched geo output length is an error', () {
    expect(
      () => SpeciesRange.fromScores(
        context: _berlin,
        probabilities: [0.1],
        geoLabels: geo,
        audioLabels: audio,
      ),
      throwsArgumentError,
    );
  });

  test('post-processor drops predictions the range rejects', () {
    final range = SpeciesRange.fromScores(
      context: _berlin,
      probabilities: [0.0, 0.98, 0.5],
      geoLabels: geo,
      audioLabels: audio,
    );
    final scores = [0.9, 0.8, 0.7, 0.0];
    final unfiltered = const PostProcessor().process(scores, audio);
    final filtered = const PostProcessor().process(
      scores,
      audio,
      allow: range.allows,
    );
    expect(unfiltered, hasLength(3));
    expect(filtered.map((p) => p.species.scientificName), [
      'Turdus merula',
      'Rara avis',
    ]);
  });

  test('cache key groups nearby fixes in the same week', () {
    const a = GeoContext(latitude: 52.49, longitude: 13.38, week: 40);
    const b = GeoContext(latitude: 52.31, longitude: 13.41, week: 40);
    const c = GeoContext(latitude: 52.49, longitude: 13.38, week: 41);
    expect(a.cacheKey, b.cacheKey);
    expect(a.cacheKey, isNot(c.cacheKey));
  });
}
