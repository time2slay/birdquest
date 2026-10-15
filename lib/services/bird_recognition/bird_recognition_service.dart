import 'prediction.dart';

export 'prediction.dart';

/// Thrown when the microphone permission is missing.
class MicrophonePermissionException implements Exception {
  const MicrophonePermissionException({this.permanentlyDenied = false});
  final bool permanentlyDenied;

  @override
  String toString() => 'Microphone permission denied';
}

/// Thrown when the recognition model has not been downloaded yet.
class ModelNotInstalledException implements Exception {
  const ModelNotInstalledException();

  @override
  String toString() => 'Recognition model is not installed';
}

/// The integration boundary between the UI and any bird sound recognizer.
///
/// Implementations: [BirdNetRecognitionService] (real, on-device) and
/// [DemoRecognitionService] (simulated, always labeled as demo in the UI).
abstract interface class BirdRecognitionService {
  /// True when results are simulated. The UI must label them as such.
  bool get isDemo;

  /// Human-readable model name for attribution, e.g. "BirdNET+ V3.0".
  String get modelName;

  /// Starts listening. Throws [MicrophonePermissionException] or
  /// [ModelNotInstalledException] when listening is not possible.
  Future<Stream<RecognitionEvent>> start();

  /// Stops listening and releases the microphone. Safe to call repeatedly.
  Future<void> stop();

  /// Releases all resources, including loaded models.
  Future<void> dispose();
}
