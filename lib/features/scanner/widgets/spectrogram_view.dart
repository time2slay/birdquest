import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/audio/spectrogram.dart';
import '../../../shared/theme/illustrations.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/widgets/bird_image.dart';
import '../../../shared/widgets/guide_description.dart';

/// Colors of the spectrogram window: [background] behind the audio and a
/// [ramp] from quiet to loud. The scanner card is dark forest in both themes,
/// so the day ramp is warmer (ochre, cream) and the night ramp cooler (teal,
/// moonlight gold).
@immutable
class SpectrogramPalette {
  const SpectrogramPalette({required this.background, required this.ramp});

  final List<Color> background;
  final List<(double, Color)> ramp;

  static const day = SpectrogramPalette(
    background: [Color(0xFF14321F), Color(0xFF0C2215)],
    ramp: [
      (0.00, Color(0x001E3F27)),
      (0.12, Color(0x662F5D3A)),
      (0.30, Color(0xCC4F7A45)),
      (0.50, Color(0xFF8DB573)),
      (0.70, Color(0xFFC79A3B)),
      (0.86, Color(0xFFF0C978)),
      (1.00, Color(0xFFFFF6DC)),
    ],
  );

  static const night = SpectrogramPalette(
    background: [Color(0xFF0E2219), Color(0xFF07140E)],
    ramp: [
      (0.00, Color(0x00122A20)),
      (0.12, Color(0x661D4A3E)),
      (0.30, Color(0xCC2F7266)),
      (0.50, Color(0xFF6FB7A8)),
      (0.70, Color(0xFF9CCB9F)),
      (0.86, Color(0xFFE0B65A)),
      (1.00, Color(0xFFFFF4D6)),
    ],
  );

  static SpectrogramPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : day;

  /// 256 premultiplied RGBA entries.
  Uint32List lut() {
    final out = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      final t = i / 255;
      var k = 0;
      while (k < ramp.length - 2 && t > ramp[k + 1].$1) {
        k++;
      }
      final (t0, c0) = ramp[k];
      final (t1, c1) = ramp[k + 1];
      final c = Color.lerp(c0, c1, ((t - t0) / (t1 - t0)).clamp(0.0, 1.0))!;
      final a = c.a;
      final r = (c.r * a * 255).round();
      final g = (c.g * a * 255).round();
      final b = (c.b * a * 255).round();
      // Little-endian RGBA in memory.
      out[i] = (a * 255).round() << 24 | b << 16 | g << 8 | r;
    }
    return out;
  }
}

/// The live spectrogram set into a painted foliage border (generated with
/// Google Flow): the audio window sits in the clearing and the grass and
/// branches overlap its edges.
class FramedSpectrogram extends StatelessWidget {
  const FramedSpectrogram({
    super.key,
    required this.buffer,
    required this.active,
  });

  final SpectrogramBuffer buffer;
  final bool active;

  /// Width / height of the whole piece. The art is 16:9 and stretched a
  /// little taller to give the audio more room.
  static const aspect = 1.55;

