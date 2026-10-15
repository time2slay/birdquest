import 'package:birdquest/app/providers.dart';
import 'package:birdquest/features/onboarding/onboarding_screen.dart';
import 'package:birdquest/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// The app's first-launch redirect, with a stand-in home screen.
  Future<void> pumpApp(WidgetTester tester, {String language = 'en'}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          deviceLanguageProvider.overrideWithValue(language),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: GoRouter(
              redirect: (_, state) =>
                  state.matchedLocation == '/' &&
                      !ref.read(onboardingDoneProvider)
                  ? '/welcome'
                  : null,
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const Scaffold(body: Text('HOME')),
                ),
                GoRoute(
                  path: '/welcome',
                  builder: (_, _) => const OnboardingScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch walks through all pages, then opens the app', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Welcome to BirdQuest'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);

    for (final title in [
      '1. Listen',
      '2. Save discoveries',
      '3. Map & achievements',
      '4. Field guide',
    ]) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Skip'), findsNothing, reason: 'last page');

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(prefs.getBool('onboarding_done'), isTrue);
  });

  testWidgets('skip finishes the tutorial; it does not show again', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    await pumpApp(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('Welcome to BirdQuest'), findsNothing);
  });

  testWidgets('landscape keeps the title and Next button on screen', (
    tester,
  ) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to BirdQuest').hitTestable(), findsOneWidget);
    expect(find.text('Next').hitTestable(), findsOneWidget);
  });

  testWidgets('Russian phone gets Russian text; EN/RU switch changes it', (
    tester,
  ) async {
    await pumpApp(tester, language: 'ru');
    expect(find.text('Добро пожаловать в BirdQuest'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to BirdQuest'), findsOneWidget);
    expect(prefs.getString('guide_language'), 'en');
  });
}
