import 'package:flutter/material.dart';

import 'tokens.dart';

/// Extra semantic colors that Material's [ColorScheme] has no slot for.
@immutable
class NatureColors extends ThemeExtension<NatureColors> {
  const NatureColors({
    required this.canvas,
    required this.moss,
    required this.mossContainer,
    required this.clay,
    required this.clayContainer,
    required this.ochre,
    required this.ochreContainer,
    required this.inkMuted,
  });

  factory NatureColors.fromPalette(BirdQuestPalette p) => NatureColors(
    canvas: p.canvas,
    moss: p.moss,
    mossContainer: p.mossContainer,
    clay: p.clay,
    clayContainer: p.clayContainer,
    ochre: p.ochre,
    ochreContainer: p.ochreContainer,
    inkMuted: p.inkMuted,
  );

  final Color canvas;
  final Color moss;
  final Color mossContainer;
  final Color clay;
  final Color clayContainer;
  final Color ochre;
  final Color ochreContainer;
  final Color inkMuted;

  @override
  NatureColors copyWith() => this;

  @override
  NatureColors lerp(NatureColors? other, double t) {
    if (other == null) return this;
    return NatureColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      moss: Color.lerp(moss, other.moss, t)!,
      mossContainer: Color.lerp(mossContainer, other.mossContainer, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      clayContainer: Color.lerp(clayContainer, other.clayContainer, t)!,
      ochre: Color.lerp(ochre, other.ochre, t)!,
      ochreContainer: Color.lerp(ochreContainer, other.ochreContainer, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
    );
  }
}

extension NatureColorsX on BuildContext {
  NatureColors get nature => Theme.of(this).extension<NatureColors>()!;
}

abstract final class AppTheme {
  static ThemeData light() => _build(BirdQuestPalette.light);

  static ThemeData _build(BirdQuestPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.forest,
      onPrimary: p.onForest,
      primaryContainer: p.mossContainer,
      onPrimaryContainer: p.forestDeep,
      secondary: p.clay,
      onSecondary: Colors.white,
      secondaryContainer: p.clayContainer,
      onSecondaryContainer: const Color(0xFF4A2511),
      tertiary: p.ochre,
      onTertiary: Colors.white,
      tertiaryContainer: p.ochreContainer,
      onTertiaryContainer: const Color(0xFF4A3608),
      error: p.error,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.canvas,
      surfaceContainer: p.surfaceMuted,
      surfaceContainerHigh: p.surfaceMuted,
      surfaceContainerHighest: p.outline,
      outline: p.outline,
      outlineVariant: p.outline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      extensions: [NatureColors.fromPalette(p)],
    );

    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: p.ink,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: p.ink,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: p.ink,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: p.ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: p.ink,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: p.ink,
        height: 1.4,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: p.inkMuted),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: p.outline.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: p.forest,
          side: BorderSide(color: p.forest.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.surfaceMuted,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(color: p.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.mossContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.forestDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.outline, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
