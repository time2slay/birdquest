import 'dart:math' as math;
import 'dart:typed_data';

/// Fixed-capacity circular buffer of mono float samples.
class RingBuffer {
  RingBuffer(this.capacity) : _data = Float32List(capacity);

  final int capacity;
  final Float32List _data;
  int _write = 0;
  int _length = 0;

  /// Number of valid samples currently held (≤ [capacity]).
  int get length => _length;

  void clear() {
    _write = 0;
    _length = 0;
  }

  void addAll(Float32List samples) {
    var src = samples;
    if (src.length > capacity) {
      src = Float32List.sublistView(src, src.length - capacity);
    }
    final first = math.min(src.length, capacity - _write);
    _data.setRange(_write, _write + first, src);
    final rest = src.length - first;
    if (rest > 0) _data.setRange(0, rest, src, first);
    _write = (_write + src.length) % capacity;
    _length = math.min(capacity, _length + src.length);
  }

  /// Copies the most recent [count] samples, oldest first. Returns null when
  /// fewer than [count] samples are available.
  Float32List? latest(int count) {
    if (count > _length) return null;
    final out = Float32List(count);
    final start = (_write - count) % capacity;
    final first = math.min(count, capacity - start);
    out.setRange(0, first, _data, start);
    if (count > first) out.setRange(first, count, _data, 0);
    return out;
  }
}
