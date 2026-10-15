/// Domain models shared between the data layer and the UI.
library;

/// Static information about a species, as known to the recognizer.
class SpeciesInfo {
  const SpeciesInfo({
    required this.scientificName,
    required this.commonName,
    this.taxonOrder,
    this.modelLabelId,
    this.description,
  });

  final String scientificName;
  final String commonName;
  final String? taxonOrder;
  final String? modelLabelId;
  final String? description;
}

/// Everything needed to save one confirmed encounter.
class EncounterDraft {
  const EncounterDraft({
    required this.species,
    required this.confirmedAt,
    this.sessionId,
    this.modelScore,
    this.clipPath,
    this.photoPaths = const [],
    this.latitude,
    this.longitude,
    this.notes,
    this.isDemo = false,
  });

  final SpeciesInfo species;
  final DateTime confirmedAt;
  final int? sessionId;
  final double? modelScore;

  /// Absolute path of a temporary clip; copied into app storage on save.
  final String? clipPath;

  /// Absolute paths of temporary photos; copied into app storage on save.
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final bool isDemo;
}

class CollectionStats {
  const CollectionStats({
    required this.uniqueSpecies,
    required this.encounters,
    required this.photos,
  });

  static const empty = CollectionStats(
    uniqueSpecies: 0,
    encounters: 0,
    photos: 0,
  );

  final int uniqueSpecies;
  final int encounters;
  final int photos;
}

/// One card in the collection, aggregated from confirmed sightings.
class CollectionEntry {
  const CollectionEntry({
    required this.speciesId,
    required this.scientificName,
    required this.commonName,
    required this.encounterCount,
    required this.photoCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.allDemo,
    this.referenceImage,
    this.coverPhotoPath,
    this.taxonOrder,
    this.description,
  });

  final int speciesId;
  final String scientificName;
  final String commonName;
  final int encounterCount;
  final int photoCount;
  final DateTime firstSeen;
  final DateTime lastSeen;

  /// True when every sighting of this species came from demo mode.
  final bool allDemo;
  final String? referenceImage;

  /// Relative media path of the user's chosen cover photo.
  final String? coverPhotoPath;
  final String? taxonOrder;
  final String? description;
}

class SightingPhoto {
  const SightingPhoto({
    required this.id,
    required this.path,
    required this.createdAt,
  });

  final int id;

  /// Relative media path.
  final String path;
  final DateTime createdAt;
}

/// One confirmed encounter with its photos.
class Encounter {
  const Encounter({
    required this.id,
    required this.speciesId,
    required this.confirmedAt,
    required this.photos,
    required this.isDemo,
    this.sessionId,
    this.modelScore,
    this.clipPath,
    this.latitude,
    this.longitude,
    this.notes,
  });

  final int id;
  final int speciesId;
  final int? sessionId;
  final DateTime confirmedAt;
  final double? modelScore;

  /// Relative media path.
  final String? clipPath;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final bool isDemo;
  final List<SightingPhoto> photos;

  bool get hasLocation => latitude != null && longitude != null;
}