  /// Where the clearing is, as fractions of the frame.
  static const _left = 0.085, _right = 0.085, _top = 0.2, _bottom = 0.24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w / aspect;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned(
                left: w * _left,
                right: w * _right,
                top: h * _top,
                bottom: h * _bottom,
                child: SpectrogramView(
                  buffer: buffer,
                  active: active,
                  height: h * (1 - _top - _bottom),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    Illustrations.forBrightness(
                      context,
                      Illustrations.spectrogramFrame,
                    ),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Live scrolling spectrogram with the species heard pinned where they sang.
///
/// Reads a [SpectrogramBuffer] directly (not through scanner state), scrolls
/// smoothly at the buffer's nominal rate between audio chunks, and freezes
/// when listening stops.
class SpectrogramView extends ConsumerStatefulWidget {
  const SpectrogramView({
    super.key,
    required this.buffer,
    required this.active,
    this.height = 150,
    this.seconds = 5,
    this.sampleRate = 32000,
    this.fftSize = 512,
    this.maxHz = 12000,
  });

  final SpectrogramBuffer buffer;

  /// Scrolls only while true; otherwise the last picture stays.
  final bool active;
  final double height;

  /// Visible history.
  final double seconds;

  // Analyzer geometry, for the frequency guide lines.
  final int sampleRate;
  final int fftSize;
  final double maxHz;

  @override
  ConsumerState<SpectrogramView> createState() => _SpectrogramViewState();
}

class _SpectrogramViewState extends ConsumerState<SpectrogramView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _head = 0; // smoothly advancing display position, in columns
  ui.Image? _image;
  int _imageHead = 0; // totalColumns when _image was built
  int _imageWidth = 0;
  bool _decoding = false;
  Uint32List? _lut;
  Brightness? _lutFor;

  int get _visible => (widget.seconds * widget.buffer.columnRate).round();

  @override
  void initState() {
    super.initState();
    _head = widget.buffer.totalColumns.toDouble();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SpectrogramView old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.0
        : math.max(0.0, (elapsed - _lastTick).inMicroseconds / 1e6);
    _lastTick = elapsed;
    final buffer = widget.buffer;
    final total = buffer.totalColumns.toDouble();
    final before = _head;
    if (total < _head) {
      _head = total; // buffer was cleared
    } else if (widget.active) {
      _head = math.min(total, _head + dt * buffer.columnRate);
      // Audio arrives in chunks; stay a little behind, but never far.
      if (total - _head > buffer.columnRate * 0.35) {
        _head = total - buffer.columnRate * 0.1;
      }
    } else {
      _head = total;
    }
    if (!_decoding && buffer.totalColumns != _imageHead) _rebuildImage();
    if (!mounted) return;
    if (_head != before) {
      setState(() {});
    } else if (!widget.active) {
      // Idle: the pending decode (if any) repaints when it lands; the ticker
      // restarts when listening resumes.
      _ticker.stop();
    }
  }

  // Colored pixels kept as a ring over columns, so each rebuild only colors
  // the columns that arrived since the last one.
  Uint32List? _ring;
  int _ringWidth = 0;
  int _ringHead = 0; // absolute column after the newest colored one
  Uint32List? _linear;

  void _rebuildImage() {
    final buffer = widget.buffer;
    final lut = _lut;
    if (lut == null) return;
    _decoding = true;
    final head = buffer.totalColumns;
    final width = _visible + 64;
    final bands = buffer.bands;
    var ring = _ring;
    if (ring == null ||
        _ringWidth != width ||
        _imageHead < 0 ||
        head < _ringHead) {
      ring = _ring = Uint32List(width * bands);
      _linear = Uint32List(width * bands);
      _ringWidth = width;
      _ringHead = head - width;
    }
    for (var col = math.max(_ringHead, head - width); col < head; col++) {
      final x = col % width;
      for (var band = 0; band < bands; band++) {
        ring[(bands - 1 - band) * width + x] = lut[buffer.value(col, band)];
      }
    }
    _ringHead = head;
    // Unroll the ring: oldest column first.
    final pixels = _linear!;
    final split = head % width;
    for (var row = 0; row < bands; row++) {
      final o = row * width;
      pixels.setRange(o, o + width - split, ring, o + split);
      pixels.setRange(o + width - split, o + width, ring, o);
    }
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      bands,
      ui.PixelFormat.rgba8888,
      (image) {
        _decoding = false;
        if (!mounted) {
          image.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = image;
          _imageHead = head;
          _imageWidth = width;
        });
        // Catch up on columns that arrived while decoding when idle.
        if (!_ticker.isActive && widget.buffer.totalColumns != head) {
          _rebuildImage();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SpectrogramPalette.of(context);
    final brightness = Theme.of(context).brightness;
    if (_lutFor != brightness) {
      _lut = palette.lut();
      _lutFor = brightness;
      _imageHead = -1; // force a rebuild in the new colors
      if (!_decoding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_decoding) _rebuildImage();
        });
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pxPerColumn = width / _visible;
        final marks = widget.buffer.marks;
        _assignLanes(marks, pxPerColumn);
        final chips = <Widget>[];
        for (var i = 0; i < marks.length; i++) {
          final m = marks[i];
          final lane = _lanes[_markKey(m)];
          if (lane == null || lane < 0) continue; // no room: stem only
          final x = width - (_head - m.column) * pxPerColumn;
          if (x < -40 || x > width + 4) continue;
          // Fade in when new, fade out near the left edge.
          final age = (_head - m.column) / widget.buffer.columnRate;
          final opacity =
              (math.min(1.0, age * 3 + 0.2) *
                      ((x / (width * 0.18)).clamp(0.0, 1.0)))
                  .clamp(0.0, 1.0);
          chips.add(
            Positioned(
              left: x - 14,
              top: 5.0 + lane * 24,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: _MarkChip(mark: m),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpectrogramPainter(
                    image: _image,
                    imageHead: _imageHead,
                    imageWidth: _imageWidth,
                    head: _head,
                    visible: _visible,
                    palette: palette,
                    marks: marks,
                    guides: _guides(),
                    active: widget.active,
                  ),
                ),
              ),
              ...chips,
            ],
          ),
        );
      },
    );
  }

  /// Label lane per mark, assigned once so labels never jump: the first of
  /// two lanes whose previous label has moved far enough left, or -1 when
  /// both are taken (the dotted stem still marks the spot).
  final Map<String, int> _lanes = {};
  static const _chipWidth = 132.0; // widest label, in dp

  static String _markKey(SpectrogramMark m) =>
      '${m.species.scientificName}@${m.column}';

  void _assignLanes(List<SpectrogramMark> marks, double pxPerColumn) {
    final live = {for (final m in marks) _markKey(m)};
    _lanes.removeWhere((k, _) => !live.contains(k));
    final sorted = [...marks]..sort((a, b) => a.column.compareTo(b.column));
    final gap = _chipWidth / pxPerColumn;
    final lastInLane = <int, int>{};
    for (final m in sorted) {
      final key = _markKey(m);
      final lane = _lanes.putIfAbsent(key, () {
        for (var l = 0; l < 2; l++) {
          final prev = lastInLane[l];
          if (prev == null || m.column - prev >= gap) return l;
        }
        return -1;
      });
      if (lane >= 0) lastInLane[lane] = m.column;
    }
  }

  /// (fraction of height from the bottom, label) for 2/4/8 kHz.
  List<(double, String)> _guides() {
    final maxBin = (widget.maxHz / widget.sampleRate * widget.fftSize).floor();
    final edges = SpectrogramAnalyzer.bandEdges(
      bands: widget.buffer.bands,
      maxBin: maxBin,
    );
    final out = <(double, String)>[];
    for (final khz in [2, 4, 8]) {
      final bin = khz * 1000 / widget.sampleRate * widget.fftSize;
      var b = 0;
      while (b < edges.length - 1 && edges[b + 1] <= bin) {
        b++;
      }
      out.add((b / widget.buffer.bands, '$khz kHz'));
    }
    return out;
  }
}

