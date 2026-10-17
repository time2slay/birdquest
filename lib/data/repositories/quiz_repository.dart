import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Where a quiz question's sound came from.
enum QuizSource {
  /// A freely licensed Wikimedia Commons recording.
  reference,

  /// The user's own saved clip.
  own,
}

class QuizAnswer {
  const QuizAnswer({
    required this.answeredAt,
    required this.scientificName,
    required this.correct,
    required this.source,
  });

  final DateTime answeredAt;
  final String scientificName;
  final bool correct;
  final QuizSource source;
}

/// Answers of the "guess the bird by voice" quiz. XP is derived from them.
class QuizRepository {
  QuizRepository(this._db);
  final AppDatabase _db;

  Future<void> record({
    required String scientificName,
    required bool correct,
    required QuizSource source,
    DateTime? at,
  }) => _db
      .into(_db.quizAnswers)
      .insert(
        QuizAnswersCompanion.insert(
          answeredAt: at ?? DateTime.now(),
          scientificName: scientificName,
          correct: correct,
          source: source.name,
        ),
      );

  /// The user's own saved clips (one per species, newest), for questions.
  Future<List<({String scientificName, String commonName, String clipPath})>>
  ownClips() async {
    final rows = await _db
        .customSelect(
          'SELECT sp.scientific_name, sp.common_name, s.audio_clip_path '
          'FROM sightings s JOIN species sp ON sp.id = s.species_id '
          'WHERE s.is_demo = 0 AND s.audio_clip_path IS NOT NULL '
          'ORDER BY s.confirmed_at DESC',
          readsFrom: {_db.sightings, _db.species},
        )
        .get();
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add(r.read<String>('scientific_name')))
          (
            scientificName: r.read<String>('scientific_name'),
            commonName: r.read<String>('common_name'),
            clipPath: r.read<String>('audio_clip_path'),
          ),
    ];
  }

  Stream<List<QuizAnswer>> watchAnswers() =>
      (_db.select(
        _db.quizAnswers,
      )..orderBy([(a) => OrderingTerm.asc(a.answeredAt)])).watch().map(
        (rows) => [
          for (final r in rows)
            QuizAnswer(
              answeredAt: r.answeredAt,
              scientificName: r.scientificName,
              correct: r.correct,
              source:
                  QuizSource.values
                      .where((s) => s.name == r.source)
                      .firstOrNull ??
                  QuizSource.reference,
            ),
        ],
      );
}
