import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../media_store.dart';
import '../models.dart';

/// Writes sessions, detections and confirmed sightings, and reads a species'
/// encounter history.
class SightingRepository {
  SightingRepository(this._db, this._media);

  final AppDatabase _db;
  final MediaStore _media;

  /// Returns the id of the species row for [info], creating it if needed.
  Future<int> upsertSpecies(SpeciesInfo info) async {
    final existing =
        await (_db.select(_db.species)
              ..where((s) => s.scientificName.equals(info.scientificName)))
            .getSingleOrNull();
    if (existing != null) {
      // Fill in metadata that may not have been known at first insert.
      if (existing.taxonOrder == null && info.taxonOrder != null ||
          existing.modelLabelId == null && info.modelLabelId != null ||
          existing.description == null && info.description != null) {
        await (_db.update(
          _db.species,
        )..where((s) => s.id.equals(existing.id))).write(
          SpeciesCompanion(
            taxonOrder: Value(existing.taxonOrder ?? info.taxonOrder),
            modelLabelId: Value(existing.modelLabelId ?? info.modelLabelId),
            description: Value(existing.description ?? info.description),
          ),
        );
      }
      return existing.id;
    }
    return _db
        .into(_db.species)
        .insert(
          SpeciesCompanion.insert(
            scientificName: info.scientificName,
            commonName: info.commonName,
            taxonOrder: Value(info.taxonOrder),
            modelLabelId: Value(info.modelLabelId),
            description: Value(info.description),
          ),
        );
  }

  Future<int> startSession({
    required DateTime startedAt,
    bool isDemo = false,
  }) => _db
      .into(_db.sessions)
      .insert(
        SessionsCompanion.insert(startedAt: startedAt, isDemo: Value(isDemo)),
      );

  Future<void> endSession(int sessionId, DateTime endedAt) =>
      (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(endedAt: Value(endedAt)),
      );

  /// Logs raw model predictions. These never affect collection counts.
  Future<void> recordDetections(
    int sessionId,
    List<({SpeciesInfo species, DateTime at, double score})> items,
  ) async {
    if (items.isEmpty) return;
    await _db.transaction(() async {
      for (final item in items) {
        final speciesId = await upsertSpecies(item.species);
        await _db
            .into(_db.detections)
            .insert(
              DetectionsCompanion.insert(
                sessionId: sessionId,
                speciesId: speciesId,
                detectedAt: item.at,
                modelScore: item.score,
              ),
            );
      }
    });
  }

  /// Saves one confirmed encounter and copies its media into app storage.
  /// Returns the new sighting id.
  Future<int> saveEncounter(EncounterDraft draft) async {
    final sightingId = await _db.transaction(() async {
      final speciesId = await upsertSpecies(draft.species);
      return _db
          .into(_db.sightings)
          .insert(
            SightingsCompanion.insert(
              speciesId: speciesId,
              sessionId: Value(draft.sessionId),
              confirmedAt: draft.confirmedAt,
              latitude: Value(draft.latitude),
              longitude: Value(draft.longitude),
              userNotes: Value(draft.notes),
              modelScore: Value(draft.modelScore),
              isDemo: Value(draft.isDemo),
            ),
          );
    });

    try {
      if (draft.clipPath != null) {
        final clip = await _media.importClip(draft.clipPath!, sightingId);
        await (_db.update(_db.sightings)..where((s) => s.id.equals(sightingId)))
            .write(SightingsCompanion(audioClipPath: Value(clip)));
      }
      for (final photo in draft.photoPaths) {
        await addPhoto(sightingId, photo);
      }
    } catch (_) {
      // Never leave a half-saved encounter behind.
      await deleteSighting(sightingId);
      rethrow;
    }
    return sightingId;
  }

