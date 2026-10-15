import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/bird_image.dart';

/// Lets the user pick one of their own photos as the species' cover image.
Future<void> showCoverPicker(
  BuildContext context,
  WidgetRef ref,
  CollectionEntry entry,
) async {
  final encounters = await ref
      .read(sightingRepositoryProvider)
      .watchEncounters(entry.speciesId)
      .first;
  final photos = [for (final e in encounters) ...e.photos];
  if (!context.mounted) return;

  if (photos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Take a photo of this bird to use it as the cover.'),
      ),
    );
    return;
  }

  final selected = await showModalBottomSheet<int?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a cover for ${entry.commonName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: Space.sm,
                  crossAxisSpacing: Space.sm,
                ),
                itemCount: photos.length,
                itemBuilder: (context, i) {
                  final photo = photos[i];
                  final isCover = photo.path == entry.coverPhotoPath;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, photo.id),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaPhoto(path: photo.path, cacheWidth: 300),
                          if (isCover)
                            Container(
                              color: Colors.black38,
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (entry.coverPhotoPath != null) ...[
              const SizedBox(height: Space.md),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, -1),
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Use default image'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  if (selected == null) return;
  await ref
      .read(collectionRepositoryProvider)
      .setCoverPhoto(entry.speciesId, selected == -1 ? null : selected);
}
