import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// Thin wrapper around an ONNX Runtime session for the BirdNET+ audio model.
///
/// Inference runs on ONNX Runtime's native threads, so the Dart UI isolate
/// only awaits the result.
class OnnxClassifier {
  static const _inputName = 'input';
  static const _outputName = 'predictions';

  final _ort = OnnxRuntime();
  OrtSession? _session;

  bool get isLoaded => _session != null;

  Future<void> load(String modelPath) async {
    await close();
    _session = await _ort.createSession(
      modelPath,
      options: OrtSessionOptions(
        // ORT ≥1.23 KleidiAI kernels have crashed on arm64 Android; BirdNET
        // Live disables them (birdnet-team/birdnet-live-app, MIT).
        sessionConfigs: const {'mlas.disable_kleidiai': '1'},
      ),
    );
  }

  /// Returns one score per label for a single window of mono samples.
  Future<List<double>> classify(Float32List window) async {
    final session = _session;
    if (session == null) throw StateError('Model not loaded');
    final input = await OrtValue.fromList(window, [1, window.length]);
    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({_inputName: input});
      final tensor = outputs[_outputName];
      if (tensor == null) {
        throw StateError('Model output "$_outputName" missing');
      }
      final raw = await tensor.asFlattenedList();
      return [for (final v in raw) (v as num).toDouble()];
    } finally {
      await input.dispose();
      for (final t in outputs?.values ?? const <OrtValue>[]) {
        await t.dispose();
      }
    }
  }

  Future<void> close() async {
    final s = _session;
    _session = null;
    await s?.close();
  }
}
