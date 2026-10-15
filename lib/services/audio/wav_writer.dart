import 'dart:io';
import 'dart:typed_data';

/// Returns a peak-normalized copy for listening. Raw unprocessed-mic audio is
/// often 40+ dB below full scale and would play back as near silence.
/// Gain is capped so that background hiss is not blown up.
Float32List normalizeForPlayback(
  Float32List samples, {
  double targetPeak = 0.9,
  double maxGain = 200,
}) {
  var peak = 0.0;
  for (final s in samples) {
    final a = s.abs();
    if (a > peak) peak = a;
  }
  if (peak == 0) return Float32List.fromList(samples);
  final gain = (targetPeak / peak).clamp(1.0, maxGain);
  return Float32List.fromList([for (final s in samples) s * gain]);
}

/// Encodes mono float samples as a 16-bit PCM WAV file.
Uint8List encodeWav(Float32List samples, {int sampleRate = 32000}) {
  const headerSize = 44;
  final dataSize = samples.length * 2;
  final bytes = ByteData(headerSize + dataSize);

  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little); // PCM chunk size
  bytes.setUint16(20, 1, Endian.little); // PCM format
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  bytes.setUint16(32, 2, Endian.little); // block align
  bytes.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(headerSize + i * 2, v, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

Future<File> writeWav(
  String path,
  Float32List samples, {
  int sampleRate = 32000,
}) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  return file.writeAsBytes(encodeWav(samples, sampleRate: sampleRate));
}
