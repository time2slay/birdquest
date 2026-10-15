import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../bird_recognition/bird_recognition_service.dart';
import '../bird_recognition/geo_filter.dart';
import '../bird_recognition/labels.dart';
import '../bird_recognition/model_manager.dart';

/// Lists the birds that occur in an area at any time of year, using the
/// BirdNET+ geo model (Apache-2.0) on the phone.
class RegionSpeciesService {
  RegionSpeciesService(this.modelManager);

  final ModelManager modelManager;

  /// One sample per month (BirdNET weeks 2, 6, …, 46).
  static const sampleWeeks = [2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46];

  /// Center plus two rings of eight points, so large areas are covered.
  static List<({double lat, double lon})> samplePoints(
    double lat,
    double lon,
    double radiusKm,
  ) {
    final points = [(lat: lat, lon: lon)];
    final cosLat = math.cos(lat * math.pi / 180).abs().clamp(0.05, 1.0);
    for (final fraction in const [0.5, 1.0]) {
      final d = radiusKm * fraction;
      for (var i = 0; i < 8; i++) {
        final bearing = i * math.pi / 4;
        points.add((
          lat: (lat + d / 111.0 * math.cos(bearing)).clamp(-89.9, 89.9),
          lon:
              ((lon + d / (111.0 * cosLat) * math.sin(bearing) + 540) % 360) -
              180,
        ));
      }
    }
    return points;
  }

  Future<List<ModelLabel>> speciesNear({
    required double latitude,
    required double longitude,
    required double radiusKm,
    void Function(double progress)? onProgress,
  }) async {
    final status = await modelManager.refresh();
    if (status is! ModelInstalled) throw const ModelNotInstalledException();
    final labels = await compute(
      parseLabels,
      await File(status.labelsPath).readAsString(),
    );
    final geo = GeoFilter();
    try {
      await geo.load(
        status.geoModelPath,
        await File(status.geoLabelsPath).readAsString(),
      );
      final found = <String>{};
      final points = samplePoints(latitude, longitude, radiusKm);
      final total = points.length * sampleWeeks.length;
      var done = 0;
      for (final p in points) {
        for (final week in sampleWeeks) {
          final range = await geo.rangeFor(
            GeoContext(latitude: p.lat, longitude: p.lon, week: week),
            labels,
          );
          found.addAll(range.plausible);
          onProgress?.call(++done / total);
        }
      }
      return [
        for (final l in labels)
          if (l.isBird && found.contains(l.scientificName)) l,
      ]..sort((a, b) => a.commonName.compareTo(b.commonName));
    } finally {
      await geo.close();
    }
  }
}
