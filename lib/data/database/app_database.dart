import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Species,
    Sessions,
    Detections,
    Sightings,
    SightingPhotos,
    GuideDescriptions,
    EncyclopediaPacks,
    EncyclopediaPackSpecies,
    QuestCompletions,
    QuizAnswers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'birdquest'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: species guide description cache and Encyclopedia packs.
        await m.createTable(guideDescriptions);
        await m.createTable(encyclopediaPacks);
        await m.createTable(encyclopediaPackSpecies);
      }
      if (from < 3) {
        // v3: species rarity per sighting and completed daily quests.
        await m.addColumn(sightings, sightings.rarity);
        await m.createTable(questCompletions);
      }
      if (from < 4) {
        // v4: reference voices in Encyclopedia areas, and quiz answers.
        // From v1 the packs table was just created in its current shape.
        if (from >= 2) {
          await m.addColumn(encyclopediaPacks, encyclopediaPacks.withVoices);
        }
        await m.createTable(quizAnswers);
      }
    },
    beforeOpen: (details) async {
      // SQLite leaves FK enforcement off by default; cascades depend on it.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sightings_species '
      'ON sightings (species_id, confirmed_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_photos_sighting '
      'ON sighting_photos (sighting_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_detections_session '
      'ON detections (session_id, species_id)',
    );
  }
}
