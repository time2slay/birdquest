import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// App-bar button that cycles System → Day → Night. The icon always shows
/// the current choice; "System" follows the phone's dark-mode setting.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  static const _next = {
    ThemeMode.system: ThemeMode.light,
    ThemeMode.light: ThemeMode.dark,
    ThemeMode.dark: ThemeMode.system,
  };

  static String label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System theme',
    ThemeMode.light => 'Day theme',
    ThemeMode.dark => 'Night theme',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
    return IconButton(
      tooltip: '${label(mode)} · tap to change',
      onPressed: () {
        final next = _next[mode]!;
        ref.read(themeModeProvider.notifier).set(next);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next == ThemeMode.system
                    ? 'System theme · follows your phone'
                    : label(next),
              ),
              duration: const Duration(milliseconds: 1400),
            ),
          );
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(icon, key: ValueKey(mode)),
      ),
    );
  }
}
