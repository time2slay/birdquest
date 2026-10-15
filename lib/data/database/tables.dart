import 'package:drift/drift.dart';

/// One unique type of bird. Rows are created lazily the first time a species
/// is detected or saved; the collection only shows species that have at least
/// one confirmed sighting.
@DataClassName('SpeciesRow')
class Species extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scientificName => text().unique()();
  TextColumn get commonName => text()();
  TextColumn get description => text().nullable()();

  /// Asset path or URL of a licensed reference image. Null means the UI shows
  /// a labeled placeholder illustration.
  TextColumn get referenceImage => text().nullable()();

  /// Taxonomic order, e.g. "Passeriformes".
  TextColumn get taxonOrder => text().nullable()();

  /// Stable species id from the recognition model's label file.
  TextColumn get modelLabelId => text().nullable()();

  /// User-chosen cover photo for the collection card.
  IntColumn get coverPhotoId => integer().nullable().references(
    SightingPhotos,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

/// One listening session on the scanner screen.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  /// True when the session ran on the simulated demo recognizer.
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();
}

/// One AI prediction for one audio window. Many detections may back a single
/// sighting; detections never count towards the collection on their own.
@DataClassName('DetectionRow')
class Detections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get speciesId =>
      integer().references(Species, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get detectedAt => dateTime()();
  RealColumn get modelScore => real()();
  TextColumn get audioClipPath => text().nullable()();
}

/// A user-confirmed encounter. Collection counts are derived from these rows.
@DataClassName('SightingRow')
class Sightings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get speciesId =>
      integer().references(Species, #id, onDelete: KeyAction.cascade)();
  IntColumn get sessionId => integer().nullable().references(
    Sessions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get confirmedAt => dateTime()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get userNotes => text().nullable()();

  /// Best model score among the detections the user confirmed.
  RealColumn get modelScore => real().nullable()();

  /// Path (relative to the app media root) of the saved sound clip.
  TextColumn get audioClipPath => text().nullable()();
  BoolColumn get isDemo => boolean().withDefault(const Constant(false))();
}

/// A user photograph attached to a sighting. Only the file reference is
/// stored; the image itself lives in app-managed storage.
@DataClassName('SightingPhotoRow')
class SightingPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sightingId =>
      integer().references(Sightings, #id, onDelete: KeyAction.cascade)();

  /// Path relative to the app media root.
  TextColumn get localFilePath => text()();
  DateTimeColumn get createdAt => dateTime()();
}
