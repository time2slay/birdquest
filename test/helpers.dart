import 'dart:io';

import 'package:birdquest/data/database/app_database.dart';
import 'package:birdquest/data/media_store.dart';
import 'package:birdquest/data/models.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

AppDatabase memoryDatabase() {
  // Several isolates/tests may open in-memory databases at once.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<MediaStore> tempMediaStore() async =>
    MediaStore(await Directory.systemTemp.createTemp('birdquest_media_'));

/// Creates a small file standing in for a camera capture.
Future<String> fakePhoto(Directory dir, [String name = 'shot.jpg']) async {
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(List.filled(16, 7));
  return f.path;
}

const kingfisher = SpeciesInfo(
  scientificName: 'Alcedo atthis',
  commonName: 'Common Kingfisher',
  taxonOrder: 'Coraciiformes',
);

const blackbird = SpeciesInfo(
  scientificName: 'Turdus merula',
  commonName: 'Common Blackbird',
);

const robin = SpeciesInfo(
  scientificName: 'Erithacus rubecula',
  commonName: 'European Robin',
  taxonOrder: 'Passeriformes',
);
