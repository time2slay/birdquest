import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../bird_recognition/prediction.dart';

/// In-place iterative radix-2 FFT. [re] and [im] must have the same
/// power-of-two length.
void fft(Float64List re, Float64List im) {
  final n = re.length;
  assert(n == im.length && n > 0 && n & (n - 1) == 0, 'length must be 2^k');
  // Bit-reversal permutation.
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final angle = -2 * math.pi / len;
    final wr = math.cos(angle), wi = math.sin(angle);
    final half = len >> 1;
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < half; k++) {
        final a = i + k, b = a + half;
        final xr = re[b] * cr - im[b] * ci;
        final xi = re[b] * ci + im[b] * cr;
        re[b] = re[a] - xr;
        im[b] = im[a] - xi;
        re[a] += xr;
        im[a] += xi;
        final nr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = nr;
      }
    }
  }
}

/// Turns a mono PCM stream into display columns: a short-time Fourier
/// transform (Hann window) folded into [bands] rows between 0 and [maxHz]
/// on a gently logarithmic scale, mapped to 0–255 intensity against an
/// adaptive per-band noise floor so quiet ambience stays calm and birdsong
/// stands out.
///
/// For display only; the recognition model computes its own features.
class SpectrogramAnalyzer {
  SpectrogramAnalyzer({
    this.sampleRate = 32000,
    this.fftSize = 512,
    this.hop = 256,
    this.bands = 96,
    this.maxHz = 12000,
    this.dynamicRangeDb = 36,
    this.floorMarginDb = 7,
  }) : _window = Float64List(fftSize),
       _smooth = Float64List(bands)..fillRange(0, bands, double.nan),
       _re = Float64List(fftSize),
       _im = Float64List(fftSize),
       _pending = Float64List(fftSize),
       _floor = Float64List(bands)..fillRange(0, bands, double.nan) {
    for (var i = 0; i < fftSize; i++) {
      _window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (fftSize - 1));
    }
    _edges = bandEdges(
      bands: bands,
      maxBin: (maxHz / sampleRate * fftSize).floor(),
    );
  }

  final int sampleRate;
  final int fftSize;
  final int hop;
  final int bands;
  final double maxHz;
  final double dynamicRangeDb;

  /// How far above the noise floor a sound must rise before it shows.
  final double floorMarginDb;

  final Float64List _window;
  final Float64List _re;
  final Float64List _im;
  final Float64List _pending;
  final Float64List _floor;
  final Float64List _smooth;
  late final List<int> _edges;
  int _filled = 0;

  /// Columns per second.
  double get columnRate => sampleRate / hop;

  /// FFT bin boundaries of each band: band `b` covers bins
  /// `[edges[b], edges[b + 1])`, at least one bin wide, starting above DC.
  static List<int> bandEdges({required int bands, required int maxBin}) {
    const k = 2.2; // curvature: 0 would be linear
    final edges = List<int>.filled(bands + 1, 0);
    for (var b = 0; b <= bands; b++) {
      final x = b / bands;
      final f = (math.exp(k * x) - 1) / (math.exp(k) - 1);
      edges[b] = 1 + (f * (maxBin - 1)).round();
    }
    for (var b = 1; b <= bands; b++) {
      if (edges[b] <= edges[b - 1]) edges[b] = edges[b - 1] + 1;
    }
    return edges;
  }

  void reset() {
    _filled = 0;
    _floor.fillRange(0, bands, double.nan);
    _smooth.fillRange(0, bands, double.nan);
  }

  /// Feeds samples and returns the columns completed by them (oldest first),
  /// each [bands] long with band 0 = lowest frequency.
  List<Uint8List> add(Float32List samples) {
    final out = <Uint8List>[];
    var i = 0;
    while (i < samples.length) {
      final take = math.min(fftSize - _filled, samples.length - i);
      for (var j = 0; j < take; j++) {
        _pending[_filled + j] = samples[i + j];
      }
      _filled += take;
      i += take;
      if (_filled == fftSize) {
        out.add(_column());
        // Keep the overlap for the next frame.
        _pending.setRange(0, fftSize - hop, _pending, hop);
        _filled = fftSize - hop;
      }
    }
    return out;
  }

  Uint8List _column() {
    for (var i = 0; i < fftSize; i++) {
      _re[i] = _pending[i] * _window[i];
      _im[i] = 0;
    }
    fft(_re, _im);
    final col = Uint8List(bands);
    for (var b = 0; b < bands; b++) {
      // Mean power over the band's bins: steadier than the peak on noise,
      // and a tone still stands out in the narrow bands where song lives.
      var sum = 0.0;
      final lo = _edges[b], hi = _edges[b + 1];
      for (var bin = lo; bin < hi; bin++) {
        sum += _re[bin] * _re[bin] + _im[bin] * _im[bin];
      }
      final power = sum / (hi - lo);
      // A little temporal smoothing calms the speckle of broadband noise.
      final prev = _smooth[b];
      final smoothed = prev.isNaN ? power : prev * 0.45 + power * 0.55;
      _smooth[b] = smoothed;
      final db = 10 * math.log(smoothed + 1e-12) / math.ln10;
      // Noise floor follows the typical level of each band: it sinks fast
      // and rises slowly, so steady ambience is absorbed but a song is not.
      final floor = _floor[b];
      _floor[b] = floor.isNaN
          ? db
          : db < floor
          ? floor + (db - floor) * 0.08
          : floor + (db - floor) * 0.01;
      final v = ((db - _floor[b] - floorMarginDb) / dynamicRangeDb).clamp(
        0.0,
        1.0,
      );
      col[b] = (math.pow(v, 0.85) * 255).round();
    }
    return col;
  }
}

