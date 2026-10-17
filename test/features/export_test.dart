import 'dart:io';

import 'package:birdquest/data/models.dart';
import 'package:birdquest/features/export/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _rows = [
  ExportRow(
    confirmedAt: DateTime(2026, 10, 17, 6, 5),
    scientificName: 'Turdus merula',
    commonName: 'Common Blackbird',
    latitude: 52.520008,
    longitude: 13.404954,
    rarity: 'common',
    modelScore: 0.91,
    notes: 'Sang "tsik", then flew, low',
    photoCount: 2,
  ),
  ExportRow(
    confirmedAt: DateTime(2026, 10, 17, 18, 30),
    scientificName: 'Strix aluco',
    commonName: 'Tawny <Owl> & co',
    notes: 'line one\nline two',
  ),
];

void main() {
  test('CSV quotes commas, quotes and line breaks; keeps Cyrillic', () {
    final csv = buildCsv(
      _rows,
      russianNames: const {'Turdus merula': 'Чёрный дрозд'},
    );
    final lines = csv.trimRight().split('\n');
    expect(lines.first, startsWith('date_time,scientific_name,english_name'));
    expect(lines[1], contains('Чёрный дрозд'));
    expect(lines[1], contains('52.520008,13.404954'));
    expect(lines[1], contains('"Sang ""tsik"", then flew, low"'));
    expect(csv, contains('"line one\nline two"'));
  });

  test('CSV without coordinates drops the columns', () {
    final csv = buildCsv(_rows, withLocation: false);
    expect(csv, isNot(contains('latitude')));
    expect(csv, isNot(contains('52.52')));
  });

  test('GPX escapes XML and skips sightings without GPS', () {
    final gpx = buildGpx(_rows, now: DateTime.utc(2026, 10, 17));
    expect(gpx, contains('<wpt lat="52.520008" lon="13.404954">'));
    expect('<wpt'.allMatches(gpx), hasLength(1));
    expect(gpx, contains('<name>Common Blackbird</name>'));
    expect(gpx, isNot(contains('Tawny <Owl>')));
    expect(
      buildGpx([
        ExportRow(
          confirmedAt: DateTime(2026),
          scientificName: 'X y',
          commonName: 'A & <B>',
          latitude: 1,
          longitude: 2,
        ),
      ]),
      contains('<name>A &amp; &lt;B&gt;</name>'),
    );
  });

  test('eBird record format: 19 columns, genus/species split, MM/dd/yyyy', () {
    final ebird = buildEbird(_rows);
    final first = ebird.split('\n').first;
    expect(first, startsWith('Common Blackbird,Turdus,merula,1,'));
    expect(first, contains('10/17/2026,06:05'));
    expect(first, contains(',Incidental,1,,N,,,Exported from BirdQuest'));
    expect(first, contains('score 0.91'));
    // 19 fields once quoted commas are ignored.
    final unquoted = first.replaceAll(RegExp(r'"[^"]*(""[^"]*)*"'), 'Q');
    expect(unquoted.split(','), hasLength(19));
    expect(ebird, contains('BirdQuest (no location)'));
  });

  test('files get a timestamped name and CSV a UTF-8 BOM', () async {
    final dir = Directory.systemTemp.createTempSync('birdquest_export_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final now = DateTime(2026, 10, 17, 9, 41);
    final csv = await writeExport(dir, ExportFormat.csv, 'a,b', now: now);
    expect(csv.path, endsWith('birdquest_20261017_0941.csv'));
    expect(csv.readAsBytesSync().take(3), [0xEF, 0xBB, 0xBF]);
    final ebird = await writeExport(dir, ExportFormat.ebird, 'x', now: now);
    expect(ebird.path, endsWith('_ebird.csv'));
    final gpx = await writeExport(dir, ExportFormat.gpx, '<gpx/>', now: now);
    expect(gpx.readAsStringSync(), '<gpx/>');
  });
}
