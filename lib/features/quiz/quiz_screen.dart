import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/clip_player.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/reference_voices.dart';
import '../../shared/widgets/species_extras.dart';
import '../progress/progress.dart';
import '../progress/rarity.dart';
import 'quiz_builder.dart';

sealed class QuizState {
  const QuizState();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

/// Not enough birds with sound yet.
class QuizUnavailable extends QuizState {
  const QuizUnavailable();
}

class QuizRunning extends QuizState {
  const QuizRunning({
    required this.questions,
    required this.index,
    required this.correct,
    this.picked,
  });

  final List<QuizQuestion> questions;
  final int index;
  final int correct;

  /// The option chosen for the current question, once answered.
  final String? picked;

  QuizQuestion get question => questions[index];
  bool get answered => picked != null;
  bool get last => index == questions.length - 1;
}

class QuizFinished extends QuizState {
  const QuizFinished(this.correct, this.total);
  final int correct;
  final int total;
}

/// Runs one round of "guess the bird by voice".
class QuizController extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizLoading();

  /// Overridable in tests.
  math.Random random = math.Random();

  Future<void> start() async {
    state = const QuizLoading();
    final guide = await ref.read(speciesGuideProvider.future);
    // Distractors are the birds of the user's region.
    final profile =
        ref.read(regionProfileProvider) ??
        await ref
            .read(regionProfileProvider.notifier)
            .ensureHere()
            .timeout(const Duration(seconds: 20), onTimeout: () => null);
    final voices = ref.read(referenceVoiceServiceProvider);
    final media = ref.read(mediaStoreProvider);
    final own = await ref.read(quizRepositoryProvider).ownClips();
    final canDownload = ref.read(wikimediaUserAgentProvider) != null;

    final pool = <QuizCandidate>[
      for (final c in own)
        QuizCandidate(
          scientificName: c.scientificName,
          source: QuizSource.own,
          load: () async => media.absolute(c.clipPath),
        ),
    ];
    final regional = profile?.species.keys.toList() ?? const <String>[];
    final downloadable = <QuizCandidate>[];
    for (final sci in regional) {
      final voice = guide[sci]?.voices.firstOrNull;
      if (voice == null) continue;
      final candidate = QuizCandidate(
        scientificName: sci,
        source: QuizSource.reference,
        voice: voice,
        load: () async => (await voices.get(voice))?.path,
      );
      if (await voices.cached(voice) != null) {
        pool.add(candidate); // works offline
      } else if (canDownload) {
        downloadable.add(candidate);
      }
    }
    // Top up with recordings that download on first play.
    downloadable.shuffle(random);
    final ownSpecies = {for (final c in pool) c.scientificName};
    for (final c in downloadable) {
      if (ownSpecies.length >= 10) break;
      if (ownSpecies.add(c.scientificName)) pool.add(c);
    }

    final questions = buildQuiz(
      pool: pool,
      others: regional,
      similarOf: (sci) => [
        for (final s in ref.read(similarSpeciesProvider(sci))) s.scientificName,
      ],
      random: random,
    );
    state = questions.isEmpty
        ? const QuizUnavailable()
        : QuizRunning(questions: questions, index: 0, correct: 0);
  }

  Future<void> answer(String scientificName) async {
    final s = state;
    if (s is! QuizRunning || s.answered) return;
    final right = scientificName == s.question.answer.scientificName;
    state = QuizRunning(
      questions: s.questions,
      index: s.index,
      correct: s.correct + (right ? 1 : 0),
      picked: scientificName,
    );
    await ref
        .read(quizRepositoryProvider)
        .record(
          scientificName: s.question.answer.scientificName,
          correct: right,
          source: s.question.answer.source,
        );
  }

  void next() {
    final s = state;
    if (s is! QuizRunning || !s.answered) return;
    state = s.last
        ? QuizFinished(s.correct, s.questions.length)
        : QuizRunning(
            questions: s.questions,
            index: s.index + 1,
            correct: s.correct,
          );
  }
}