/// A detection pinned to the spectrogram column where it was heard.
class SpectrogramMark {
  const SpectrogramMark({
    required this.column,
    required this.species,
    required this.score,
  });

  /// Absolute column index (see [SpectrogramBuffer.totalColumns]).
  final int column;
  final SpeciesInfo species;
  final double score;
}

/// The most recent spectrogram columns plus detection marks, shared between
/// a recognizer (writer) and the scanner's spectrogram view (reader).
///
/// It is a [ChangeNotifier] on purpose: columns arrive ~125 times a second
/// and must repaint only the spectrogram, not rebuild the scanner state.
class SpectrogramBuffer extends ChangeNotifier {
  SpectrogramBuffer({
    this.bands = 96,
    this.capacity = 768,
    this.columnRate = 125,
  }) : _data = Uint8List(bands * capacity);

  final int bands;
  final int capacity;

  /// Nominal columns per second, used for smooth scrolling and mark timing.
  final double columnRate;

  final Uint8List _data;
  final List<SpectrogramMark> _marks = [];
  int _total = 0;
  DateTime? _lastAppend;

  /// Columns written since creation or [clear]; the newest has index
  /// `totalColumns - 1`.
  int get totalColumns => _total;

  /// When the last batch arrived; null when nothing arrived since [clear].
  DateTime? get lastAppend => _lastAppend;

  List<SpectrogramMark> get marks => List.unmodifiable(_marks);

  /// Intensity 0–255 of [band] in absolute column [column], or 0 when that
  /// column is not (or no longer) stored.
  int value(int column, int band) {
    if (column < 0 || column >= _total || column < _total - capacity) return 0;
    return _data[(column % capacity) * bands + band];
  }

  void addColumns(List<Uint8List> columns, {DateTime? now}) {
    if (columns.isEmpty) return;
    for (final col in columns) {
      _data.setRange(
        (_total % capacity) * bands,
        (_total % capacity) * bands + bands,
        col,
      );
      _total++;
    }
    _lastAppend = now ?? DateTime.now();
    _marks.removeWhere((m) => m.column < _total - capacity);
    notifyListeners();
  }

  /// Pins [predictions] to the audio they were heard in: a 3 s window that
  /// ended now, so the middle of it sits [windowSeconds] / 2 back.
  /// Uncertain predictions are skipped, and repeats of a species within
  /// [mergeSeconds] are merged so a singing bird gets one label, not many.
  void mark(
    List<Prediction> predictions, {
    double windowSeconds = 3,
    double mergeSeconds = 4,
  }) {
    if (predictions.isEmpty || _total == 0) return;
    final column = math.max(
      0,
      _total - (windowSeconds / 2 * columnRate).round(),
    );
    final minGap = (mergeSeconds * columnRate).round();
    for (final p in predictions) {
      if (p.isUncertain) continue;
      final dup = _marks.any(
        (m) =>
            m.species.scientificName == p.species.scientificName &&
            (m.column - column).abs() < minGap,
      );
      if (!dup) {
        _marks.add(
          SpectrogramMark(column: column, species: p.species, score: p.score),
        );
      }
    }
    notifyListeners();
  }

  void clear() {
    _data.fillRange(0, _data.length, 0);
    _marks.clear();
    _total = 0;
    _lastAppend = null;
    notifyListeners();
  }
}
