import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../data/models.dart';

enum ExportFormat {
  /// Every field, for spreadsheets and backups.
  csv('csv', 'text/csv'),

  /// Waypoints for sightings with GPS, for maps and GIS apps.
  gpx('gpx', 'application/gpx+xml'),

  /// eBird Record Format (no header), for eBird's checklist import.
  ebird('csv', 'text/csv');

  const ExportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

/// One CSV field, quoted when it contains a comma, quote or line break.
String csvField(Object? value) {
  final s = value?.toString() ?? '';
  if (s.contains(RegExp('[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}

String _csvRow(List<Object?> fields) => fields.map(csvField).join(',');

String xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// Full CSV with a header. [russianNames] maps scientific to Russian names.
/// With [withLocation] false the coordinates are left out.
String buildCsv(
  List<ExportRow> rows, {
  Map<String, String> russianNames = const {},
  bool withLocation = true,
}) {
  final out = StringBuffer()
    ..writeln(
      _csvRow([
        'date_time',
        'scientific_name',
        'english_name',
        'russian_name',
        if (withLocation) ...['latitude', 'longitude'],
        'rarity',
        'model_score',
        'photos',
        'notes',
      ]),
    );
  for (final r in rows) {
    out.writeln(
      _csvRow([
        r.confirmedAt.toLocal().toIso8601String(),
        r.scientificName,
        r.commonName,
        russianNames[r.scientificName],
        if (withLocation) ...[
          r.latitude?.toStringAsFixed(6),
          r.longitude?.toStringAsFixed(6),
        ],
        r.rarity,
        r.modelScore?.toStringAsFixed(2),
        r.photoCount,
        r.notes,
      ]),
    );
  }
  return out.toString();
}

/// GPX 1.1 with one waypoint per sighting that has coordinates.
String buildGpx(List<ExportRow> rows, {DateTime? now}) {
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="BirdQuest" '
      'xmlns="http://www.topografix.com/GPX/1/1">',
    )
    ..writeln(
      '  <metadata><name>BirdQuest sightings</name>'
      '<time>${(now ?? DateTime.now()).toUtc().toIso8601String()}</time>'
      '</metadata>',
    );
  for (final r in rows.where((r) => r.hasLocation)) {
    final desc = [
      r.scientificName,
      if (r.rarity != null) r.rarity!,
      if (r.notes != null && r.notes!.isNotEmpty) r.notes!,
    ].join(' · ');
    out
      ..writeln(
        '  <wpt lat="${r.latitude!.toStringAsFixed(6)}" '
        'lon="${r.longitude!.toStringAsFixed(6)}">',
      )
      ..writeln('    <time>${r.confirmedAt.toUtc().toIso8601String()}</time>')
      ..writeln('    <name>${xmlEscape(r.commonName)}</name>')
      ..writeln('    <desc>${xmlEscape(desc)}</desc>')
      ..writeln('    <sym>Bird</sym>')
      ..writeln('  </wpt>');
  }
  out.writeln('</gpx>');
  return out.toString();
}

/// eBird Record Format (19 columns, no header): each sighting is an
/// incidental observation of one bird, with BirdQuest noted as the method.
String buildEbird(List<ExportRow> rows, {bool withLocation = true}) {
  final date = DateFormat('MM/dd/yyyy');
  final time = DateFormat('HH:mm');
  final out = StringBuffer();
  for (final r in rows) {
    final parts = r.scientificName.split(' ');
    final local = r.confirmedAt.toLocal();
    final hasLoc = withLocation && r.hasLocation;
    out.writeln(
      _csvRow([
        r.commonName,
        parts.first,
        parts.length > 1 ? parts.sublist(1).join(' ') : '',
        1,
        [
          'Identified by sound with BirdQuest (BirdNET+)'
              '${r.modelScore == null ? '' : ', score ${r.modelScore!.toStringAsFixed(2)}'}',
          if (r.notes != null && r.notes!.isNotEmpty) r.notes!,
        ].join('. '),
        hasLoc
            ? 'BirdQuest ${r.latitude!.toStringAsFixed(4)}, '
                  '${r.longitude!.toStringAsFixed(4)}'
            : 'BirdQuest (no location)',
        hasLoc ? r.latitude!.toStringAsFixed(6) : '',
        hasLoc ? r.longitude!.toStringAsFixed(6) : '',
        date.format(local),
        time.format(local),
        '', // state/province
        '', // country code
        'Incidental',
        1, // observers
        '', // duration
        'N', // all observations reported?
        '', // distance
        '', // area
        'Exported from BirdQuest',
      ]),
    );
  }
  return out.toString();
}

/// Writes the export to [dir] and returns the file.
Future<File> writeExport(
  Directory dir,
  ExportFormat format,
  String content, {
  DateTime? now,
}) async {
  await dir.create(recursive: true);
  final stamp = DateFormat('yyyyMMdd_HHmm').format(now ?? DateTime.now());
  final suffix = format == ExportFormat.ebird ? '_ebird' : '';
  final file = File(
    p.join(dir.path, 'birdquest_$stamp$suffix.${format.extension}'),
  );
  // A BOM helps spreadsheet apps read UTF-8 (Cyrillic names) correctly.
  final bom = format == ExportFormat.csv ? '﻿' : '';
  await file.writeAsString('$bom$content', flush: true);
  return file;
}
