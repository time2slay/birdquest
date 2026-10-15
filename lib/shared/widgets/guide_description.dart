import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'photo_credit.dart';

/// Localized species name for [scientificName], falling back to [fallback].
String speciesDisplayName(
  WidgetRef ref,
  String scientificName,
  String fallback,
) => ref.watch(
  speciesNameProvider((scientificName: scientificName, fallback: fallback)),
);

/// Short species description from Wikipedia in the chosen language, with the
/// CC BY-SA attribution and a link to the article. Falls back to [fallback]
/// (BirdQuest's own field notes) when no description is available.
class GuideDescription extends ConsumerWidget {
  const GuideDescription({
    super.key,
    required this.scientificName,
    this.fallback,
  });

  final String scientificName;
  final String? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(guideLanguageProvider);
    final async = ref.watch(descriptionProvider(scientificName));
    final desc = async.value;

    if (async.isLoading && desc == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: Space.sm),
            Text(
              lang == GuideLanguage.ru
                  ? 'Загружаем описание…'
                  : 'Loading description…',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (desc == null) {
      return Text(
        fallback ??
            (lang == GuideLanguage.ru
                ? 'Описание пока недоступно. Скачайте энциклопедию для '
                      'работы офлайн.'
                : 'No description yet. Download the Encyclopedia to read '
                      'offline.'),
        style: theme.textTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: fallback == null ? context.nature.inkMuted : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          desc.text,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 15,
              color: context.nature.inkMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Wikipedia (${desc.lang.name.toUpperCase()}) · CC BY-SA 4.0',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => openExternal(context, desc.articleUrl),
              child: Text(lang == GuideLanguage.ru ? 'Читать' : 'Read more'),
            ),
          ],
        ),
      ],
    );
  }
}
