import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'labels.dart';

/// BirdNET week number (1–48): four "weeks" per month, as the geo model
/// expects. Days 29–31 belong to week 4 of their month.
int birdnetWeek(DateTime date) {
  final weekOfMonth = ((date.day - 1) ~/ 7 + 1).clamp(1, 4);
  return (date.month - 1) * 4 + weekOfMonth;
}

/// Parses the geo model's tab-separated labels (`id<TAB>sci<TAB>common`) into
/// scientific names, in output order.
List<String> parseGeoLabels(String text) => [
  for (final line in text.replaceFirst('﻿', '').split(RegExp(r'\r?\n')))
    if (line.trim().isNotEmpty) line.split('\t')[1],
];

/// Location and week the filter was computed for.
class GeoContext {
  const GeoContext({
    required this.latitude,
    required this.longitude,
    required this.week,
  });

  final double latitude;
  final double longitude;
  final int week;

  /// Cache key: ~1° cells are far finer than the model's resolution.
  String get cacheKey => '${latitude.round()}:${longitude.round()}:$week';
}

/// The set of audio-model species plausible at one place and week.
class SpeciesRange {
  SpeciesRange._(this.context, this._blocked, this.plausible);

  final GeoContext context;

  /// Scientific names of audio-model birds the geo model rules out.
  final Set<String> _blocked;

  /// Audio-model birds the geo model considers plausible here.
  final Set<String> plausible;

  int get plausibleCount => plausible.length;

  /// Species the geo model does not know are always allowed, so the filter
  /// can only remove out-of-range predictions, never hide unknown birds.
  bool allows(String scientificName) => !_blocked.contains(scientificName);

  /// Builds a range from raw geo-model [probabilities].
  factory SpeciesRange.fromScores({
    required GeoContext context,
    required List<double> probabilities,
    required List<String> geoLabels,
    required List<ModelLabel> audioLabels,
    double threshold = 0.03,
  }) {
    if (probabilities.length != geoLabels.length) {
      throw ArgumentError(
        'Geo model returned ${probabilities.length} scores for '
        '${geoLabels.length} labels',
      );
    }
    final score = <String, double>{
      for (var i = 0; i < geoLabels.length; i++) geoLabels[i]: probabilities[i],
    };
    final blocked = <String>{};
    final plausible = <String>{};
    for (final label in audioLabels) {
      if (!label.isBird) continue;
      final p = score[label.scientificName];
      if (p == null || p.isNaN) continue;
      if (p >= threshold) {
        plausible.add(label.scientificName);
      } else {
        blocked.add(label.scientificName);
      }
    }
    return SpeciesRange._(context, blocked, plausible);
  }
}

/// Runs the BirdNET+ geo model (Apache-2.0) to compute [SpeciesRange]s.
class GeoFilter {
  static const _inputName = 'input';
  static const _outputName = 'probabilities';

  final _ort = OnnxRuntime();
  OrtSession? _session;
  List<String>? _labels;
  final _cache = <String, SpeciesRange>{};

  bool get isLoaded => _session != null;

  Future<void> load(String modelPath, String labelsText) async {
    await close();
    _labels = parseGeoLabels(labelsText);
    _session = await _ort.createSession(
      modelPath,
      options: OrtSessionOptions(
        sessionConfigs: const {'mlas.disable_kleidiai': '1'},
      ),
    );
  }

  Future<SpeciesRange> rangeFor(
    GeoContext context,
    List<ModelLabel> audioLabels,
  ) async {
    final cached = _cache[context.cacheKey];
    if (cached != null) return cached;
    final session = _session;
    final labels = _labels;
    if (session == null || labels == null) {
      throw StateError('Geo model not loaded');
    }
    final input = await OrtValue.fromList(
      Float32List.fromList([
        context.latitude,
        context.longitude,
        context.week.toDouble(),
      ]),
      [1, 3],
    );
    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({_inputName: input});
      final raw = await outputs[_outputName]!.asFlattenedList();
      final range = SpeciesRange.fromScores(
        context: context,
        probabilities: [for (final v in raw) (v as num).toDouble()],
        geoLabels: labels,
        audioLabels: audioLabels,
      );
      _cache[context.cacheKey] = range;
      return range;
    } finally {
      await input.dispose();
      for (final t in outputs?.values ?? const <OrtValue>[]) {
        await t.dispose();
      }
    }
  }

  Future<void> close() async {
    final s = _session;
    _session = null;
    _cache.clear();
    await s?.close();
  }
}
