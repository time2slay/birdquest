import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models.dart';

/// Read model for the collection. Every count here is computed from saved
/// sightings at query time, never stored, so deleting a mistaken encounter
/// immediately corrects the totals.
class CollectionRepository {
  CollectionRepository(this._db);

  final AppDatabase _db;

  static const _collectionSql = '''
SELECT
  sp.id AS species_id,
  sp.scientific_name,
  sp.common_name,
  sp.reference_image,
  sp.taxon_order,
  sp.description,
  (SELECT local_file_path FROM sighting_photos WHERE id = sp.cover_photo_id)
    AS cover_path,
  COUNT(DISTINCT si.id) AS encounters,
  COUNT(ph.id) AS photos,
  MIN(si.confirmed_at) AS first_seen,
  MAX(si.confirmed_at) AS last_seen,
  MIN(si.is_demo) AS all_demo
FROM species sp
JOIN sightings si ON si.species_id = sp.id
LEFT JOIN sighting_photos ph ON ph.sighting_id = si.id
''';

  Stream<List<CollectionEntry>> watchCollection() {
    return _db
        .customSelect(
          '$_collectionSql GROUP BY sp.id ORDER BY last_seen DESC',
          readsFrom: {_db.species, _db.sightings, _db.sightingPhotos},
        )
        .watch()
        .map((rows) => rows.map(_mapEntry).toList());
  }

  /// The aggregated entry for one species, or null once it has no sightings.
  Stream<CollectionEntry?> watchEntry(int speciesId) {
    return _db
        .customSelect(
          '$_collectionSql WHERE sp.id = ? GROUP BY sp.id',
          variables: [Variable.withInt(speciesId)],
          readsFrom: {_db.species, _db.sightings, _db.sightingPhotos},
        )
        .watch()
        .map((rows) => rows.isEmpty ? null : _mapEntry(rows.first));
  }

  Stream<CollectionStats> watchStats() {
    return _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(DISTINCT species_id) FROM sightings) AS species, '
          '(SELECT COUNT(*) FROM sightings) AS encounters, '
          '(SELECT COUNT(*) FROM sighting_photos) AS photos',
          readsFrom: {_db.sightings, _db.sightingPhotos},
        )
        .watch()
        .map((rows) {
          final r = rows.single;
          return CollectionStats(
            uniqueSpecies: r.read<int>('species'),
            encounters: r.read<int>('encounters'),
            photos: r.read<int>('photos'),
          );
        });
  }

  /// Uses one of the user's photos as the collection cover; null restores
  /// the default reference image.
  Future<void> setCoverPhoto(int speciesId, int? photoId) =>
      (_db.update(_db.species)..where((s) => s.id.equals(speciesId))).write(
        SpeciesCompanion(coverPhotoId: Value(photoId)),
      );

  CollectionEntry _mapEntry(QueryRow r) => CollectionEntry(
    speciesId: r.read<int>('species_id'),
    scientificName: r.read<String>('scientific_name'),
    commonName: r.read<String>('common_name'),
    referenceImage: r.readNullable<String>('reference_image'),
    taxonOrder: r.readNullable<String>('taxon_order'),
    description: r.readNullable<String>('description'),
    coverPhotoPath: r.readNullable<String>('cover_path'),
    encounterCount: r.read<int>('encounters'),
    photoCount: r.read<int>('photos'),
    firstSeen: r.read<DateTime>('first_seen'),
    lastSeen: r.read<DateTime>('last_seen'),
    allDemo: r.read<int>('all_demo') == 1,
  );
}
