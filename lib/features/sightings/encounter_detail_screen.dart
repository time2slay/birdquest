import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';
import '../../shared/widgets/clip_player.dart';
import '../../shared/widgets/common.dart';
import '../bird_details/photo_capture.dart';

/// One saved encounter: photos, sound, location and notes, with delete.
class EncounterDetailScreen extends ConsumerWidget {
  const EncounterDetailScreen({super.key, required this.sightingId});

  final int sightingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounter = ref.watch(encounterProvider(sightingId));
    return encounter.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (e) => e == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.delete_outline_rounded,
                title: 'Encounter deleted',
                message: 'This encounter is no longer in your collection.',
              ),
            )
          : _EncounterView(encounter: e),
    );
  }
}

class _EncounterView extends ConsumerWidget {
  const _EncounterView({required this.encounter});
  final Encounter encounter;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Delete this encounter?'),
        content: Text(
          'Its ${encounter.photos.length} photo(s) and sound clip will be '
          'removed and your collection count will go down by one. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(sightingRepositoryProvider).deleteSighting(encounter.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    SightingPhoto photo,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sightingRepositoryProvider).deletePhoto(photo.id);
    }
  }

  Future<void> _editNotes(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: encounter.notes);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Field notes'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Behaviour, habitat, weather…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (text != null) {
      await ref
          .read(sightingRepositoryProvider)
          .updateNotes(encounter.id, text.trim().isEmpty ? null : text.trim());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final when = DateFormat.yMMMMEEEEd().add_Hm().format(encounter.confirmedAt);
    final media = ref.read(mediaStoreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encounter'),
        actions: [
          IconButton(
            tooltip: 'Delete encounter',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          if (encounter.isDemo) ...[
            const DemoBanner(),
            const SizedBox(height: Space.md),
          ],
          Text(when, style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (encounter.modelScore != null)
                ScoreChip(score: encounter.modelScore!),
              if (encounter.hasLocation)
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(
                    '${encounter.latitude!.toStringAsFixed(5)}, '
                    '${encounter.longitude!.toStringAsFixed(5)}',
                  ),
                ),
            ],
          ),
          if (encounter.clipPath != null) ...[
            const SizedBox(height: Space.lg),
            ClipPlayer(
              label: 'Recorded sound',
              loadPath: () async => media.absolute(encounter.clipPath!),
            ),
          ],
          SectionHeader(
            'Photos · ${encounter.photos.length}',
            trailing: TextButton.icon(
              onPressed: () async {
                final path = await capturePhoto(context, ref);
                if (path != null) {
                  await ref
                      .read(sightingRepositoryProvider)
                      .addPhoto(encounter.id, path);
                }
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add'),
            ),
          ),
          if (encounter.photos.isEmpty)
            Text(
              'No photos for this encounter.',
              style: theme.textTheme.bodySmall,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Space.sm,
                crossAxisSpacing: Space.sm,
              ),
              itemCount: encounter.photos.length,
              itemBuilder: (context, i) {
                final photo = encounter.photos[i];
                return GestureDetector(
                  onTap: () => _showPhoto(context, photo),
                  onLongPress: () => _deletePhoto(context, ref, photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.md),
                    child: MediaPhoto(path: photo.path, cacheWidth: 600),
                  ),
                );
              },
            ),
          if (encounter.photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(
                'Tap to view · long-press to delete',
                style: theme.textTheme.bodySmall,
              ),
            ),
          SectionHeader(
            'Field notes',
            trailing: IconButton(
              tooltip: 'Edit notes',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editNotes(context, ref),
            ),
          ),
          Text(
            encounter.notes ?? 'No notes yet.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, SightingPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: InteractiveViewer(
            child: Center(
              child: MediaPhoto(path: photo.path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
