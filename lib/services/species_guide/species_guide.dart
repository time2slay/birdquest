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

/// A freely licensed reference recording on Wikimedia Commons.
class GuideVoice {
  const GuideVoice({
    required this.fileName,
    required this.author,
    required this.license,
    this.licenseUrl,
    this.seconds,
  });

  /// Commons file name, underscores instead of spaces.
  final String fileName;
  final String author;
  final String license;
  final String? licenseUrl;

  /// Length when Commons knows it.
  final double? seconds;

  String get filePageUrl =>
      'https://commons.wikimedia.org/wiki/File:${Uri.encodeComponent(fileName)}';

  /// The original file, served via Special:FilePath (redirects to upload.).
  Uri get downloadUri => Uri.parse(
    'https://commons.wikimedia.org/wiki/Special:FilePath/'
    '${Uri.encodeComponent(fileName)}',
  );

  String get credit => '$author · $license';

  /// "Song", "Call" or null, from the file name.
  String? get kind {
    final f = fileName.toLowerCase();
    if (f.contains('song')) return 'song';
    if (f.contains('call')) return 'call';
    return null;
  }
}

/// Where a flight speed comes from.
enum SpeedSource {
  /// Measured for this species (Wikipedia's list of birds by flight speed).
  species,

  /// Wikidata's speed property for this species.
  wikidata,

  /// No figure for the species: the median of its family in that list.
  family,
}

/// Flight speeds in km/h.
class GuideSpeed {
  const GuideSpeed({this.horizontal, this.dive, required this.source});

  /// Fastest level (flapping) flight.
  final int? horizontal;

  /// Fastest overall, typically in a dive, when higher than [horizontal].
  final int? dive;
  final SpeedSource source;

  static const listUrl =
      'https://en.wikipedia.org/wiki/List_of_birds_by_flight_speed';

  /// The highest known figure.
  int get top => [?horizontal, ?dive].fold(0, (a, b) => a > b ? a : b);

  String get sourceUrl => switch (source) {
    SpeedSource.wikidata => 'https://www.wikidata.org/wiki/Property:P2052',
    _ => listUrl,
  };
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
  const GuideEntry({
    required this.texts,
    this.photo,
    this.voices = const [],
    this.family,
    this.speed,
  });

  final Map<GuideLanguage, GuideText> texts;
  final GuidePhoto? photo;

  /// Up to three reference recordings, best first.
  final List<GuideVoice> voices;

  /// Scientific family name, e.g. "Turdidae".
  final String? family;
  final GuideSpeed? speed;

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
  SpeciesGuide(this._entries) {
    for (final MapEntry(key: sci, value: e) in _entries.entries) {
      final fam = e.family;
      if (fam != null) (_byFamily[fam] ??= []).add(sci);
      final genus = genusOf(sci);
      if (genus != null) (_byGenus[genus] ??= []).add(sci);
    }
  }

  static const assetPath = 'assets/data/species_index.json.gz';
  static final empty = SpeciesGuide(const {});

  final Map<String, GuideEntry> _entries;
  final Map<String, List<String>> _byFamily = {};
  final Map<String, List<String>> _byGenus = {};

  int get length => _entries.length;

  /// The genus of a binomial name ("Turdus merula" -> "Turdus").
  static String? genusOf(String scientificName) {
    final i = scientificName.indexOf(' ');
    return i > 0 ? scientificName.substring(0, i) : null;
  }

  /// Species of [genus] in the index (including the one asked about).
  List<String> genusMembers(String genus) => _byGenus[genus] ?? const [];

  /// Species of [family] in the index.
  List<String> familyMembers(String family) => _byFamily[family] ?? const [];

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
      final spd = m['spd'] as Map<String, dynamic>?;
      entries[sci] = GuideEntry(
        family: m['fam'] as String?,
        voices: [
          for (final v in (m['snd'] as List<dynamic>? ?? const []))
            GuideVoice(
              fileName: (v as Map<String, dynamic>)['f'] as String,
              author: v['a'] as String,
              license: v['l'] as String,
              licenseUrl: v['u'] as String?,
              seconds: (v['d'] as num?)?.toDouble(),
            ),
        ],
        speed: spd == null
            ? null
            : GuideSpeed(
                horizontal: (spd['h'] as num?)?.round(),
                dive: (spd['d'] as num?)?.round(),
                source: spd['fam'] != null
                    ? SpeedSource.family
                    : spd['wd'] != null
                    ? SpeedSource.wikidata
                    : SpeedSource.species,
              ),
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
