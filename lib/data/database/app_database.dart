import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Species, Sessions, Detections, Sightings, SightingPhotos],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'birdquest'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Add stepwise migrations here as the schema evolves, e.g.
      // if (from < 2) await m.addColumn(sightings, sightings.weather);
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
