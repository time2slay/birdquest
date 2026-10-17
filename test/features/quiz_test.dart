import 'dart:math' as math;

import 'package:birdquest/data/repositories/quiz_repository.dart';
import 'package:birdquest/features/progress/progress.dart';
import 'package:birdquest/features/quiz/quiz_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

QuizCandidate _c(String sci, [QuizSource source = QuizSource.reference]) =>
    QuizCandidate(scientificName: sci, source: source, load: () async => sci);

void main() {
  const regional = [
    'Turdus merula',
    'Turdus philomelos',
    'Erithacus rubecula',
    'Parus major',
    'Fringilla coelebs',
    'Sturnus vulgaris',
  ];

  test('every question has 4 distinct options including the answer', () {
    final quiz = buildQuiz(
      pool: [for (final s in regional) _c(s)],
      others: regional,
      similarOf: (_) => const [],
      random: math.Random(1),
    );
    expect(quiz, hasLength(regional.length), reason: 'one per species');
    for (final q in quiz) {
      expect(q.options, hasLength(4));
      expect(q.options.toSet(), hasLength(4));
      expect(q.options, contains(q.answer.scientificName));
    }
  });

  test('look-alikes are used as distractors', () {
    final quiz = buildQuiz(
      pool: [_c('Turdus merula')],
      others: regional,
      similarOf: (s) =>
          s == 'Turdus merula' ? const ['Turdus philomelos'] : const [],
      random: math.Random(2),
    );
    expect(quiz.single.options, contains('Turdus philomelos'));
  });

  test("the user's own clip wins over a reference recording", () {
    final quiz = buildQuiz(
      pool: [_c('Turdus merula'), _c('Turdus merula', QuizSource.own)],
      others: regional,
      similarOf: (_) => const [],
      random: math.Random(3),
    );
    expect(quiz.single.answer.source, QuizSource.own);
  });

  test('too few species means no quiz', () {
    expect(
      buildQuiz(
        pool: [_c('Turdus merula')],
        others: const ['Parus major', 'Turdus merula'],
        similarOf: (_) => const [],
        random: math.Random(4),
      ),
      isEmpty,
    );
  });

  test('quiz XP is 5 per right answer, capped at 50 a day', () {
    QuizAnswer a(int day, bool ok) => QuizAnswer(
      answeredAt: DateTime(2026, 10, day, 12),
      scientificName: 'Parus major',
      correct: ok,
      source: QuizSource.reference,
    );
    expect(quizXp([a(1, true), a(1, false), a(1, true)]), 10);
    expect(quizXp([for (var i = 0; i < 14; i++) a(2, true)]), 50);
    expect(
      quizXp([for (var i = 0; i < 14; i++) a(2, true), a(3, true)]),
      55,
      reason: 'the cap is per day',
    );
  });

  test('quiz answers are stored and read back in order', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final repo = QuizRepository(db);
    await repo.record(
      scientificName: 'Parus major',
      correct: true,
      source: QuizSource.own,
      at: DateTime(2026, 10, 17, 8),
    );
    await repo.record(
      scientificName: 'Turdus merula',
      correct: false,
      source: QuizSource.reference,
      at: DateTime(2026, 10, 17, 9),
    );
    final answers = await repo.watchAnswers().first;
    expect(answers.map((a) => (a.scientificName, a.correct, a.source)), [
      ('Parus major', true, QuizSource.own),
      ('Turdus merula', false, QuizSource.reference),
    ]);
  });

  test('the quiz quest counts today’s right answers', () {
    final quest = questPool.singleWhere((q) => q.id == 'quiz_5');
    final stats = DayStats.compute(
      const [],
      DateTime(2026, 10, 17),
      quizCorrect: 5,
    );
    expect(quest.measure(stats), 5);
    expect(quest.measure(stats) >= quest.target, isTrue);
  });
}
