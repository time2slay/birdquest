import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/bird_recognition/bird_recognition_service.dart';
import '../../services/bird_recognition/geo_filter.dart';
import '../../services/bird_recognition/labels.dart';
import '../../services/bird_recognition/model_manager.dart';
import '../../services/location_service.dart';
import '../../services/species_guide/region_species_service.dart';
import '../../services/species_guide/species_guide.dart';
import '../map/area_grouping.dart';

/// How rare a species is in the user's region, from the BirdNET+ geo model.
enum Rarity {
  common,
  uncommon,
  rare,
  legendary;

  static Rarity? parse(String? name) =>
      Rarity.values.where((r) => r.name == name).firstOrNull;

  /// Average yearly geo-model probability → tier. Calibrated on Berlin and
  /// Da Nang: blackbird/robin ≈ 0.98 and house sparrow in Da Nang ≈ 0.33
  /// (common), eagle owl in Berlin ≈ 0.19 (uncommon), golden eagle in
  /// Berlin ≈ 0.03 (rare). Roughly 30–45% of a region's birds are rare.
  static Rarity fromMean(double mean) => mean >= 0.3
      ? Rarity.common
      : mean >= 0.1
      ? Rarity.uncommon
      : Rarity.rare;

  String label(GuideLanguage lang) => lang == GuideLanguage.ru
      ? const ['Обычный', 'Необычный', 'Редкий', 'Легендарный'][index]
      : const ['Common', 'Uncommon', 'Rare', 'Legendary'][index];

  Color get color => const [
    Color(0xFF7A8A6E),
    Color(0xFF3F8A4A),
    Color(0xFF3B78C2),
    Color(0xFFC9932E),
  ][index];

  IconData get icon => const [
    Icons.circle_outlined,
    Icons.change_history_rounded,
    Icons.diamond_outlined,
    Icons.auto_awesome_rounded,
  ][index];
}

/// One bird that occurs in the region in at least one month.
class RegionSpecies {
  const RegionSpecies({
    required this.scientificName,
    required this.commonName,
    required this.taxonOrder,
    required this.mean,
    this.monthly = const [],
  });

  final String scientificName;
  final String commonName;
  final String taxonOrder;

  /// Average geo-model probability over the year.
  final double mean;

  /// Geo-model probability for each month, January first (12 values; empty
  /// in profiles cached before seasonality existed).
  final List<double> monthly;

  Rarity get rarity => Rarity.fromMean(mean);
}

/// The birds of the user's region and how common each one is.
class RegionProfile {
  const RegionProfile({
    required this.latitude,
    required this.longitude,
    required this.species,
    required this.unknown,
  });

  final double latitude;
  final double longitude;

  /// Birds present in at least one month, by scientific name.
  final Map<String, RegionSpecies> species;

  /// Audio-model birds the geo model has no data for.
  final Set<String> unknown;

  /// Null when the geo model cannot judge the species. Birds it knows but
  /// never expects here are legendary (vagrants).
  Rarity? rarityOf(String scientificName) {
    if (unknown.contains(scientificName)) return null;
    return species[scientificName]?.rarity ?? Rarity.legendary;
  }

