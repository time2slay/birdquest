import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/species_guide/species_guide.dart';
import '../theme/tokens.dart';

Future<void> openExternal(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open the link')));
  }
}

/// Compact "📷 Author · License" overlay; tap for full attribution.
class PhotoCreditChip extends StatelessWidget {
  const PhotoCreditChip({super.key, required this.photo});

  final GuidePhoto photo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Photo credit: ${photo.credit}',
      child: GestureDetector(
        onTap: () => showPhotoCredit(context, photo),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  photo.credit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPhotoCredit(BuildContext context, GuidePhoto photo) {
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
              Text('Reference photo', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.md),
              Text('Author: ${photo.author}'),
              Text('License: ${photo.license}'),
              const SizedBox(height: Space.sm),
              Text(
                'From Wikimedia Commons. Shown unmodified except for '
                'resizing and cropping to fit.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openExternal(context, photo.filePageUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('View on Commons'),
                  ),
                  if (photo.licenseUrl != null)
                    TextButton(
                      onPressed: () => openExternal(context, photo.licenseUrl!),
                      child: const Text('License'),
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
