import 'dart:math' as math;

import '../../data/models.dart';

/// All sightings of one species within about [areaRadiusKm] of each other.
class AreaGroup {
  const AreaGroup({
    required this.speciesId,
    required this.scientificName,
    required this.commonName,
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.firstSeen,
    required this.lastSeen,
    required this.allDemo,
  });

  final int speciesId;
  final String scientificName;
  final String commonName;

  /// Mean position of the sightings, used for the pin.
  final double latitude;
  final double longitude;

  /// Confirmed sightings of this species in this area.
  final int count;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final bool allDemo;
}

/// Grid cell size in degrees (~2.2 km); used to count distinct areas.
const double areaCellDegrees = 0.02;

String areaCellKey(double lat, double lon) =>
    '${(lat / areaCellDegrees).floor()}:${(lon / areaCellDegrees).floor()}';

/// Sightings of a species closer than this to a pin join that pin.
const double areaRadiusKm = 1.0;

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Groups sightings by species and proximity (no grid edges, so two
/// sightings a few metres apart never split), most-seen first.
List<AreaGroup> groupByArea(List<LocatedSighting> sightings) {
  final clusters = <List<LocatedSighting>>[];
  final centers = <({int species, double lat, double lon})>[];
  final sorted = [...sightings]
    ..sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
  for (final s in sorted) {
    var joined = false;
    for (var i = 0; i < clusters.length; i++) {
      final c = centers[i];
      if (c.species == s.speciesId &&
          _distanceKm(c.lat, c.lon, s.latitude, s.longitude) <= areaRadiusKm) {
        final list = clusters[i]..add(s);
        centers[i] = (
          species: c.species,
          lat:
              list.map((x) => x.latitude).reduce((a, b) => a + b) / list.length,
          lon:
              list.map((x) => x.longitude).reduce((a, b) => a + b) /
              list.length,
        );
        joined = true;
        break;
      }
    }
    if (!joined) {
      clusters.add([s]);
      centers.add((species: s.speciesId, lat: s.latitude, lon: s.longitude));
    }
  }
  final groups = [
    for (var i = 0; i < clusters.length; i++)
      AreaGroup(
        speciesId: clusters[i].first.speciesId,
        scientificName: clusters[i].first.scientificName,
        commonName: clusters[i].first.commonName,
        latitude: centers[i].lat,
        longitude: centers[i].lon,
        count: clusters[i].length,
        firstSeen: clusters[i].first.confirmedAt,
        lastSeen: clusters[i].last.confirmedAt,
        allDemo: clusters[i].every((s) => s.isDemo),
      ),
  ];
  groups.sort((a, b) => b.count.compareTo(a.count));
  return groups;
}