  Map<String, Object> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'species': [
      for (final s in species.values)
        [
          s.scientificName,
          s.commonName,
          s.taxonOrder,
          s.mean,
          [for (final m in s.monthly) (m * 1000).round() / 1000],
        ],
    ],
    'unknown': unknown.toList(),
  };

  factory RegionProfile.fromJson(Map<String, dynamic> j) => RegionProfile(
    latitude: (j['lat'] as num).toDouble(),
    longitude: (j['lon'] as num).toDouble(),
    species: {
      for (final e in j['species'] as List)
        e[0] as String: RegionSpecies(
          scientificName: e[0] as String,
          commonName: e[1] as String,
          taxonOrder: e[2] as String,
          mean: (e[3] as num).toDouble(),
          monthly: e.length > 4
              ? [for (final m in e[4] as List) (m as num).toDouble()]
              : const [],
        ),
    },
    unknown: {for (final u in j['unknown'] as List) u as String},
  );

  /// Builds a profile from one geo-model range per sampled week.
  factory RegionProfile.fromRanges({
    required double latitude,
    required double longitude,
    required List<SpeciesRange> ranges,
    required List<ModelLabel> labels,
    double presence = 0.03,
  }) {
    final species = <String, RegionSpecies>{};
    final unknown = <String>{};
    for (final l in labels) {
      if (!l.isBird) continue;
      final weekly = [for (final r in ranges) ?r.scores[l.scientificName]];
      if (weekly.isEmpty) {
        unknown.add(l.scientificName);
        continue;
      }
      final max = weekly.reduce((a, b) => a > b ? a : b);
      if (max < presence) continue;
      species[l.scientificName] = RegionSpecies(
        scientificName: l.scientificName,
        commonName: l.commonName,
        taxonOrder: l.taxonOrder,
        mean: weekly.reduce((a, b) => a + b) / weekly.length,
        monthly: weekly.length == 12 ? weekly : const [],
      );
    }
    return RegionProfile(
      latitude: latitude,
      longitude: longitude,
      species: species,
      unknown: unknown,
    );
  }
}

/// Runs the geo model for every month at one place.
Future<RegionProfile> computeRegionProfile(
  ModelManager models,
  double latitude,
  double longitude,
) async {
  final status = await models.refresh();
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
    final ranges = [
      for (final week in RegionSpeciesService.sampleWeeks)
        await geo.rangeFor(
          GeoContext(latitude: latitude, longitude: longitude, week: week),
          labels,
        ),
    ];
    return RegionProfile.fromRanges(
      latitude: latitude,
      longitude: longitude,
      ranges: ranges,
      labels: labels,
    );
  } finally {
    await geo.close();
  }
}

typedef RegionProfileComputer = Future<RegionProfile> Function(
  double latitude,
  double longitude,
);

/// Overridable in tests.
final regionProfileComputerProvider = Provider<RegionProfileComputer>(
  (ref) =>
      (lat, lon) =>
          computeRegionProfile(ref.read(modelManagerProvider), lat, lon),
);

/// The user's home region, cached in preferences and recomputed when they
/// move more than [refreshKm] away.
class RegionProfileNotifier extends Notifier<RegionProfile?> {
  /// v2 adds per-month values; a v1 profile is simply recomputed.
  static const _key = 'region_profile_v2';
  static const refreshKm = 50.0;
  Future<RegionProfile?>? _pending;

  @override
  RegionProfile? build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return null;
    try {
      return RegionProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Profile for a place, recomputing only when it is far from the cached
  /// one. Null when the models are missing or the computation fails.
  Future<RegionProfile?> ensureNear(double latitude, double longitude) {
    final current = state;
    if (current != null &&
        distanceKm(current.latitude, current.longitude, latitude, longitude) <=
            refreshKm) {
      return Future.value(current);
    }
    return _pending ??= () async {
      try {
        final profile = await ref.read(regionProfileComputerProvider)(
          latitude,
          longitude,
        );
        state = profile;
        await ref
            .read(sharedPreferencesProvider)
            .setString(_key, jsonEncode(profile.toJson()));
        return profile;
      } catch (e) {
        debugPrint('Region profile: $e');
        return current;
      } finally {
        _pending = null;
      }
    }();
  }

  /// Profile for the phone's current approximate position.
  Future<RegionProfile?> ensureHere() async {
    final pos = await LocationService.coarsePosition();
    if (pos == null) return state;
    return ensureNear(pos.latitude, pos.longitude);
  }
}

final regionProfileProvider =
    NotifierProvider<RegionProfileNotifier, RegionProfile?>(
      RegionProfileNotifier.new,
    );

/// Monthly presence of a species in the user's region, January first, or
/// null when there is no region profile yet or the geo model cannot judge
/// the species. All zeros means "not expected here".
final seasonalityProvider = Provider.family<List<double>?, String>((
  ref,
  scientificName,
) {
  final profile = ref.watch(regionProfileProvider);
  if (profile == null || profile.unknown.contains(scientificName)) return null;
  final s = profile.species[scientificName];
  if (s == null) return List.filled(12, 0);
  return s.monthly.length == 12 ? s.monthly : null;
});
