import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/species_extras.dart';
import '../progress/rarity.dart';
import '../species_traits/meme_badge_widgets.dart';

/// What goes on a shared card. Deliberately no coordinates.
class ShareCardData {
  const ShareCardData({
    required this.scientificName,
    required this.commonName,
    required this.date,
    this.photoPath,
    this.rarity,
  });

  final String scientificName;
  final String commonName;
  final DateTime date;

  /// Absolute path of the user's own photo; else the reference photo is used.
  final String? photoPath;
  final Rarity? rarity;
}

/// Shows a preview of the card and shares it as a PNG.
Future<void> showShareCard(BuildContext context, ShareCardData data) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ShareDialog(data: data),
  );
}

class _ShareDialog extends ConsumerStatefulWidget {
  const _ShareDialog({required this.data});
  final ShareCardData data;

  @override
  ConsumerState<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<_ShareDialog> {
  final _boundary = GlobalKey();
  bool _busy = false;

  static const cardWidth = 320.0;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final box =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: 1080 / cardWidth);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = ref.read(appPathsProvider).tempDir;
      await dir.create(recursive: true);
      final safe = widget.data.scientificName.replaceAll(
        RegExp('[^A-Za-z]+'),
        '_',
      );
      final file = File(p.join(dir.path, 'birdquest_$safe.png'));
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      final ru = ref.read(guideLanguageProvider) == GuideLanguage.ru;
      final name = ref
          .read(speciesGuideProvider)
          .value
          ?.nameFor(
            widget.data.scientificName,
            widget.data.commonName,
            ref.read(guideLanguageProvider),
          );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: ru
              ? 'Моя находка в BirdQuest: ${name ?? widget.data.commonName}'
              : 'My BirdQuest find: ${name ?? widget.data.commonName}',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    return Dialog(
      insetPadding: const EdgeInsets.all(Space.lg),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _boundary,
              child: SizedBox(
                width: cardWidth,
                child: ShareCard(data: widget.data),
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              ru
                  ? 'Без координат — только вид, дата и фото.'
                  : 'No coordinates — just the bird, date and photo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Space.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(ru ? 'Отмена' : 'Cancel'),
                ),
                const SizedBox(width: Space.sm),
                FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(ru ? 'Поделиться' : 'Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The 4:5 card itself, in the app's forest style.
class ShareCard extends ConsumerWidget {
  const ShareCard({super.key, required this.data});

  final ShareCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(guideLanguageProvider);
    final ru = lang == GuideLanguage.ru;
    final guide = ref.watch(speciesGuideProvider).value;
    final entry = guide?[data.scientificName];
    final name =
        guide?.nameFor(data.scientificName, data.commonName, lang) ??
        data.commonName;
    final other = guide?.nameFor(
      data.scientificName,
      data.commonName,
      ru ? GuideLanguage.en : GuideLanguage.ru,
    );
    final badges = ref.watch(memeBadgesProvider(data.scientificName));
    final reference = data.photoPath == null
        ? ref.watch(referencePhotoProvider(data.scientificName)).value
        : null;
    final photo = data.photoPath != null
        ? FileImage(File(data.photoPath!))
        : reference != null
        ? FileImage(reference.file) as ImageProvider
        : null;
    final date = DateFormat.yMMMMd(ru ? 'ru' : 'en').format(data.date);
    const cream = Color(0xFFFFF6DC);

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3F27), Color(0xFF2F5D3A), Color(0xFF4F7A45)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo != null)
                Positioned.fill(
                  child: Image(image: photo, fit: BoxFit.cover),
                )
              else
                const Positioned.fill(
                  bottom: 120,
                  child: Icon(
                    Icons.flutter_dash,
                    size: 96,
                    color: Colors.white24,
                  ),
                ),
              // Fade the photo into the card.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.45, 0.72],
                      colors: [
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xF21E3F27),
                      ],
                    ),
                  ),
                ),
              ),
              if (badges.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      for (final b in badges)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Image.asset(b.asset, width: 64, height: 64),
                        ),
                    ],
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (data.rarity != null)
                          _Pill(
                            icon: data.rarity!.icon,
                            text: data.rarity!.label(lang),
                            color: data.rarity!.color,
                          ),
                        for (final b in badges)
                          _Pill(
                            text: b.title(lang),
                            color: const Color(0xFF8DB573),
                          ),
                        if (entry?.speed case final s? when s.top > 0)
                          _Pill(
                            icon: Icons.speed_rounded,
                            text: speedText(s, ru: ru).split(' · ').first,
                            color: const Color(0xFFC79A3B),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: cream,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (other != null && other != name)
                      Text(
                        other,
                        style: const TextStyle(
                          color: Color(0xCCFFF6DC),
                          fontSize: 13,
                        ),
                      ),
                    Text(
                      data.scientificName,
                      style: const TextStyle(
                        color: Color(0xB3FFF6DC),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          size: 16,
                          color: cream,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'BirdQuest',
                          style: TextStyle(
                            color: cream,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            date,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xCCFFF6DC),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (data.photoPath == null && reference != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '📷 ${reference.photo.credit} · Wikimedia Commons',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0x99FFF6DC),
                            fontSize: 9,
                          ),
                        ),
                      ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
