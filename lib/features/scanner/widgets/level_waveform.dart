import 'package:flutter/material.dart';

/// Bar waveform of recent microphone input levels.
class LevelWaveform extends StatelessWidget {
  const LevelWaveform({
    super.key,
    required this.levels,
    this.bars = 48,
    this.height = 48,
    this.color = Colors.white,
  });

  /// Levels 0..1, oldest first.
  final List<double> levels;
  final int bars;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter(levels, bars, color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.levels, this.bars, this.color);

  final List<double> levels;
  final int bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / bars;
    final barWidth = slot * 0.55;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final offset = bars - levels.length;
    for (var i = 0; i < bars; i++) {
      final li = i - offset;
      final level = li >= 0 ? levels[li] : 0.0;
      final h = (0.06 + level * 0.94) * size.height;
      final x = slot * i + slot / 2;
      final age = (i / bars);
      paint.color = color.withValues(alpha: 0.25 + 0.75 * age);
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.levels != levels || old.color != color;
}
