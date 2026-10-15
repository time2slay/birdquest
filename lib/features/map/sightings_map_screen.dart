import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../services/location_service.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/bird_map.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../../shared/widgets/theme_toggle.dart';
import 'area_grouping.dart';

/// Map of confirmed sightings. Pins show the species' reference photo (not
/// the user's photos); tapping one opens a preview with area statistics.
class SightingsMapScreen extends ConsumerStatefulWidget {
  const SightingsMapScreen({super.key});

  @override
  ConsumerState<SightingsMapScreen> createState() => _SightingsMapScreenState();
}

class _SightingsMapScreenState extends ConsumerState<SightingsMapScreen> {
  final _map = MapController();
  LatLng? _initial;

  Future<void> _goToMe() async {
    final pos = await LocationService.coarsePosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location unavailable')));
      }
      return;
    }
    _map.move(LatLng(pos.latitude, pos.longitude), 13);
  }

  @override
  Widget build(BuildContext context) {
    final located = ref.watch(locatedSightingsProvider);
    final sightings = located.value ?? const [];
    final groups = groupByArea(sightings);
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    _initial ??= sightings.isNotEmpty
        ? LatLng(sightings.first.latitude, sightings.first.longitude)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ru ? 'Карта находок' : 'Sightings map'),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'map-me',
        tooltip: ru ? 'Моё местоположение' : 'My location',
        onPressed: _goToMe,
        child: const Icon(Icons.my_location_rounded),
      ),
      body: Stack(
        children: [
          // Wait for the saved sightings so the map opens on them, not on
          // the world view.
          if (!located.hasValue)
            const Center(child: CircularProgressIndicator())
          else
            BirdMap(
              controller: _map,
              initialCenter: _initial ?? const LatLng(48, 15),
              initialZoom: _initial == null ? 3 : 12,
              layers: [
                MarkerLayer(
                  markers: [
                    for (final g in groups.reversed)
                      Marker(
                        point: LatLng(g.latitude, g.longitude),
                        width: 60,
                        height: 60,
                        child: _BirdPin(
                          group: g,
                          onTap: () => _showPreview(context, g),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          if (groups.isEmpty)
            Positioned(
              left: Space.lg,
              right: Space.lg,
              bottom: Space.xxl * 2,
              child: NoticeCard(
                icon: Icons.place_outlined,
                tone: NoticeTone.info,
                title: ru
                    ? 'Здесь появятся ваши находки'
                    : 'Your sightings appear here',
                message: ru
                    ? 'Сохраняйте находки с включённым «Прикрепить GPS» — '
                          'координаты хранятся только на телефоне.'
                    : 'Save discoveries with "Attach GPS location" on. '
                          'Coordinates stay on this phone.',
              ),
            ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, AreaGroup g) {
    showModalBottomSheet<void>(
      context: context,
      // Above the bottom navigation bar, not underneath it.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scroll) => _AreaPreview(group: g, scroll: scroll),
      ),
    );
  }
}

class _BirdPin extends StatelessWidget {
  const _BirdPin({required this.group, required this.onTap});
  final AreaGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${group.commonName}, ${group.count} sightings',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(blurRadius: 6, color: Colors.black38),
                ],
              ),
              child: ClipOval(
                child: BirdImage(
                  name: group.commonName,
                  scientificName: group.scientificName,
                  showPlaceholderLabel: false,
                  cacheWidth: 160,
                ),
              ),
            ),
            if (group.count > 1)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '${group.count}',
                    style: TextStyle(
                      color: scheme.onSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AreaPreview extends ConsumerWidget {
  const _AreaPreview({required this.group, required this.scroll});
  final AreaGroup group;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final name = speciesDisplayName(
      ref,
      group.scientificName,
      group.commonName,
    );
    final fmt = DateFormat.yMMMd(ru ? 'ru' : 'en');
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: BirdImage(
            name: name,
            scientificName: group.scientificName,
            borderRadius: BorderRadius.circular(Radii.lg),
            showCredit: true,
          ),
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(child: Text(name, style: theme.textTheme.headlineSmall)),
            if (group.allDemo) const DemoBadge(),
          ],
        ),
        Text(
          group.scientificName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: context.nature.inkMuted,
          ),
        ),
        const SizedBox(height: Space.md),
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: context.nature.mossContainer,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ru
                    ? 'Замечена ${group.count} раз в этом районе'
                    : 'Spotted ${group.count} '
                          '${group.count == 1 ? 'time' : 'times'} in this area',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.nature.onMossContainer,
                ),
              ),
              Text(
                ru
                    ? 'Игроками BirdQuest · пока только ваши находки'
                    : 'By BirdQuest players · currently your sightings only',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.xs),
              Text(
                group.count == 1
                    ? fmt.format(group.firstSeen)
                    : '${fmt.format(group.firstSeen)} – ${fmt.format(group.lastSeen)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        GuideDescription(scientificName: group.scientificName),
        const SizedBox(height: Space.md),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/species/${group.speciesId}');
          },
          icon: const Icon(Icons.history_rounded),
          label: Text(ru ? 'История встреч' : 'Encounter history'),
        ),
      ],
    );
  }
}