final quizControllerProvider =
    NotifierProvider.autoDispose<QuizController, QuizState>(QuizController.new);

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(quizControllerProvider.notifier).start());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final controller = ref.read(quizControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(ru ? 'Угадай по голосу' : 'Guess by voice')),
      body: switch (state) {
        QuizLoading() => const Center(child: CircularProgressIndicator()),
        QuizUnavailable() => _Unavailable(ru: ru),
        QuizRunning() => _Question(
          state: state,
          ru: ru,
          controller: controller,
        ),
        QuizFinished(:final correct, :final total) => _Finished(
          correct: correct,
          total: total,
          ru: ru,
          onAgain: controller.start,
        ),
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.ru});
  final bool ru;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        NoticeCard(
          icon: Icons.music_off_rounded,
          title: ru ? 'Пока не хватает голосов' : 'Not enough voices yet',
          message: ru
              ? 'Для викторины нужны хотя бы 4 вида с записями. Сохраните '
                    'птиц со своим клипом, скачайте голоса для своей области '
                    'в Энциклопедии или подключитесь к сети.'
              : 'The quiz needs at least 4 species with recordings. Save '
                    'birds with your clip, download voices for your area in '
                    'the Encyclopedia, or go online.',
          actions: [
            FilledButton.tonal(
              onPressed: () => context.push('/guide/download'),
              child: Text(ru ? 'Скачать голоса' : 'Download voices'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Question extends ConsumerWidget {
  const _Question({
    required this.state,
    required this.ru,
    required this.controller,
  });

  final QuizRunning state;
  final bool ru;
  final QuizController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final q = state.question;
    final answerSci = q.answer.scientificName;
    final voice = q.answer.voice;
    return ListView(
      padding: const EdgeInsets.all(Space.lg),
      children: [
        Row(
          children: [
            Text(
              ru
                  ? 'Вопрос ${state.index + 1} из ${state.questions.length}'
                  : 'Question ${state.index + 1} of ${state.questions.length}',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text('${state.correct}', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: Space.sm),
        LinearProgressIndicator(
          value:
              (state.index + (state.answered ? 1 : 0)) / state.questions.length,
        ),
        const SizedBox(height: Space.lg),
        ClipPlayer(
          key: ValueKey('q${state.index}'),
          label: ru ? 'Кто это поёт?' : 'Who is singing?',
          subtitle: q.answer.source == QuizSource.own
              ? (ru ? 'Ваша запись' : 'Your own recording')
              : state.answered && voice != null
              ? voice.credit
              : (ru ? 'Эталонная запись' : 'Reference recording'),
          onInfo: state.answered && voice != null
              ? () => showVoiceCredit(context, voice, ru: ru)
              : null,
          loadPath: q.answer.load,
        ),
        const SizedBox(height: Space.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Space.sm,
          crossAxisSpacing: Space.sm,
          childAspectRatio: 0.92,
          children: [
            for (final sci in q.options)
              _Option(
                scientificName: sci,
                state: switch ((state.answered, sci == answerSci)) {
                  (false, _) => _OptionState.open,
                  (true, true) => _OptionState.right,
                  (true, false) when sci == state.picked => _OptionState.wrong,
                  _ => _OptionState.dimmed,
                },
                onTap: () => controller.answer(sci),
              ),
          ],
        ),
        const SizedBox(height: Space.lg),
        if (state.answered) ...[
          Text(
            state.picked == answerSci
                ? (ru ? 'Верно! +$quizAnswerXp XP' : 'Right! +$quizAnswerXp XP')
                : (ru
                      ? 'Это ${speciesDisplayName(ref, answerSci, englishNameFor(ref, answerSci))}'
                      : 'It was ${speciesDisplayName(ref, answerSci, englishNameFor(ref, answerSci))}'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.sm),
          FilledButton.icon(
            onPressed: controller.next,
            icon: Icon(
              state.last ? Icons.flag_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(
              state.last
                  ? (ru ? 'Итоги' : 'See results')
                  : (ru ? 'Дальше' : 'Next'),
            ),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { open, right, wrong, dimmed }

class _Option extends ConsumerWidget {
  const _Option({
    required this.scientificName,
    required this.state,
    required this.onTap,
  });

  final String scientificName;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final en = englishNameFor(ref, scientificName);
    final name = speciesDisplayName(ref, scientificName, en);
    final border = switch (state) {
      _OptionState.right => const Color(0xFF3F8A4A),
      _OptionState.wrong => theme.colorScheme.error,
      _ => Colors.transparent,
    };
    return AnimatedOpacity(
      duration: Motion.medium,
      opacity: state == _OptionState.dimmed ? 0.45 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: border, width: 3),
        ),
        child: InkWell(
          onTap: state == _OptionState.open ? onTap : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BirdImage(
                  name: en,
                  scientificName: scientificName,
                  showPlaceholderLabel: false,
                  cacheWidth: 360,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    if (state == _OptionState.right)
                      const Icon(Icons.check_circle, color: Color(0xFF3F8A4A))
                    else if (state == _OptionState.wrong)
                      Icon(Icons.cancel, color: theme.colorScheme.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({
    required this.correct,
    required this.total,
    required this.ru,
    required this.onAgain,
  });

  final int correct;
  final int total;
  final bool ru;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xp = math.min(correct * quizAnswerXp, quizDailyXpCap);
    final verdict = correct == total
        ? (ru
              ? 'Безупречно! Вы знаток голосов.'
              : 'Flawless! A true voice expert.')
        : correct >= total * 0.7
        ? (ru ? 'Отличный слух!' : 'Great ears!')
        : correct >= total * 0.4
        ? (ru ? 'Неплохо — тренировка помогает.' : 'Not bad — practice helps.')
        : (ru
              ? 'Голоса птиц коварны. Ещё раунд?'
              : 'Bird voices are tricky. Another round?');
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        const SizedBox(height: Space.xl),
        Icon(Icons.emoji_events_rounded, size: 96, color: context.nature.ochre),
        const SizedBox(height: Space.lg),
        Text(
          '$correct / $total',
          style: theme.textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.sm),
        Text(
          verdict,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.sm),
        Text(
          ru
              ? 'До +$xp XP (не больше $quizDailyXpCap XP в день)'
              : 'Up to +$xp XP (at most $quizDailyXpCap XP a day)',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: Text(ru ? 'Ещё раунд' : 'Play again'),
        ),
      ],
    );
  }
}
