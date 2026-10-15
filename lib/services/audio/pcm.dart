import 'dart:math' as math;
import 'dart:typed_data';

/// Converts little-endian PCM16 bytes to mono floats in [-1, 1), averaging
/// [channels] interleaved channels. Trailing partial frames are ignored.
Float32List pcm16ToFloat32(Uint8List bytes, {int channels = 1}) {
  final frameBytes = 2 * channels;
  final frames = bytes.lengthInBytes ~/ frameBytes;
  final data = ByteData.sublistView(bytes);
  final out = Float32List(frames);
  for (var f = 0; f < frames; f++) {
    var sum = 0;
    for (var c = 0; c < channels; c++) {
      sum += data.getInt16((f * channels + c) * 2, Endian.little);
    }
    out[f] = sum / channels / 32768.0;
  }
  return out;
}

/// Root-mean-square level of [samples].
double rms(Float32List samples) {
  if (samples.isEmpty) return 0;
  var sum = 0.0;
  for (final s in samples) {
    sum += s * s;
  }
  return math.sqrt(sum / samples.length);
}

/// Maps an RMS value to a perceptual 0..1 level for UI meters.
///
/// Android's unprocessed microphone source has no automatic gain, so outdoor
/// ambience sits around -70 dBFS; the meter therefore spans -90..-30 dBFS.
double rmsToLevel(double rmsValue) {
  if (rmsValue <= 0) return 0;
  final db = 20 * math.log(rmsValue) / math.ln10;
  return ((db + 90) / 60).clamp(0.0, 1.0);
}
