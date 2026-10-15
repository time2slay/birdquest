import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Language for species names and descriptions.
enum GuideLanguage { en, ru }

/// Licensed lead photo of a species on Wikimedia Commons.
class GuidePhoto {
  const GuidePhoto({
    required this.fileName,
    required this.author,
    required this.license,
    this.licenseUrl,
  });

  /// Commons file name, underscores instead of spaces.
  final String fileName;
  final String author;
  final String license;
  final String? licenseUrl;

  String get filePageUrl =>
      'https://commons.wikimedia.org/wiki/File:${Uri.encodeComponent(fileName)}';

  /// A Commons thumbnail of [width] px served via Special:FilePath.
  Uri thumbnailUri(int width) => Uri.parse(
    'https://commons.wikimedia.org/wiki/Special:FilePath/'
    '${Uri.encodeComponent(fileName)}?width=$width',
  );

  /// One-line attribution, e.g. "Andreas Trepte · CC BY-SA 2.5".
  String get credit => '$author · $license';
}

/// Text for one language.
class GuideText {
  const GuideText({this.name, this.description, this.articleTitle});

  final String? name;
  final String? description;
  final String? articleTitle;

  String? articleUrl(GuideLanguage lang) => articleTitle == null
      ? null
      : 'https://${lang.name}.wikipedia.org/wiki/'
            '${Uri.encodeComponent(articleTitle!.replaceAll(' ', '_'))}';
}

class GuideEntry {
  const GuideEntry({required this.texts, this.photo});

  final Map<GuideLanguage, GuideText> texts;
  final GuidePhoto? photo;

  GuideText? text(GuideLanguage lang) => texts[lang];

  /// Description in [lang], falling back to the other language.
  ({String text, GuideLanguage lang, String? url})? description(
    GuideLanguage lang,
  ) {
    for (final l in [lang, ...GuideLanguage.values.where((x) => x != lang)]) {
      final t = texts[l];
      if (t?.description != null && t!.description!.isNotEmpty) {
        return (text: t.description!, lang: l, url: t.articleUrl(l));
      }
    }
    return null;
  }
}

/// Species index bundled with the app, built by `tool/build_species_info.py`
/// from Wikidata (names, CC0), Wikipedia (article titles) and Wikimedia
/// Commons (photo credits). Descriptions are fetched on demand or by an
/// Encyclopedia download and cached in the database.
class SpeciesGuide {
  SpeciesGuide(this._entries);

  static const assetPath = 'assets/data/species_index.json.gz';
  static final empty = SpeciesGuide(const {});

  final Map<String, GuideEntry> _entries;

  int get length => _entries.length;

  GuideEntry? operator [](String scientificName) => _entries[scientificName];

  /// Name to show for a species: the localized common name when available,
  /// else [fallback] (the model's English name).
  String nameFor(String scientificName, String fallback, GuideLanguage lang) {
    if (lang == GuideLanguage.en) return fallback;
    return _entries[scientificName]?.texts[lang]?.name ?? fallback;
  }

  static Future<SpeciesGuide> loadAsset([AssetBundle? bundle]) async {
    final data = await (bundle ?? rootBundle).load(assetPath);
    return compute(
      decode,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Decodes the gzip'd JSON bundle. Public for tests and isolates.
  static SpeciesGuide decode(Uint8List gz) {
    final json =
        jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, dynamic>;
    final species = json['species'] as Map<String, dynamic>;
    final entries = <String, GuideEntry>{};
    species.forEach((sci, raw) {
      final m = raw as Map<String, dynamic>;
      GuideText? text(String key) {
        final t = m[key] as Map<String, dynamic>?;
        if (t == null) return null;
        return GuideText(
          name: t['n'] as String?,
          description: t['d'] as String?,
          articleTitle: t['t'] as String?,
        );
      }

      final img = m['img'] as Map<String, dynamic>?;
      entries[sci] = GuideEntry(
        texts: {
          for (final l in GuideLanguage.values)
            if (text(l.name) != null) l: text(l.name)!,
        },
        photo: img == null
            ? null
            : GuidePhoto(
                fileName: img['f'] as String,
                author: img['a'] as String,
                license: img['l'] as String,
                licenseUrl: img['u'] as String?,
              ),
      );
    });
    return SpeciesGuide(entries);
  }
}
