import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/spectrogram.dart';
import 'bird_recognition_service.dart';
import 'field_notes.dart';

/// SIMULATED recognizer for UI development and demos.
///
/// Emits scripted predictions without touching the microphone or a model.
/// Everything it produces is flagged as demo data and labeled in the UI;
/// it must never be presented as a real identification.
class DemoRecognitionService implements BirdRecognitionService {
  DemoRecognitionService({
    math.Random? random,
    this.hop = const Duration(seconds: 1),
  }) : _random = random ?? math.Random();

  final math.Random _random;
  final Duration hop;
  StreamController<RecognitionEvent>? _events;
  Timer? _predictTimer;
  Timer? _levelTimer;
  Timer? _specTimer;
  int _tick = 0;
  final List<_SyntheticSong> _songs = [];

  @override
  final spectrogram = SpectrogramBuffer();

  static const species = fieldGuideSpecies;

  @override
  bool get isDemo => true;

  @override
  String get modelName => 'Demo mode (simulated)';

  @override
  Future<Stream<RecognitionEvent>> start() async {
    await stop();
    _tick = 0;
    _songs.clear();
    spectrogram.clear();
    final events = _events = StreamController<RecognitionEvent>();
    _levelTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final t = DateTime.now().millisecondsSinceEpoch / 400;
      final level = 0.35 + 0.25 * math.sin(t) + 0.2 * _random.nextDouble();
      events.add(AudioLevelEvent(level.clamp(0.0, 1.0)));
    });
    _predictTimer = Timer.periodic(hop, (_) => _emit());
    // 5 columns every 40 ms = the real analyzer's 125 columns per second.
    _specTimer = Timer.periodic(
      const Duration(milliseconds: 40),
      (_) => spectrogram.addColumns([for (var i = 0; i < 5; i++) _column()]),
    );
    return events.stream;
  }

  /// One synthetic column: faint ambience plus the songs in progress.
  Uint8List _column() {
    final bands = spectrogram.bands;
    final col = Uint8List(bands);
    for (var b = 0; b < bands; b++) {
      // Low-frequency rumble fading upwards, plus speckle.
      final rumble = 40 * math.exp(-b / 7);
      col[b] = (rumble + _random.nextDouble() * 22).round().clamp(0, 255);
    }
    for (final song in _songs) {
      song.paint(col);
    }
    _songs.removeWhere((s) => s.done);
    return col;
  }

  void _emit() {
    final events = _events;
    if (events == null) return;
    _tick++;
    // Introduce species gradually and repeat them, so grouping is visible.
    final available = math.min(species.length, 1 + _tick ~/ 3);
    final predictions = <Prediction>[];
    for (var i = 0; i < available; i++) {
      if (_random.nextDouble() < 0.45) {
        final base = i == available - 1 && i > 2 ? 0.38 : 0.55;
        predictions.add(
          Prediction(
            species: species[i],
            score: (base + _random.nextDouble() * 0.4).clamp(0.0, 0.99),
          ),
        );
      }
    }
    predictions.sort((a, b) => b.score.compareTo(a.score));
    for (final p in predictions) {
      final key = p.species.scientificName;
      if (_songs.length < 4 && !_songs.any((s) => s.key == key)) {
        _songs.add(_SyntheticSong(key, _random));
      }
    }
    // The songs start now, so pin the marks at the current column.
    spectrogram.mark(predictions, windowSeconds: 0);
    events.add(PredictionEvent(at: DateTime.now(), predictions: predictions));
  }

  @override
  Future<void> stop() async {
    _predictTimer?.cancel();
    _levelTimer?.cancel();
    _specTimer?.cancel();
    _predictTimer = _levelTimer = _specTimer = null;
    await _events?.close();
    _events = null;
  }

  @override
  Future<void> dispose() => stop();
}

/// A made-up song for the demo spectrogram: a species-specific series of
/// swept syllables with a faint harmonic. Purely decorative.
class _SyntheticSong {
  _SyntheticSong(this.key, math.Random random)
    : _h = key.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff),
      _jitter = random.nextDouble() * 4 - 2;

  final String key;
  final int _h;
  final double _jitter;
  int _t = 0;

  int get _syllables => 3 + _h % 5;
  int get _syllableLength => 18 + _h % 17;
  int get _gap => 8 + (_h ~/ 7) % 10;
  double get _center => 30 + (_h ~/ 3) % 36 + _jitter;
  double get _slope => (((_h ~/ 11) % 3) - 1) * 0.45;

  bool get done => _t >= _syllables * (_syllableLength + _gap);

  void paint(Uint8List col) {
    final period = _syllableLength + _gap;
    final pos = _t % period;
    _t++;
    if (pos >= _syllableLength) return;
    final x = pos / _syllableLength;
    final envelope = math.pow(math.sin(math.pi * x), 0.5).toDouble();
    final center = _center + _slope * (pos - _syllableLength / 2);
    void stroke(double c, double strength) {
      for (var b = (c - 6).floor(); b <= (c + 6).ceil(); b++) {
        if (b < 0 || b >= col.length) continue;
        final d = (b - c) / 2.2;
        final v = 255 * strength * envelope * math.exp(-d * d);
        col[b] = math.max(col[b], v.round().clamp(0, 255));
      }
    }

    stroke(center, 0.95);
    stroke(center * 1.45, 0.35);
  }
}
