import 'package:flutter/material.dart';

/// Raw design tokens for BirdQuest.
///
/// Every color the UI uses comes from a [BirdQuestPalette]. Only the light
/// palette ships today; a dark palette only needs a second instance.
@immutable
class BirdQuestPalette {
  const BirdQuestPalette({
    required this.brightness,
    required this.forest,
    required this.forestDeep,
    required this.onForest,
    required this.moss,
    required this.mossContainer,
    required this.clay,
    required this.clayContainer,
    required this.ochre,
    required this.ochreContainer,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.error,
  });

  final Brightness brightness;
  final Color forest;
  final Color forestDeep;
  final Color onForest;
  final Color moss;
  final Color mossContainer;
  final Color clay;
  final Color clayContainer;
  final Color ochre;
  final Color ochreContainer;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color error;

  static const light = BirdQuestPalette(
    brightness: Brightness.light,
    forest: Color(0xFF2F5D3A),
    forestDeep: Color(0xFF1E3F27),
    onForest: Color(0xFFFFFFFF),
    moss: Color(0xFF6B8F4E),
    mossContainer: Color(0xFFDDE8CF),
    clay: Color(0xFFB4673F),
    clayContainer: Color(0xFFF4DCCB),
    ochre: Color(0xFFC79A3B),
    ochreContainer: Color(0xFFF5E7C4),
    canvas: Color(0xFFF7F3EA),
    surface: Color(0xFFFFFDF8),
    surfaceMuted: Color(0xFFEEE8DA),
    ink: Color(0xFF1F2A22),
    inkMuted: Color(0xFF5E6A60),
    outline: Color(0xFFD5CDBB),
    error: Color(0xFFB3261E),
  );
}

/// Spacing scale (4-pt grid).
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Motion durations.
abstract final class Motion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 450);
}
