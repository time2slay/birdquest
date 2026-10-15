import 'dart:math' as math;

import 'labels.dart';
import 'prediction.dart';

/// Turns raw model scores into a short, sorted list of bird predictions.
///
/// BirdNET+ V3 already applies a sigmoid, so scores are used as-is. The
/// sensitivity shift follows the BirdNET Live app (MIT):
/// `sigmoid(logit(p) + (sensitivity - 1) * 5)`.
class PostProcessor {
  const PostProcessor({
    this.threshold = 0.35,
    this.topK = 10,
    this.sensitivity = 1.0,
    this.birdsOnly = true,
  });

  final double threshold;
  final int topK;

  /// 0.5..1.5; above 1 reports more (and less certain) detections.
  final double sensitivity;

  /// The model also knows frogs, insects and mammals; BirdQuest hides them.
  final bool birdsOnly;

  /// [allow], when given, hides species it rejects (e.g. out of range).
  List<Prediction> process(
    List<double> scores,
    List<ModelLabel> labels, {
    bool Function(String scientificName)? allow,
  }) {
    if (scores.length != labels.length) {
      throw ArgumentError(
        'Model returned ${scores.length} scores for ${labels.length} labels',
      );
    }
    final bias = (sensitivity - 1) * 5;
    final out = <Prediction>[];
    for (var i = 0; i < scores.length; i++) {
      var s = scores[i];
      if (s.isNaN) continue;
      if (bias != 0) s = _shift(s, bias);
      if (s < threshold) continue;
      final label = labels[i];
      if (birdsOnly && !label.isBird) continue;
      if (allow != null && !allow(label.scientificName)) continue;
      out.add(Prediction(species: label.toSpeciesInfo(), score: s));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.length > topK ? out.sublist(0, topK) : out;
  }

  static double _shift(double p, double bias) {
    const eps = 1e-7;
    final c = p.clamp(eps, 1 - eps);
    final logit = math.log(c / (1 - c));
    return 1 / (1 + math.exp(-(logit + bias)));
  }
}
