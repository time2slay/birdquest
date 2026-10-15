import 'dart:typed_data';

import '../../data/models.dart';

/// Score below which a prediction is shown as "uncertain".
const double kUncertainBelow = 0.5;

/// One species prediction for one audio window.
class Prediction {
  const Prediction({required this.species, required this.score});

  final SpeciesInfo species;

  /// Model score in [0, 1]. A confidence-like value, not a calibrated
  /// probability.
  final double score;

  bool get isUncertain => score < kUncertainBelow;
}

/// Events emitted while a recognizer is listening.
sealed class RecognitionEvent {
  const RecognitionEvent();
}

/// Microphone input level, 0..1, for the activity indicator.
class AudioLevelEvent extends RecognitionEvent {
  const AudioLevelEvent(this.level);
  final double level;
}

/// The result of one inference window.
class PredictionEvent extends RecognitionEvent {
  const PredictionEvent({
    required this.at,
    required this.predictions,
    this.window,
    this.sampleRate = 32000,
  });

  final DateTime at;

  /// Predictions above threshold, best first. May be empty.
  final List<Prediction> predictions;

  /// The mono audio window that produced these predictions, if available.
  final Float32List? window;
  final int sampleRate;
}

/// State of the location (geo model) filter for the current session.
sealed class GeoFilterState {
  const GeoFilterState();
}

/// The user turned the filter off.
class GeoFilterOff extends GeoFilterState {
  const GeoFilterOff();
}

/// Waiting for a location fix.
class GeoFilterLocating extends GeoFilterState {
  const GeoFilterLocating();
}

/// Predictions are limited to species plausible here this week.
class GeoFilterActive extends GeoFilterState {
  const GeoFilterActive(this.plausibleSpecies, this.allows);
  final int plausibleSpecies;

  /// Whether a species is plausible here; used to drop suggestions made
  /// before the location fix arrived.
  final bool Function(String scientificName) allows;
}

/// The filter could not run; all species are shown.
class GeoFilterUnavailable extends GeoFilterState {
  const GeoFilterUnavailable(this.reason);
  final String reason;
}

class GeoFilterEvent extends RecognitionEvent {
  const GeoFilterEvent(this.state);
  final GeoFilterState state;
}

/// A non-fatal problem reported while listening.
class RecognitionErrorEvent extends RecognitionEvent {
  const RecognitionErrorEvent(this.message);
  final String message;
}
