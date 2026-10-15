import 'package:flutter/material.dart';

/// Raw design tokens for BirdQuest.
///
/// Every color the UI uses comes from a [BirdQuestPalette]: a warm
/// field-guide [light] palette and a moonlit-forest [dark] one.
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
    required this.onMossContainer,
    required this.onClayContainer,
    required this.onOchreContainer,
    required this.onAccent,
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

  /// Text/icon colors on the tinted containers and on accent fills.
  final Color onMossContainer;
  final Color onClayContainer;
  final Color onOchreContainer;
  final Color onAccent;

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
    onMossContainer: Color(0xFF244A2D),
    onClayContainer: Color(0xFF7A3A18),
    onOchreContainer: Color(0xFF6B4E0F),
    onAccent: Color(0xFFFFFFFF),
  );

  /// Moonlit forest: deep green-black canvas, soft mint primary.
  static const dark = BirdQuestPalette(
    brightness: Brightness.dark,
    forest: Color(0xFF9CCB9F),
    forestDeep: Color(0xFFCDE8CF),
    onForest: Color(0xFF0E3018),
    moss: Color(0xFF8DB573),
    mossContainer: Color(0xFF263A2B),
    clay: Color(0xFFE0A27F),
    clayContainer: Color(0xFF472C1F),
    ochre: Color(0xFFE0B65A),
    ochreContainer: Color(0xFF423719),
    canvas: Color(0xFF121814),
    surface: Color(0xFF1A221D),
    surfaceMuted: Color(0xFF243029),
    ink: Color(0xFFE8EDE6),
    inkMuted: Color(0xFFA3B0A6),
    outline: Color(0xFF34443A),
    error: Color(0xFFFFB4AB),
    onMossContainer: Color(0xFFCDE8CF),
    onClayContainer: Color(0xFFF6CDB6),
    onOchreContainer: Color(0xFFF3DDA6),
    onAccent: Color(0xFF1A221D),
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
