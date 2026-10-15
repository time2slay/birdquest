import 'dart:typed_data';

import 'package:birdquest/services/audio/pcm.dart';
import 'package:birdquest/services/audio/ring_buffer.dart';
import 'package:birdquest/services/audio/wav_writer.dart';
import 'package:birdquest/services/bird_recognition/labels.dart';
import 'package:birdquest/services/bird_recognition/post_processor.dart';
import 'package:flutter_test/flutter_test.dart';

const _csv =
    '﻿idx;id;sci_name;com_name;class;order\n'
    '0;3;Turdus merula;Common Blackbird;Aves;Passeriformes\n'
    '1;9;Rana temporaria;Common Frog;Amphibia;Anura\n'
    '2;12;Erithacus rubecula;European Robin;Aves;Passeriformes\n'
    '3;15;Alcedo atthis;;Aves;Coraciiformes\n';

void main() {
  group('labels', () {
    test('parses the BirdNET+ V3 CSV with BOM', () {
      final labels = parseLabels(_csv);
      expect(labels, hasLength(4));
      expect(labels[0].scientificName, 'Turdus merula');
      expect(labels[0].isBird, isTrue);
      expect(labels[1].isBird, isFalse);
      expect(labels[3].commonName, 'Alcedo atthis', reason: 'falls back');
      expect(labels[2].toSpeciesInfo().modelLabelId, '12');
    });

    test('rejects a file without the expected columns', () {
      expect(() => parseLabels('a;b\n1;2'), throwsFormatException);
    });
  });

  group('post processor', () {
    final labels = parseLabels(_csv);

    test('thresholds, sorts, hides non-birds and NaN', () {
      final out = const PostProcessor(threshold: 0.35)
          .process([0.5, 0.99, 0.9, double.nan], labels);
      expect(out.map((p) => p.species.commonName), [
        'European Robin',
        'Common Blackbird',
      ]);
      expect(out.first.score, 0.9);
    });

    test('top-K limits the result', () {
      final out = const PostProcessor(
        threshold: 0.1,
        topK: 1,
      ).process([0.5, 0, 0.6, 0.7], labels);
      expect(out.single.species.scientificName, 'Alcedo atthis');
    });

    test('sensitivity above 1 raises scores, below 1 lowers them', () {
      final scores = [0.3, 0.0, 0.0, 0.0];
      expect(const PostProcessor().process(scores, labels), isEmpty);
      final hi = const PostProcessor(sensitivity: 1.25).process(scores, labels);
      expect(hi.single.score, greaterThan(0.35));
      final lo = const PostProcessor(
        threshold: 0,
        sensitivity: 0.75,
      ).process(scores, labels);
      expect(lo.first.score, lessThan(0.3));
    });

    test('mismatched score length is an error', () {
      expect(
        () => const PostProcessor().process([0.1], labels),
        throwsArgumentError,
      );
    });

    test('uncertainty flag below 0.5', () {
      final out = const PostProcessor().process([0.4, 0, 0.8, 0], labels);
      expect(out.firstWhere((p) => p.score == 0.4).isUncertain, isTrue);
      expect(out.firstWhere((p) => p.score == 0.8).isUncertain, isFalse);
    });
  });

  group('ring buffer', () {
    test('returns the latest samples in order across wrap-around', () {
      final rb = RingBuffer(5);
      expect(rb.latest(1), isNull);
      rb.addAll(Float32List.fromList([1, 2, 3]));
      rb.addAll(Float32List.fromList([4, 5, 6, 7]));
      expect(rb.length, 5);
      expect(rb.latest(5), [3, 4, 5, 6, 7]);
      expect(rb.latest(2), [6, 7]);
      expect(rb.latest(6), isNull);
    });

    test('handles input larger than capacity', () {
      final rb = RingBuffer(3)..addAll(Float32List.fromList([1, 2, 3, 4, 5]));
      expect(rb.latest(3), [3, 4, 5]);
    });
  });

  group('pcm', () {
    test('converts little-endian PCM16 to floats', () {
      final bytes = Uint8List.fromList([0x00, 0x80, 0xFF, 0x7F, 0x00, 0x00]);
      final out = pcm16ToFloat32(bytes);
      expect(out[0], -1.0);
      expect(out[1], closeTo(32767 / 32768, 1e-6));
      expect(out[2], 0.0);
    });

    test('rms and level mapping', () {
      expect(rms(Float32List.fromList([0.5, -0.5])), closeTo(0.5, 1e-6));
      expect(rmsToLevel(0), 0);
      expect(rmsToLevel(1), 1);
      expect(rmsToLevel(0.0316228), closeTo(1, 1e-4)); // -30 dBFS
      expect(rmsToLevel(0.001), closeTo(0.5, 1e-6)); // -60 dBFS
      expect(rmsToLevel(0.0000316228), closeTo(0, 1e-4)); // -90 dBFS
    });
  });

  test('playback normalization boosts quiet clips with a gain cap', () {
    final quiet = normalizeForPlayback(Float32List.fromList([0.003, -0.0015]));
    expect(quiet[0], closeTo(0.6, 1e-6), reason: 'capped at 200x');
    final loud = normalizeForPlayback(Float32List.fromList([0.5, -0.25]));
    expect(loud[0], closeTo(0.9, 1e-6));
    expect(normalizeForPlayback(Float32List(3)), [0, 0, 0]);
  });

  test('wav encoder writes a valid 16-bit mono header', () {
    final wav = encodeWav(
      Float32List.fromList([0, 0.5, -1]),
      sampleRate: 32000,
    );
    final d = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(d.getUint32(24, Endian.little), 32000);
    expect(d.getUint16(34, Endian.little), 16);
    expect(d.getUint32(40, Endian.little), 6);
    expect(wav.length, 44 + 6);
    expect(d.getInt16(46, Endian.little), 16384);
    expect(d.getInt16(48, Endian.little), -32767);
  });
}
