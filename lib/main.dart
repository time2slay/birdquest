import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // en + ru date formats
  final paths = await AppPaths.resolve();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BirdQuestApp(),
    ),
  );
}
