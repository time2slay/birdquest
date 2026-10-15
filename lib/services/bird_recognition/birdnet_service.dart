import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../audio/audio_capture_service.dart';
import '../audio/pcm.dart';
import '../audio/ring_buffer.dart';
import 'bird_recognition_service.dart';
import 'geo_filter.dart';
import 'labels.dart';
import 'model_manager.dart';
import 'onnx_classifier.dart';
import 'post_processor.dart';

/// Real on-device recognition with BirdNET+ V3.0 (CC BY-SA 4.0).
///
/// Pipeline (modelled on BirdNET Live, MIT): 32 kHz mono PCM16 microphone
/// stream → ring buffer → every [hop] the latest 3 s window → ONNX model →
/// [PostProcessor]. Windows that are effectively silent are skipped because
/// the model's internal normalization returns NaN for constant input.
///
/// When [geoFilterEnabled], the BirdNET+ geo model (Apache-2.0) limits results
/// to species plausible at the user's approximate location and week.
class BirdNetRecognitionService implements BirdRecognitionService {
  BirdNetRecognitionService({
    required this.modelManager,
    AudioCaptureService? capture,
    this.postProcessor = const PostProcessor(),
    this.hop = const Duration(seconds: 1),
    this.geoFilterEnabled = false,
    this.locate = _noLocation,
  }) : _capture = capture ?? AudioCaptureService(sampleRate: sampleRate);

  static const sampleRate = 32000;
  static const windowSamples = 3 * sampleRate;

  /// Digital silence only; real outdoor ambience on an unprocessed mic source
  /// can be as quiet as -80 dBFS and must still be analyzed.
  static const _silenceRms = 1e-6;
  static const _geoRefresh = Duration(minutes: 30);

  static Future<({double latitude, double longitude})?> _noLocation() async =>
      null;

  final ModelManager modelManager;
  final PostProcessor postProcessor;
  final Duration hop;
  final bool geoFilterEnabled;
  final Future<({double latitude, double longitude})?> Function() locate;
  final AudioCaptureService _capture;
  final _classifier = OnnxClassifier();
  final _geo = GeoFilter();
  SpeciesRange? _range;
  Timer? _geoTimer;
  final _buffer = RingBuffer(windowSamples * 2);

  List<ModelLabel>? _labels;
  StreamController<RecognitionEvent>? _events;
  StreamSubscription<Float32List>? _audioSub;
  Timer? _timer;
  bool _inferring = false;
  DateTime _lastLevel = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get isDemo => false;

  @override
  String get modelName => 'BirdNET+ V3.0';

  Future<void> _ensureLoaded() async {
    if (_classifier.isLoaded && _labels != null) return;
    final status = await modelManager.refresh();
    if (status is! ModelInstalled) throw const ModelNotInstalledException();
    final csv = await File(status.labelsPath).readAsString();
    _labels = await compute(parseLabels, csv);
    await _classifier.load(status.modelPath);
    if (geoFilterEnabled) {
      await _geo.load(
        status.geoModelPath,
        await File(status.geoLabelsPath).readAsString(),
      );
    }
  }

  /// Computes the plausible-species set without blocking listening; until
  /// it is ready, all species are shown.
  Future<void> _refreshRange() async {
    final events = _events;
    final labels = _labels;
    if (events == null || labels == null) return;
    if (!geoFilterEnabled) {
      events.add(const GeoFilterEvent(GeoFilterOff()));
      return;
    }
    if (_range == null) events.add(const GeoFilterEvent(GeoFilterLocating()));
    final pos = await locate();
    if (events.isClosed) return;
    if (pos == null) {
      _range = null;
      events.add(
        const GeoFilterEvent(
          GeoFilterUnavailable('Location unavailable — showing all species'),
        ),
      );
      return;
    }
    try {
      final range = await _geo.rangeFor(
        GeoContext(
          latitude: pos.latitude,
          longitude: pos.longitude,
          week: birdnetWeek(DateTime.now()),
        ),
        labels,
      );
      if (events.isClosed) return;
      _range = range;
      events.add(
        GeoFilterEvent(GeoFilterActive(range.plausibleCount, range.allows)),
      );
    } catch (e) {
      if (!events.isClosed) {
        events.add(
          GeoFilterEvent(GeoFilterUnavailable('Location filter failed: $e')),
        );
      }
    }
  }

  @override
  Future<Stream<RecognitionEvent>> start() async {
    await stop();
    await AudioCaptureService.ensurePermission();
    await _ensureLoaded();

    final events = _events = StreamController<RecognitionEvent>();
    _buffer.clear();
    final audio = await _capture.start();
    _audioSub = audio.listen(
      _onAudio,
      onError: (Object e) =>
          events.add(RecognitionErrorEvent('Microphone error: $e')),
    );
    _timer = Timer.periodic(hop, (_) => _infer());
    unawaited(_refreshRange());
    if (geoFilterEnabled) {
      _geoTimer = Timer.periodic(_geoRefresh, (_) => _refreshRange());
    }
    return events.stream;
  }

  void _onAudio(Float32List samples) {
    _buffer.addAll(samples);
    final now = DateTime.now();
    if (now.difference(_lastLevel).inMilliseconds >= 60) {
      _lastLevel = now;
      _events?.add(AudioLevelEvent(rmsToLevel(rms(samples))));
    }
  }

  Future<void> _infer() async {
    final events = _events;
    final labels = _labels;
    if (_inferring || events == null || labels == null) return;
    final window = _buffer.latest(windowSamples);
    if (window == null) return;
    final at = DateTime.now();
    if (rms(window) < _silenceRms) {
      events.add(PredictionEvent(at: at, predictions: const []));
      return;
    }

    _inferring = true;
    try {
      final scores = await _classifier.classify(window);
      if (events.isClosed) return;
      events.add(
        PredictionEvent(
          at: at,
          predictions: postProcessor.process(
            scores,
            labels,
            allow: _range?.allows,
          ),
          window: window,
          sampleRate: sampleRate,
        ),
      );
    } catch (e) {
      if (!events.isClosed) {
        events.add(RecognitionErrorEvent('Recognition failed: $e'));
      }
    } finally {
      _inferring = false;
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _geoTimer?.cancel();
    _timer = _geoTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _capture.stop();
    await _events?.close();
    _events = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _classifier.close();
    await _geo.close();
  }
}