class _SpectrogramPainter extends CustomPainter {
  _SpectrogramPainter({
    required this.image,
    required this.imageHead,
    required this.imageWidth,
    required this.head,
    required this.visible,
    required this.palette,
    required this.marks,
    required this.guides,
    required this.active,
  });

  final ui.Image? image;
  final int imageHead;
  final int imageWidth;
  final double head;
  final int visible;
  final SpectrogramPalette palette;
  final List<SpectrogramMark> marks;
  final List<(double, String)> guides;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(Radii.lg),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.background,
        ).createShader(rect),
    );

    // Audio, faded in from the left edge.
    canvas.saveLayer(rect, Paint());
    final img = image;
    if (img != null && imageWidth > 0) {
      final firstInImage = imageHead - imageWidth;
      final srcLeft = head - visible - firstInImage;
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(srcLeft, 0, visible.toDouble(), img.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final pxPerColumn = size.width / visible;
    final stem = Paint()
      ..color = const Color(0xCCE0B65A)
      ..strokeWidth = 1.2;
    for (final m in marks) {
      final x = size.width - (head - m.column) * pxPerColumn;
      if (x < 0 || x > size.width) continue;
      for (var y = 26.0; y < size.height; y += 6) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 2.5), stem);
      }
    }
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          colors: [Color(0x00000000), Color(0xFF000000), Color(0xFF000000)],
          stops: [0, 0.16, 1],
        ).createShader(rect),
    );
    canvas.restore();

    // Frequency guides.
    final guidePaint = Paint()
      ..color = const Color(0x1FFFFFFF)
      ..strokeWidth = 1;
    for (final (f, label) in guides) {
      final y = size.height * (1 - f);
      for (var x = 40.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(x + 3, y), guidePaint);
      }
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0x8CFFFFFF),
            fontSize: 9.5,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, y - tp.height / 2));
    }

    // The "now" edge: a soft glow while listening.
    if (active) {
      final edge = Rect.fromLTWH(size.width - 26, 0, 26, size.height);
      canvas.drawRect(
        edge,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x00FFF4D6), Color(0x33FFF4D6)],
          ).createShader(edge),
      );
      canvas.drawLine(
        Offset(size.width - 1.5, 0),
        Offset(size.width - 1.5, size.height),
        Paint()
          ..color = const Color(0x99FFF4D6)
          ..strokeWidth = 1.5,
      );
    }

    // Inner shadow for depth.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpectrogramPainter old) => true;
}

class _MarkChip extends ConsumerWidget {
  const _MarkChip({required this.mark});

  final SpectrogramMark mark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = mark.species;
    final name = speciesDisplayName(ref, s.scientificName, s.commonName);
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 7, 2),
      decoration: BoxDecoration(
        color: const Color(0xD9102A19),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: const Color(0x8CE0B65A), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 17,
            child: BirdImage(
              name: s.commonName,
              scientificName: s.scientificName,
              borderRadius: BorderRadius.circular(9),
              showPlaceholderLabel: false,
              cacheWidth: 51,
            ),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 92),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFF4D6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
