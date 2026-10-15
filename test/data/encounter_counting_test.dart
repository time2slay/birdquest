import 'dart:io';

import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/media_store.dart';
import 'package:birdquest/data/models.dart';
import 'package:birdquest/data/repositories/collection_repository.dart';
import 'package:birdquest/data/repositories/sighting_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late MediaStore media;
  late SightingRepository sightings;
  late CollectionRepository collection;
  late Directory scratch;

  setUp(() async {
    db = memoryDatabase();
    media = await tempMediaStore();
    sightings = SightingRepository(db, media);
    collection = CollectionRepository(db);
    scratch = await Directory.systemTemp.createTemp('birdquest_scratch_');
  });

  tearDown(() async {
    await db.close();
    await media.root.delete(recursive: true);
    await scratch.delete(recursive: true);
  });

  Future<CollectionEntry?> entryFor(SpeciesInfo s) async {
    final all = await collection.watchCollection().first;
    return all.where((e) => e.scientificName == s.scientificName).firstOrNull;
  }

  test('detections alone never add a species to the collection', () async {
    final session = await sightings.startSession(
      startedAt: DateTime(2026, 5, 1),
    );
    await sightings.recordDetections(session, [
      for (var i = 0; i < 10; i++)
        (species: kingfisher, at: DateTime(2026, 5, 1, 8, 0, i), score: 0.8),
    ]);

    expect(await collection.watchCollection().first, isEmpty);
    final stats = await collection.watchStats().first;
    expect(stats.uniqueSpecies, 0);
    expect(stats.encounters, 0);
  });

  test('10 detections + 1 confirmation = 1 encounter; next day = 2', () async {
    final day1 = await sightings.startSession(startedAt: DateTime(2026, 5, 1));
    await sightings.recordDetections(day1, [
      for (var i = 0; i < 10; i++)
        (species: kingfisher, at: DateTime(2026, 5, 1, 8, 0, i), score: 0.8),
    ]);
    await sightings.saveEncounter(
      EncounterDraft(
        species: kingfisher,
        confirmedAt: DateTime(2026, 5, 1, 8, 5),
        sessionId: day1,
        modelScore: 0.91,
      ),
    );
    expect((await entryFor(kingfisher))!.encounterCount, 1);

    final day2 = await sightings.startSession(startedAt: DateTime(2026, 5, 2));
    await sightings.saveEncounter(
      EncounterDraft(
        species: kingfisher,
        confirmedAt: DateTime(2026, 5, 2, 7, 30),
        sessionId: day2,
      ),
    );

    final entry = (await entryFor(kingfisher))!;
    expect(entry.encounterCount, 2);
    expect(entry.firstSeen, DateTime(2026, 5, 1, 8, 5));
    expect(entry.lastSeen, DateTime(2026, 5, 2, 7, 30));
    final stats = await collection.watchStats().first;
    expect(stats.uniqueSpecies, 1);
    expect(stats.encounters, 2);
  });

  test('deleting an encounter updates counts; deleting the last removes '
      'the species from the collection', () async {
    final a = await sightings.saveEncounter(
      EncounterDraft(species: kingfisher, confirmedAt: DateTime(2026, 5, 1)),
    );
    final b = await sightings.saveEncounter(
      EncounterDraft(species: kingfisher, confirmedAt: DateTime(2026, 5, 2)),
    );
    await sightings.saveEncounter(
      EncounterDraft(species: robin, confirmedAt: DateTime(2026, 5, 2)),
    );

    await sightings.deleteSighting(b);
    expect((await entryFor(kingfisher))!.encounterCount, 1);
    expect((await entryFor(kingfisher))!.lastSeen, DateTime(2026, 5, 1));

    await sightings.deleteSighting(a);
    expect(await entryFor(kingfisher), isNull);
    final stats = await collection.watchStats().first;
    expect(stats.uniqueSpecies, 1);
    expect(stats.encounters, 1);
  });

  test('photos are copied into app storage, counted, and removed with the '
      'encounter', () async {
    final p1 = await fakePhoto(scratch, 'a.jpg');
    final p2 = await fakePhoto(scratch, 'b.jpg');
    final id = await sightings.saveEncounter(
      EncounterDraft(
        species: robin,
        confirmedAt: DateTime(2026, 6, 1),
        photoPaths: [p1, p2],
      ),
    );

    final encounter = (await sightings.watchEncounter(id).first)!;
    expect(encounter.photos, hasLength(2));
    for (final photo in encounter.photos) {
      expect(photo.path, isNot(startsWith(scratch.path)));
      expect(media.file(photo.path).existsSync(), isTrue);
    }
    expect((await entryFor(robin))!.photoCount, 2);
    expect((await collection.watchStats().first).photos, 2);

    await sightings.deleteSighting(id);
    for (final photo in encounter.photos) {
      expect(media.file(photo.path).existsSync(), isFalse);
    }
    final remaining = await db.select(db.sightingPhotos).get();
    expect(remaining, isEmpty, reason: 'FK cascade removes photo rows');
    expect((await collection.watchStats().first).photos, 0);
  });

  test(
    'photo count with several encounters is not multiplied by joins',
    () async {
      await sightings.saveEncounter(
        EncounterDraft(
          species: robin,
          confirmedAt: DateTime(2026, 6, 1),
          photoPaths: [
            await fakePhoto(scratch, '1.jpg'),
            await fakePhoto(scratch, '2.jpg'),
          ],
        ),
      );
      await sightings.saveEncounter(
        EncounterDraft(
          species: robin,
          confirmedAt: DateTime(2026, 6, 2),
          photoPaths: [await fakePhoto(scratch, '3.jpg')],
        ),
      );
      await sightings.saveEncounter(
        EncounterDraft(species: robin, confirmedAt: DateTime(2026, 6, 3)),
      );
      final entry = (await entryFor(robin))!;
      expect(entry.encounterCount, 3);
      expect(entry.photoCount, 3);
    },
  );

  test(
    'cover photo falls back to default when that photo is deleted',
    () async {
      final id = await sightings.saveEncounter(
        EncounterDraft(
          species: robin,
          confirmedAt: DateTime(2026, 6, 1),
          photoPaths: [await fakePhoto(scratch)],
        ),
      );
      final photo = (await sightings.watchEncounter(id).first)!.photos.single;
      final entry = (await entryFor(robin))!;

      await collection.setCoverPhoto(entry.speciesId, photo.id);
      expect((await entryFor(robin))!.coverPhotoPath, photo.path);

      await sightings.deletePhoto(photo.id);
      expect((await entryFor(robin))!.coverPhotoPath, isNull);
    },
  );

  test('saved clip is stored relative to the media root', () async {
    final clip = File('${scratch.path}/clip.wav')..writeAsBytesSync([1, 2, 3]);
    final id = await sightings.saveEncounter(
      EncounterDraft(
        species: robin,
        confirmedAt: DateTime(2026, 6, 1),
        clipPath: clip.path,
      ),
    );
    final e = (await sightings.watchEncounter(id).first)!;
    expect(e.clipPath, isNotNull);
    expect(media.file(e.clipPath!).readAsBytesSync(), [1, 2, 3]);
  });

  test('demo encounters are flagged and can be removed in bulk', () async {
    await sightings.saveEncounter(
      EncounterDraft(
        species: robin,
        confirmedAt: DateTime(2026, 6, 1),
        isDemo: true,
      ),
    );
    await sightings.saveEncounter(
      EncounterDraft(species: kingfisher, confirmedAt: DateTime(2026, 6, 1)),
    );
    expect((await entryFor(robin))!.allDemo, isTrue);
    expect((await entryFor(kingfisher))!.allDemo, isFalse);

    await sightings.deleteDemoData();
    expect(await entryFor(robin), isNull);
    expect(await entryFor(kingfisher), isNotNull);
  });

  test('species rows are reused and enriched, never duplicated', () async {
    await sightings.upsertSpecies(
      const SpeciesInfo(
        scientificName: 'Alcedo atthis',
        commonName: 'Common Kingfisher',
      ),
    );
    await sightings.upsertSpecies(kingfisher);
    final rows = await db.select(db.species).get();
    expect(rows, hasLength(1));
    expect(rows.single.taxonOrder, 'Coraciiformes');
  });
}
