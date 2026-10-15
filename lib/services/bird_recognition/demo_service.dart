import 'dart:async';
import 'dart:math' as math;

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
  int _tick = 0;

  static const species = fieldGuideSpecies;

  @override
  bool get isDemo => true;

  @override
  String get modelName => 'Demo mode (simulated)';

  @override
  Future<Stream<RecognitionEvent>> start() async {
    await stop();
    _tick = 0;
    final events = _events = StreamController<RecognitionEvent>();
    _levelTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final t = DateTime.now().millisecondsSinceEpoch / 400;
      final level = 0.35 + 0.25 * math.sin(t) + 0.2 * _random.nextDouble();
      events.add(AudioLevelEvent(level.clamp(0.0, 1.0)));
    });
    _predictTimer = Timer.periodic(hop, (_) => _emit());
    return events.stream;
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
    events.add(PredictionEvent(at: DateTime.now(), predictions: predictions));
  }

  @override
  Future<void> stop() async {
    _predictTimer?.cancel();
    _levelTimer?.cancel();
    _predictTimer = _levelTimer = null;
    await _events?.close();
    _events = null;
  }

  @override
  Future<void> dispose() => stop();
}