  /// Copies [sourcePath] into storage and attaches it to [sightingId].
  Future<int> addPhoto(int sightingId, String sourcePath) async {
    final relative = await _media.importPhoto(sourcePath, sightingId);
    return _db
        .into(_db.sightingPhotos)
        .insert(
          SightingPhotosCompanion.insert(
            sightingId: sightingId,
            localFilePath: relative,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> deletePhoto(int photoId) async {
    final row = await (_db.select(
      _db.sightingPhotos,
    )..where((p) => p.id.equals(photoId))).getSingleOrNull();
    if (row == null) return;
    await (_db.delete(
      _db.sightingPhotos,
    )..where((p) => p.id.equals(photoId))).go();
    await _media.deleteFile(row.localFilePath);
  }

  /// Deletes a sighting, its photo rows (FK cascade) and its media files.
  /// Collection counts update automatically because they are derived.
  Future<void> deleteSighting(int sightingId) async {
    await (_db.delete(
      _db.sightings,
    )..where((s) => s.id.equals(sightingId))).go();
    await _media.deleteSightingMedia(sightingId);
  }

  Future<void> updateNotes(int sightingId, String? notes) =>
      (_db.update(_db.sightings)..where((s) => s.id.equals(sightingId))).write(
        SightingsCompanion(userNotes: Value(notes)),
      );

  /// Encounters of one species, newest first, each with its photos.
  Stream<List<Encounter>> watchEncounters(int speciesId) {
    final query =
        _db.select(_db.sightings).join([
            leftOuterJoin(
              _db.sightingPhotos,
              _db.sightingPhotos.sightingId.equalsExp(_db.sightings.id),
            ),
          ])
          ..where(_db.sightings.speciesId.equals(speciesId))
          ..orderBy([
            OrderingTerm.desc(_db.sightings.confirmedAt),
            OrderingTerm.desc(_db.sightings.id),
            OrderingTerm.asc(_db.sightingPhotos.createdAt),
          ]);
    return query.watch().map(_groupEncounters);
  }

  Stream<Encounter?> watchEncounter(int sightingId) {
    final query = _db.select(_db.sightings).join([
      leftOuterJoin(
        _db.sightingPhotos,
        _db.sightingPhotos.sightingId.equalsExp(_db.sightings.id),
      ),
    ])..where(_db.sightings.id.equals(sightingId));
    return query.watch().map((rows) {
      final list = _groupEncounters(rows);
      return list.isEmpty ? null : list.first;
    });
  }

  List<Encounter> _groupEncounters(List<TypedResult> rows) {
    final order = <int>[];
    final sightings = <int, SightingRow>{};
    final photos = <int, List<SightingPhoto>>{};
    for (final row in rows) {
      final s = row.readTable(_db.sightings);
      if (!sightings.containsKey(s.id)) {
        order.add(s.id);
        sightings[s.id] = s;
        photos[s.id] = [];
      }
      final p = row.readTableOrNull(_db.sightingPhotos);
      if (p != null) {
        photos[s.id]!.add(
          SightingPhoto(
            id: p.id,
            path: p.localFilePath,
            createdAt: p.createdAt,
          ),
        );
      }
    }
    return [
      for (final id in order)
        Encounter(
          id: id,
          speciesId: sightings[id]!.speciesId,
          sessionId: sightings[id]!.sessionId,
          confirmedAt: sightings[id]!.confirmedAt,
          modelScore: sightings[id]!.modelScore,
          clipPath: sightings[id]!.audioClipPath,
          latitude: sightings[id]!.latitude,
          longitude: sightings[id]!.longitude,
          notes: sightings[id]!.userNotes,
          isDemo: sightings[id]!.isDemo,
          photos: photos[id]!,
        ),
    ];
  }

  /// Removes every encounter and session recorded in demo mode.
  Future<void> deleteDemoData() async {
    final demoSightings = await (_db.select(
      _db.sightings,
    )..where((s) => s.isDemo.equals(true))).get();
    for (final s in demoSightings) {
      await deleteSighting(s.id);
    }
    await (_db.delete(_db.sessions)..where((s) => s.isDemo.equals(true))).go();
  }
}
