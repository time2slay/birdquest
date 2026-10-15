import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/theme/app_theme.dart';
import 'router.dart';

class BirdQuestApp extends StatefulWidget {
  const BirdQuestApp({super.key});

  @override
  State<BirdQuestApp> createState() => _BirdQuestAppState();
}

class _BirdQuestAppState extends State<BirdQuestApp> {
  late final GoRouter _router = buildRouter();

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
      // Dark mode: add BirdQuestPalette.dark and AppTheme.dark().
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
