import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'photo_credit.dart';

/// Shows a species image with this priority: the user's own cover photo,
/// a licensed reference image (bundled asset or Wikimedia Commons photo for
/// [scientificName]), or a clearly labeled placeholder illustration.
class BirdImage extends ConsumerWidget {
  const BirdImage({
    super.key,
    required this.name,
    this.scientificName,
    this.coverPhotoPath,
    this.referenceImage,
    this.borderRadius = BorderRadius.zero,
    this.showPlaceholderLabel = true,
    this.showCredit = false,
    this.cacheWidth,
  });

  final String name;

  /// Looks up a Commons reference photo when given.
  final String? scientificName;

  /// Overlays the photo credit (required by CC licenses on large images).
  final bool showCredit;

  /// Relative media path of a user photo.
  final String? coverPhotoPath;

  /// Asset path of a licensed reference image.
  final String? referenceImage;
  final BorderRadius borderRadius;
  final bool showPlaceholderLabel;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget child;
    if (coverPhotoPath != null) {
      child = Image.file(
        ref.watch(mediaStoreProvider).file(coverPhotoPath!),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else if (referenceImage != null) {
      child = Image.asset(
        referenceImage!,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    } else if (scientificName != null) {
      final ref0 = ref.watch(referencePhotoProvider(scientificName!)).value;
      child = ref0 == null
          ? _placeholder(context)
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  ref0.file,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  errorBuilder: (_, _, _) => _placeholder(context),
                ),
                if (showCredit)
                  Positioned(
                    left: Space.sm,
                    bottom: Space.sm,
                    child: PhotoCreditChip(photo: ref0.photo),
                  ),
              ],
            );
    } else {
      child = _placeholder(context);
    }
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  Widget _placeholder(BuildContext context) =>
      BirdPlaceholder(name: name, showLabel: showPlaceholderLabel);
}

/// A generated illustration standing in for a licensed bird photograph.
class BirdPlaceholder extends StatelessWidget {
  const BirdPlaceholder({super.key, required this.name, this.showLabel = true});

  final String name;
  final bool showLabel;

  static const _gradients = [
    [Color(0xFF2F5D3A), Color(0xFF6B8F4E)],
    [Color(0xFF3E5C4A), Color(0xFFC79A3B)],
    [Color(0xFF51463A), Color(0xFFB4673F)],
    [Color(0xFF2C4F57), Color(0xFF6B8F4E)],
    [Color(0xFF4A5A2F), Color(0xFFD9B26A)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[name.hashCode.abs() % _gradients.length];
    return Semantics(
      label: 'Placeholder illustration for $name',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final size = c.biggest.shortestSide;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -size * 0.08,
                  bottom: -size * 0.04,
                  width: size * 0.9,
                  height: size * 0.9,
                  child: CustomPaint(
                    painter: _BirdSilhouettePainter(
                      Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Center(
                  child: CustomPaint(
                    size: Size.square(size * 0.42),
                    painter: _BirdSilhouettePainter(
                      Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (showLabel && size > 90)
                  Positioned(
                    left: Space.sm,
                    bottom: Space.sm,
                    child: _PlaceholderTag(compact: size < 160),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceholderTag extends StatelessWidget {
  const _PlaceholderTag({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        compact ? 'Placeholder' : 'Placeholder illustration · no photo yet',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// A simple perched-songbird silhouette.
class _BirdSilhouettePainter extends CustomPainter {
  _BirdSilhouettePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(0.18 * w, 0.30 * h) // beak tip
      ..lineTo(0.30 * w, 0.27 * h)
      ..cubicTo(0.33 * w, 0.14 * h, 0.50 * w, 0.12 * h, 0.55 * w, 0.26 * h)
      ..cubicTo(0.70 * w, 0.30 * h, 0.82 * w, 0.42 * h, 0.95 * w, 0.62 * h)
      ..lineTo(0.80 * w, 0.62 * h)
      ..cubicTo(0.72 * w, 0.72 * h, 0.55 * w, 0.78 * h, 0.44 * w, 0.72 * h)
      ..cubicTo(0.30 * w, 0.66 * h, 0.27 * w, 0.48 * h, 0.33 * w, 0.36 * h)
      ..close();
    final legs = Paint()
      ..color = color
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    final paint = Paint()..color = color;
    canvas.drawPath(body, paint);
    canvas.drawLine(
      Offset(0.47 * w, 0.74 * h),
      Offset(0.45 * w, 0.88 * h),
      legs,
    );
    canvas.drawLine(
      Offset(0.55 * w, 0.74 * h),
      Offset(0.56 * w, 0.88 * h),
      legs,
    );
    canvas.drawLine(
      Offset(0.30 * w, 0.89 * h),
      Offset(0.75 * w, 0.89 * h),
      legs,
    );
  }

  @override
  bool shouldRepaint(_BirdSilhouettePainter old) => old.color != color;
}

/// A user photo from app storage.
class MediaPhoto extends ConsumerWidget {
  const MediaPhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.absolute = false,
  });

  /// Relative media path, or an absolute path when [absolute] is true.
  final String path;
  final BoxFit fit;
  final int? cacheWidth;
  final bool absolute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = absolute
        ? File(path)
        : ref.watch(mediaStoreProvider).file(path);
    return Image.file(
      file,
      fit: fit,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => ColoredBox(
        color: context.nature.canvas,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
