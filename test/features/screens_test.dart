import 'dart:io';

import 'package:birdquest/app/providers.dart';
import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/models.dart';
import 'package:birdquest/data/repositories/sighting_repository.dart';
import 'package:birdquest/features/collection/collection_screen.dart';
import 'package:birdquest/features/scanner/scanner_screen.dart';
import 'package:birdquest/services/bird_recognition/model_manager.dart';
import 'package:birdquest/shared/theme/app_theme.dart';
import 'package:birdquest/shared/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Directory root;
  late AppPaths paths;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = memoryDatabase();
    root = Directory.systemTemp.createTempSync('birdquest_widget_');
    paths = AppPaths(
      mediaRoot: Directory('${root.path}/media')..createSync(),
      modelsDir: Directory('${root.path}/models')..createSync(),
      tempDir: Directory('${root.path}/tmp')..createSync(),
    );
  });

  tearDown(() async {
    await db.close();
    root.deleteSync(recursive: true);
  });

  Widget app(Widget child, {List overrides = const []}) => ProviderScope(
    overrides: [
      appPathsProvider.overrideWithValue(paths),
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      modelStatusProvider.overrideWith(
        (ref) => Stream.value(const ModelNotInstalled()),
      ),
      ...overrides,
    ],
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );

  testWidgets('collection shows stats and per-species encounter counts', (
    tester,
  ) async {
    final media = (await tester.runAsync(tempMediaStore))!;
    final sightings = SightingRepository(db, media);
    await tester.runAsync(() async {
      for (final day in [1, 2]) {
        await sightings.saveEncounter(
          EncounterDraft(
            species: kingfisher,
            confirmedAt: DateTime(2026, 5, day),
          ),
        );
      }
      await sightings.saveEncounter(
        EncounterDraft(species: robin, confirmedAt: DateTime(2026, 5, 3)),
      );
    });

    await tester.pumpWidget(app(const CollectionScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Common Kingfisher'), findsOneWidget);
    expect(find.text('Discovered 2 times'), findsOneWidget);
    expect(find.text('Discovered 1 time'), findsOneWidget);
    expect(find.text('Encounters'), findsOneWidget);
    expect(find.text('3'), findsOneWidget, reason: 'total encounters');
    expect(find.text('Placeholder'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    // Let drift cancel its stream-query timers.
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => media.root.delete(recursive: true));
  });

  testWidgets('empty collection explains how to add birds', (tester) async {
    await tester.pumpWidget(app(const CollectionScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your field journal is empty'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Let drift cancel its stream-query timers.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('scanner offers the model download and labels demo mode', (
    tester,
  ) async {
    // A typical phone viewport (411 x 914 dp).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const ScannerScreen()));
    await tester.pump();
    expect(find.text('One-time setup: bird sound model'), findsOneWidget);
    expect(find.textContaining('DEMO MODE'), findsNothing);

    await tester.ensureVisible(find.text('Try demo mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try demo mode'));
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
    expect(find.text('One-time setup: bird sound model'), findsNothing);
    expect(find.text('No birds heard yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Let drift cancel its stream-query timers.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'theme follows the phone by default; toggle cycles and persists',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        app(
          Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(56),
                  child: Row(children: [ThemeToggleButton()]),
                ),
              );
            },
          ),
        ),
      );
      expect(capturedRef.read(themeModeProvider), ThemeMode.system);
      expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();
      expect(capturedRef.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();
      expect(capturedRef.read(themeModeProvider), ThemeMode.dark);

      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();
      expect(capturedRef.read(themeModeProvider), ThemeMode.system);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('dark theme swaps in the night illustration', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPathsProvider.overrideWithValue(paths),
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const CollectionScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      'assets/illustrations/empty_collection_dark.png',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
