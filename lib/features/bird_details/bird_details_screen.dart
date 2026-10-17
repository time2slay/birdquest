import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../services/bird_recognition/field_notes.dart';
import 'photo_capture.dart';
import '../../services/location_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/clip_player.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/guide_description.dart';
import '../progress/progress_widgets.dart';
import '../progress/rarity.dart';
import '../scanner/scanner_controller.dart';
import '../../shared/widgets/reference_voices.dart';
import '../../shared/widgets/species_extras.dart';
import '../species_traits/meme_badge_widgets.dart';

/// Details for a species heard in the current session, with Take Photo and
/// Save Discovery.
class BirdDetailsScreen extends ConsumerStatefulWidget {
  const BirdDetailsScreen({super.key, required this.speciesKey});

  /// Scientific name of the detection group.
  final String speciesKey;

  @override
  ConsumerState<BirdDetailsScreen> createState() => _BirdDetailsScreenState();
}

class _BirdDetailsScreenState extends ConsumerState<BirdDetailsScreen> {
  bool _attachLocation = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Rarity chip: compute the home region once if it is not known yet.
    if (ref.read(regionProfileProvider) == null) {
      ref.read(regionProfileProvider.notifier).ensureHere();
    }
  }

  ScannerController get _scanner =>
      ref.read(scannerControllerProvider.notifier);

  Future<void> _takePhoto(DetectionGroup group) async {
    final path = await capturePhoto(context, ref);
    if (path == null || !mounted) return;
    if (group.isSaved) {
      // Already saved: attach directly to the saved encounter.
      await ref
          .read(sightingRepositoryProvider)
          .addPhoto(group.savedSightingIds.last, path);
      _snack('Photo added to your saved encounter');
    } else {
      _scanner.addPendingPhoto(widget.speciesKey, path);
    }
  }

  Future<void> _save({bool separate = false}) async {
    setState(() => _saving = true);
    try {
      double? lat, lon;
      if (_attachLocation) {
        final pos = await LocationService.currentPosition();
        lat = pos?.latitude;
        lon = pos?.longitude;
        if (pos == null) _snack('Location unavailable — saved without GPS');
      }
      // Rarity where the bird was found, fixed now so XP never shifts later.
      final regions = ref.read(regionProfileProvider.notifier);
      final profile = lat != null && lon != null
          ? await regions.ensureNear(lat, lon)
          : await regions.ensureHere();
      await _scanner.saveEncounter(
        widget.speciesKey,
        separate: separate,
        latitude: lat,
        longitude: lon,
        rarity: profile?.rarityOf(widget.speciesKey)?.name,
      );
      if (!mounted) return;
      _snack(
        separate
            ? 'Saved as a separate encounter'
            : 'Discovery saved to your collection',
      );
    } catch (e) {
      _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerControllerProvider);
    final group = state.groups[widget.speciesKey];
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Detection no longer available',
          message:
              'This session was cleared. Saved discoveries are in your '
              'collection.',
        ),
      );
    }

    final theme = Theme.of(context);
    final species = group.species;
    final name = speciesDisplayName(
      ref,
      species.scientificName,
      species.commonName,
    );
    final when = DateFormat.yMMMd().add_Hm().format(group.firstHeard);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF2F5D3A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'bird-${species.scientificName}',
                child: BirdImage(
                  name: name,
                  scientificName: species.scientificName,
                  showCredit: true,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(Space.lg),
            sliver: SliverList.list(
              children: [
                if (state.isDemo) ...[
                  const DemoBanner(),
                  const SizedBox(height: Space.md),
                ],
                Text(name, style: theme.textTheme.headlineMedium),
                if (name != species.commonName)
                  Text(species.commonName, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  species.scientificName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: context.nature.inkMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: Space.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SpeciesRarityChip(species.scientificName),
                ),
                MemeBadgeRow(scientificName: species.scientificName),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ScoreChip(score: group.bestScore),
                    Chip(
                      avatar: const Icon(Icons.repeat_rounded, size: 16),
                      label: Text('Heard ${group.hits}×'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.schedule_rounded, size: 16),
                      label: Text(when),
                    ),
                    if (species.taxonOrder != null)
                      Chip(label: Text(species.taxonOrder!)),
                  ],
                ),
                if (group.isUncertain) ...[
                  const SizedBox(height: Space.md),
                  const NoticeCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Uncertain identification',
                    message:
                        'The model is not confident about this one. Listen '
                        'again or look for the bird before confirming.',
                  ),
                ],
                const SizedBox(height: Space.lg),
                GuideDescription(
                  scientificName: species.scientificName,
                  fallback:
                      species.description ??
                      fieldNoteFor(species.scientificName),
                ),
                const SizedBox(height: Space.lg),
                if (group.hasAudio)
                  ClipPlayer(
                    label: 'Best recording this session',
                    loadPath: () => _scanner.ensureClip(widget.speciesKey),
                  ),
                ReferenceVoices(
                  scientificName: species.scientificName,
                  compareHint: group.hasAudio,
                ),
                SpeciesExtras(scientificName: species.scientificName),
                SectionHeader(
                  group.isSaved ? 'Your photos' : 'Your photos (optional)',
                ),
                _PendingPhotos(
                  group: group,
                  onRemove: (path) =>
                      _scanner.removePendingPhoto(widget.speciesKey, path),
                ),
                if (!group.isSaved)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _attachLocation,
                    onChanged: (v) => setState(() => _attachLocation = v),
                    title: const Text('Attach GPS location'),
                    subtitle: const Text('Stored only on this phone'),
                    secondary: const Icon(Icons.place_outlined),
                  ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _takePhoto(group),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Take photo'),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: group.isSaved
                          ? FilledButton.tonalIcon(
                              onPressed: () async {
                                final id = await ref
                                    .read(sightingRepositoryProvider)
                                    .upsertSpecies(species);
                                if (context.mounted) {
                                  context.push('/species/$id');
                                }
                              },
                              icon: const Icon(
                                Icons.collections_bookmark_outlined,
                              ),
                              label: const Text('View history'),
                            )
                          : FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.bookmark_add_outlined),
                              label: const Text('Save discovery'),
                            ),
                    ),
                  ],
                ),
                if (group.isSaved) ...[
                  const SizedBox(height: Space.md),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          group.savedSightingIds.length == 1
                              ? 'Saved as 1 encounter. More detections this '
                                    'session won\'t add extra encounters.'
                              : 'Saved as ${group.savedSightingIds.length} '
                                    'separate encounters this session.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _confirmSeparate(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Save as a separate encounter'),
                    ),
                  ),
                ],
                const SizedBox(height: Space.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSeparate(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save a separate encounter?'),
        content: const Text(
          'Use this only if you heard a different individual, e.g. another '
          'bird of the same species in a new spot. Your collection count '
          'will increase by one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save separately'),
          ),
        ],
      ),
    );
    if (ok == true) await _save(separate: true);
  }
}

class _PendingPhotos extends StatelessWidget {
  const _PendingPhotos({required this.group, required this.onRemove});

  final DetectionGroup group;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (group.pendingPhotos.isEmpty) {
      return Text(
        group.isSaved
            ? 'Photos you take now are added to the saved encounter.'
            : 'Spotted it? Take a photo — it will be attached to this '
                  'encounter when you save.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: group.pendingPhotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) {
          final path = group.pendingPhotos[i];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox.square(
                  dimension: 112,
                  child: MediaPhoto(
                    path: path,
                    absolute: true,
                    cacheWidth: 336,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => onRemove(path),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Remove photo',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
