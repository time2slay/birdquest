import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/reference_voices.dart';
import '../../shared/widgets/species_extras.dart';
import '../species_traits/meme_badge_widgets.dart';

/// Encyclopedia page for one species: reference photo, names in both
/// languages, description, and the user's own encounters.
class SpeciesGuideScreen extends ConsumerWidget {
  const SpeciesGuideScreen({
    super.key,
    required this.scientificName,
    this.fallbackName,
  });

  final String scientificName;
  final String? fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final guide = ref.watch(speciesGuideProvider).value;
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final entry = guide?[scientificName];
    final english =
        fallbackName ??
        entry?.text(GuideLanguage.en)?.articleTitle ??
        scientificName;
    final name = speciesDisplayName(ref, scientificName, english);
    final otherName = ru ? english : entry?.text(GuideLanguage.ru)?.name;
    final collected = ref
        .watch(collectionProvider)
        .value
        ?.where((e) => e.scientificName == scientificName)
        .firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF2F5D3A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: BirdImage(
                name: name,
                scientificName: scientificName,
                showCredit: true,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(Space.lg),
            sliver: SliverList.list(
              children: [
                Text(name, style: theme.textTheme.headlineMedium),
                if (otherName != null && otherName != name)
                  Text(otherName, style: theme.textTheme.titleSmall),
                Text(
                  scientificName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: context.nature.inkMuted,
                  ),
                ),
                MemeBadgeRow(scientificName: scientificName),
                const SizedBox(height: Space.lg),
                GuideDescription(scientificName: scientificName),
                ReferenceVoices(scientificName: scientificName),
                SpeciesExtras(scientificName: scientificName),
                const SizedBox(height: Space.lg),
                Card(
                  child: ListTile(
                    leading: Icon(
                      collected == null
                          ? Icons.hearing_outlined
                          : Icons.collections_bookmark_rounded,
                    ),
                    title: Text(
                      collected == null
                          ? (ru ? 'Ещё не встречена' : 'Not discovered yet')
                          : (ru
                                ? 'Встречена ${collected.encounterCount} раз'
                                : 'Discovered ${collected.encounterCount} '
                                      '${collected.encounterCount == 1 ? 'time' : 'times'}'),
                    ),
                    subtitle: collected == null
                        ? Text(
                            ru
                                ? 'Послушайте — может, она рядом.'
                                : 'Listen out — it may be nearby.',
                          )
                        : null,
                    trailing: collected == null
                        ? null
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: collected == null
                        ? null
                        : () => context.push('/species/${collected.speciesId}'),
                  ),
                ),
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
