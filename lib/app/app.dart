import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_theme.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'providers.dart';
import 'router.dart';

class BirdQuestApp extends ConsumerStatefulWidget {
  const BirdQuestApp({super.key});

  @override
  ConsumerState<BirdQuestApp> createState() => _BirdQuestAppState();
}

class _BirdQuestAppState extends ConsumerState<BirdQuestApp> {
  late final GoRouter _router = buildRouter(
    needsOnboarding: () => !ref.read(onboardingDoneProvider),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BirdQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: _router,
      // Keep content (and bottom buttons) clear of the system navigation
      // bar on edge-to-edge Android; in landscape it sits on the side.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(top: false, child: child!),
      ),
    );
  }
}
