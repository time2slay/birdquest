import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../services/species_guide/species_guide.dart';
import '../../shared/theme/tokens.dart';
import 'export_service.dart';

/// Lets the user export their collection and hands the file to the share
/// sheet (Drive, Telegram, Files…). Demo sightings are never exported.
Future<void> showExportSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ExportSheet(),
    );

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ExportFormat _format = ExportFormat.csv;
  bool _withLocation = true;
  bool _busy = false;
  String? _message;

  Future<void> _export() async {
    final ru = ref.read(guideLanguageProvider) == GuideLanguage.ru;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rows = await ref.read(sightingRepositoryProvider).exportRows();
      if (rows.isEmpty) {
        setState(
          () => _message = ru
              ? 'Пока нечего экспортировать — сохраните первую встречу.'
              : 'Nothing to export yet — save your first encounter.',
        );
        return;
      }
      final guide = await ref.read(speciesGuideProvider.future);
      final content = switch (_format) {
        ExportFormat.csv => buildCsv(
          rows,
          withLocation: _withLocation,
          russianNames: {
            for (final r in rows)
              r.scientificName: ?guide[r.scientificName]
                  ?.text(GuideLanguage.ru)
                  ?.name,
          },
        ),
        ExportFormat.gpx => buildGpx(rows),
        ExportFormat.ebird => buildEbird(rows, withLocation: _withLocation),
      };
      if (_format == ExportFormat.gpx && !rows.any((r) => r.hasLocation)) {
        setState(
          () => _message = ru
              ? 'Ни у одной встречи нет GPS — в GPX будет пусто.'
              : 'No encounter has GPS — the GPX would be empty.',
        );
        return;
      }
      final file = await writeExport(
        ref.read(appPathsProvider).tempDir,
        _format,
        content,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: _format.mimeType)],
          subject: 'BirdQuest',
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = ref.watch(guideLanguageProvider) == GuideLanguage.ru;
    final theme = Theme.of(context);
    final locationMatters = _format != ExportFormat.gpx;
    String title(ExportFormat f) => switch (f) {
      ExportFormat.csv => ru ? 'Таблица CSV' : 'CSV spreadsheet',
      ExportFormat.gpx => ru ? 'GPX — точки на карте' : 'GPX — map waypoints',
      ExportFormat.ebird => ru ? 'Для импорта в eBird' : 'For eBird import',
    };
    String subtitle(ExportFormat f) => switch (f) {
      ExportFormat.csv =>
        ru
            ? 'Все встречи: дата, вид (EN/RU), место, редкость, заметки'
            : 'Every encounter: date, species (EN/RU), place, rarity, notes',
      ExportFormat.gpx =>
        ru
            ? 'Встречи с GPS — для карт и GIS'
            : 'Encounters with GPS — for maps and GIS',
      ExportFormat.ebird =>
        ru
            ? 'eBird Record Format, как случайные наблюдения'
            : 'eBird Record Format, as incidental observations',
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ru ? 'Экспорт коллекции' : 'Export your collection',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Space.sm),
            RadioGroup<ExportFormat>(
              groupValue: _format,
              onChanged: (f) => setState(() => _format = f!),
              child: Column(
                children: [
                  for (final f in ExportFormat.values)
                    RadioListTile<ExportFormat>(
                      contentPadding: EdgeInsets.zero,
                      value: f,
                      title: Text(title(f)),
                      subtitle: Text(subtitle(f)),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: locationMatters ? _withLocation : true,
              onChanged: locationMatters
                  ? (v) => setState(() => _withLocation = v)
                  : null,
              title: Text(ru ? 'Координаты' : 'Coordinates'),
              subtitle: Text(
                ru
                    ? 'Файл покажет, где вы бывали. Выключите, если делитесь им.'
                    : 'The file shows where you have been. Turn off before '
                          'sharing it with others.',
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: Space.sm),
              Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(ru ? 'Экспортировать' : 'Export'),
            ),
          ],
        ),
      ),
    );
  }
}
