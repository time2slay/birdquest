import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../theme/tokens.dart';
import 'clip_player.dart';
import 'common.dart';
import 'photo_credit.dart';

/// Freely licensed reference recordings of a species from Wikimedia Commons,
/// downloaded on first play (or with the Encyclopedia) and cached.
class ReferenceVoices extends ConsumerWidget {
  const ReferenceVoices({
    super.key,
    required this.scientificName,
    this.compareHint = false,
  });

  final String scientificName;

  /// Mentions comparing with the user's own recording (scanner details).
  final bool compareHint;

  static const _ethicsKey = 'voice_ethics_shown';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(speciesGuideProvider).value;
    final voices = guide?[scientificName]?.voices ?? const <GuideVoice>[];
    if (voices.isEmpty) return const SizedBox.shrink();
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(ru ? 'Эталонные голоса' : 'Reference recordings'),
        if (compareHint)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.sm),
            child: Text(
              ru
                  ? 'Сравните со своей записью выше.'
                  : 'Compare them with your own recording above.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final (i, v) in voices.indexed) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          ClipPlayer(
            key: ValueKey(v.fileName),
            label: _label(v, i, ru),
            subtitle: v.credit,
            onInfo: () => showVoiceCredit(context, v, ru: ru),
            loadPath: () => _load(context, ref, v, ru),
          ),
        ],
      ],
    );
  }

  static String _label(GuideVoice v, int i, bool ru) {
    final kind = switch (v.kind) {
      'song' => ru ? 'Песня' : 'Song',
      'call' => ru ? 'Позыв' : 'Call',
      _ => ru ? 'Запись ${i + 1}' : 'Recording ${i + 1}',
    };
    final s = v.seconds;
    return s == null ? kind : '$kind · ${s.round()} ${ru ? 'с' : 's'}';
  }

  Future<String?> _load(
    BuildContext context,
    WidgetRef ref,
    GuideVoice v,
    bool ru,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(_ethicsKey) ?? false)) {
      await prefs.setBool(_ethicsKey, true);
      messenger?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            ru
                ? 'Не проигрывайте голоса птицам подолгу, особенно в сезон '
                      'гнездования: это их беспокоит.'
                : 'Please don’t play calls to birds for long, especially in '
                      'the nesting season: it disturbs them.',
          ),
        ),
      );
    }
    final file = await ref.read(referenceVoiceServiceProvider).get(v);
    if (file == null) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            ru
                ? 'Запись недоступна офлайн. Подключитесь к сети или скачайте '
                      'голоса в Энциклопедии.'
                : 'Not available offline. Connect, or download voices in the '
                      'Encyclopedia.',
          ),
        ),
      );
    }
    return file?.path;
  }
}

Future<void> showVoiceCredit(
  BuildContext context,
  GuideVoice voice, {
  required bool ru,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ru ? 'Эталонная запись' : 'Reference recording',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: Space.md),
              Text('${ru ? 'Автор' : 'Author'}: ${voice.author}'),
              Text('${ru ? 'Лицензия' : 'License'}: ${voice.license}'),
              const SizedBox(height: Space.sm),
              Text(
                ru
                    ? 'С Wikimedia Commons, без изменений.'
                    : 'From Wikimedia Commons, unmodified.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openExternal(context, voice.filePageUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(ru ? 'Открыть на Commons' : 'View on Commons'),
                  ),
                  if (voice.licenseUrl != null)
                    TextButton(
                      onPressed: () => openExternal(context, voice.licenseUrl!),
                      child: Text(ru ? 'Лицензия' : 'License'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
