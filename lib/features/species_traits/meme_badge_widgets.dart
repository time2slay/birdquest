import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/tokens.dart';
import '../achievements/achievements.dart';
import '../progress/rarity.dart';
import 'meme_badges.dart';

/// Badges for a species from what the app knows about it: the guide
/// (family, speed), its rarity here and when the user usually hears it.
final memeBadgesProvider = Provider.family<List<MemeBadge>, String>((
  ref,
  scientificName,
) {
  final entry = ref.watch(speciesGuideProvider).value?[scientificName];
  final rarity = ref.watch(regionProfileProvider)?.rarityOf(scientificName);
  final facts = ref.watch(sightingFactsProvider).value ?? const [];
  final own = [
    for (final f in facts)
      if (f.scientificName == scientificName) f.confirmedAt.toLocal(),
  ];
  final dawn = own.length < 2
      ? null
      : own.where((t) => t.hour < 7).length / own.length;
  return memeBadgesFor(
    scientificName: scientificName,
    family: entry?.family,
    speed: entry?.speed,
    rarity: rarity,
    dawnShare: dawn,
  );
});

/// Sticker chips; tap one to see why the bird earned it.
class MemeBadgeRow extends ConsumerWidget {
  const MemeBadgeRow({super.key, required this.scientificName});

  final String scientificName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(memeBadgesProvider(scientificName));
    if (badges.isEmpty) return const SizedBox.shrink();
    final lang = ref.watch(guideLanguageProvider);
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [for (final b in badges) MemeBadgeChip(badge: b, lang: lang)],
      ),
    );
  }
}

class MemeBadgeChip extends StatelessWidget {
  const MemeBadgeChip({super.key, required this.badge, required this.lang});

  final MemeBadge badge;
  final GuideLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: badge.title(lang),
      child: Material(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _showWhy(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 12, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(badge.asset, width: 32, height: 32),
                const SizedBox(width: 4),
                Text(
                  badge.title(lang),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWhy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(badge.asset, width: 160, height: 160),
                const SizedBox(height: Space.md),
                Text(badge.title(lang), style: theme.textTheme.headlineSmall),
                const SizedBox(height: Space.xs),
                Text(
                  badge.why(lang),
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
