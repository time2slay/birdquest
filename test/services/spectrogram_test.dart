import 'dart:math' as math;
import 'dart:typed_data';

import 'package:birdquest/services/audio/spectrogram.dart';
import 'package:birdquest/services/bird_recognition/prediction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Float32List _sine(double hz, int n, {int rate = 32000, double amp = 0.5}) =>
    Float32List.fromList([
      for (var i = 0; i < n; i++) amp * math.sin(2 * math.pi * hz * i / rate),
    ]);

void main() {
  group('fft', () {
    test('a pure tone peaks in its bin', () {
      const n = 512;
      final re = Float64List(n), im = Float64List(n);
      for (var i = 0; i < n; i++) {
        re[i] = math.sin(2 * math.pi * 32 * i / n); // bin 32
      }
      fft(re, im);
      var best = 0;
      var bestPower = 0.0;
      for (var k = 1; k < n ~/ 2; k++) {
        final p = re[k] * re[k] + im[k] * im[k];
        if (p > bestPower) {
          bestPower = p;
          best = k;
        }
      }
      expect(best, 32);
      expect(math.sqrt(bestPower), closeTo(n / 2, 1e-6));
    });
  });

  group('SpectrogramAnalyzer', () {
    test('band edges increase, start above DC and end at the max bin', () {
      final edges = SpectrogramAnalyzer.bandEdges(bands: 96, maxBin: 192);
      expect(edges, hasLength(97));
      expect(edges.first, 1);
      for (var b = 1; b < edges.length; b++) {
        expect(edges[b], greaterThan(edges[b - 1]));
      }
      expect(edges.last, greaterThanOrEqualTo(192));
    });

    test('emits one column per hop once the first frame is full', () {
      final a = SpectrogramAnalyzer();
      expect(a.add(Float32List(511)), isEmpty);
      expect(a.add(Float32List(1)), hasLength(1));
      expect(a.add(Float32List(256 * 3)), hasLength(3));
      expect(a.columnRate, 125);
    });

    test('steady ambience settles to a calm, mostly dark picture', () {
      final a = SpectrogramAnalyzer();
      final rnd = math.Random(2);
      List<Uint8List> noise(int n) => a.add(
        Float32List.fromList([
          for (var i = 0; i < n; i++) (rnd.nextDouble() - 0.5) * 0.01,
        ]),
      );
      noise(32000 * 3); // settle
      final cols = noise(32000);
      var lit = 0, all = 0;
      for (final c in cols) {
        for (final v in c) {
          all++;
          if (v > 40) lit++;
        }
      }
      expect(lit / all, lessThan(0.05));
    });

    test('a tone after ambience lights up its band, not the others', () {
      final a = SpectrogramAnalyzer();
      final rnd = math.Random(1);
      // Ambience first so the noise floor settles.
      a.add(
        Float32List.fromList([
          for (var i = 0; i < 32000; i++) (rnd.nextDouble() - 0.5) * 0.002,
        ]),
      );
      final cols = a.add(_sine(4000, 8000));
      final col = cols.last;
      final edges = SpectrogramAnalyzer.bandEdges(bands: 96, maxBin: 192);
      const bin = 4000 / 32000 * 512; // 64
      final band = edges.indexWhere((e) => e > bin) - 1;
      expect(col[band], greaterThan(200));
      expect(col[5], lessThan(60));
      expect(col[90], lessThan(60));
    });
  });

  group('SpectrogramBuffer', () {
    test('keeps the latest columns in a ring', () {
      final b = SpectrogramBuffer(bands: 2, capacity: 3);
      b.addColumns([
        for (var i = 1; i <= 5; i++) Uint8List.fromList([i, i * 10]),
      ]);
      expect(b.totalColumns, 5);
      expect(b.value(4, 0), 5);
      expect(b.value(2, 1), 30);
      expect(b.value(1, 0), 0, reason: 'overwritten');
      expect(b.value(9, 0), 0);
    });

    test('pins marks half a window back and merges quick repeats', () {
      final b = SpectrogramBuffer(bands: 1, capacity: 1000, columnRate: 100);
      b.addColumns(List.generate(500, (_) => Uint8List(1)));
      final p = Prediction(species: kingfisher, score: 0.9);
      b.mark([p]);
      expect(b.marks.single.column, 500 - 150);
      b.addColumns(List.generate(50, (_) => Uint8List(1)));
      b.mark([p]); // 0.5 s later: same song
      expect(b.marks, hasLength(1));
      b.addColumns(List.generate(450, (_) => Uint8List(1)));
      b.mark([p]); // 5 s after the first: a new label
      expect(b.marks, hasLength(2));
      b.mark([Prediction(species: robin, score: 0.4)]);
      expect(b.marks, hasLength(2), reason: 'uncertain results get no label');
    });

    test('drops marks that scrolled out and clears', () {
      final b = SpectrogramBuffer(bands: 1, capacity: 100, columnRate: 10);
      b.addColumns(List.generate(50, (_) => Uint8List(1)));
      b.mark([Prediction(species: robin, score: 0.6)]);
      b.addColumns(List.generate(200, (_) => Uint8List(1)));
      expect(b.marks, isEmpty);
      b.clear();
      expect(b.totalColumns, 0);
      expect(b.lastAppend, isNull);
    });
  });
}
