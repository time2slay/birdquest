import 'dart:math' as math;

import '../../data/repositories/quiz_repository.dart';
import '../../services/species_guide/species_guide.dart';

/// A sound the quiz can play, and which bird made it.
class QuizCandidate {
  const QuizCandidate({
    required this.scientificName,
    required this.source,
    required this.load,
    this.voice,
  });

  final String scientificName;
  final QuizSource source;

  /// Resolves (and if needed downloads) the audio file; null if unavailable.
  final Future<String?> Function() load;

  /// The Commons recording, for its credit; null for the user's own clip.
  final GuideVoice? voice;
}

class QuizQuestion {
  const QuizQuestion(this.answer, this.options);
  final QuizCandidate answer;

  /// Scientific names, shuffled, including the answer.
  final List<String> options;
}

/// Builds up to [count] questions from [pool], one per species. Each has
/// [optionCount] choices: look-alikes from [similarOf] first (that is what
/// makes it a real test), then other birds from [others]. Returns an empty
/// list when there are not enough distinct species for one question.
List<QuizQuestion> buildQuiz({
  required List<QuizCandidate> pool,
  required List<String> others,
  required List<String> Function(String scientificName) similarOf,
  required math.Random random,
  int count = 10,
  int optionCount = 4,
}) {
  final bySpecies = <String, QuizCandidate>{};
  for (final c in pool) {
    // Prefer the user's own recording of a species: it is what they heard.
    final prev = bySpecies[c.scientificName];
    if (prev == null || c.source == QuizSource.own) {
      bySpecies[c.scientificName] = c;
    }
  }
  final everyone = {...bySpecies.keys, ...others}.toList();
  if (everyone.length < optionCount) return const [];

  final picks = bySpecies.values.toList()..shuffle(random);
  final questions = <QuizQuestion>[];
  for (final answer in picks.take(count)) {
    final sci = answer.scientificName;
    final options = <String>{sci};
    final similar = similarOf(sci).where((s) => s != sci).toList()
      ..shuffle(random);
    // At most two look-alikes, so the question stays fair.
    for (final s in similar.take(2)) {
      if (everyone.contains(s)) options.add(s);
    }
    final rest = everyone.where((s) => !options.contains(s)).toList()
      ..shuffle(random);
    for (final s in rest) {
      if (options.length >= optionCount) break;
      options.add(s);
    }
    final shuffled = options.toList()..shuffle(random);
    questions.add(QuizQuestion(answer, shuffled));
  }
  return questions;
}
