import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../bird_recognition/bird_recognition_service.dart';
import 'pcm.dart';

/// Streams raw microphone audio as mono float samples.
///
/// Uses the unprocessed Android source with gain control, echo cancellation
/// and noise suppression off, since those filters distort bird song.
class AudioCaptureService {
  AudioCaptureService({this.sampleRate = 32000});

  final int sampleRate;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _sub;
  final _carry = BytesBuilder(copy: false);

  /// Requests the microphone permission if needed.
  static Future<void> ensurePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw MicrophonePermissionException(
        permanentlyDenied: status.isPermanentlyDenied,
      );
    }
  }

  Future<Stream<Float32List>> start() async {
    await ensurePermission();
    await stop();
    final recorder = _recorder = AudioRecorder();
    final bytes = await recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        androidConfig: const AndroidRecordConfig(
          audioSource: AndroidAudioSource.unprocessed,
          manageBluetooth: false,
        ),
      ),
    );

    final controller = StreamController<Float32List>();
    _sub = bytes.listen(
      (chunk) {
        // Keep sample alignment if a chunk ends mid-sample.
        _carry.add(chunk);
        final all = _carry.takeBytes();
        final even = all.length & ~1;
        if (even < all.length) _carry.add(all.sublist(even));
        if (even > 0) {
          controller.add(pcm16ToFloat32(Uint8List.sublistView(all, 0, even)));
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = stop;
    return controller.stream;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _carry.clear();
    final r = _recorder;
    _recorder = null;
    if (r != null) {
      try {
        await r.stop();
      } finally {
        await r.dispose();
      }
    }
  }
}
