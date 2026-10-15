import 'package:drift/drift.dart';

import '../../services/species_guide/species_guide.dart';
import '../../services/species_guide/wikipedia_client.dart';
import '../database/app_database.dart';

/// A cached species description.
class GuideDescriptionData {
  const GuideDescriptionData({
    required this.text,
    required this.lang,
    required this.articleTitle,
  });

  final String text;
  final GuideLanguage lang;
  final String articleTitle;

  String get articleUrl =>
      'https://${lang.name}.wikipedia.org/wiki/'
      '${Uri.encodeComponent(articleTitle.replaceAll(' ', '_'))}';
}

class EncyclopediaPack {
  const EncyclopediaPack({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.languages,
    required this.withPhotos,
    required this.speciesCount,
    required this.createdAt,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final List<GuideLanguage> languages;
  final bool withPhotos;
  final int speciesCount;
  final DateTime createdAt;
}

/// One species in the downloaded Encyclopedia.
class EncyclopediaSpecies {
  const EncyclopediaSpecies({
    required this.scientificName,
    required this.commonName,
  });

  final String scientificName;
  final String commonName;
}

/// Description cache and Encyclopedia packs.
class GuideRepository {
  GuideRepository(this._db, this._wiki);

  final AppDatabase _db;
  final WikipediaClient _wiki;

  Future<GuideDescriptionData?> cachedDescription(
    String scientificName,
    GuideLanguage lang,
  ) async {
    final row =
        await (_db.select(_db.guideDescriptions)..where(
              (d) =>
                  d.scientificName.equals(scientificName) &
                  d.lang.equals(lang.name),
            ))
            .getSingleOrNull();
    return row == null
        ? null
        : GuideDescriptionData(
            text: row.body,
            lang: lang,
            articleTitle: row.articleTitle,
          );
  }

  /// Description in [lang] (or the other language as a fallback): from the
  /// cache, or fetched once from Wikipedia when [allowNetwork].
  Future<GuideDescriptionData?> description(
    String scientificName,
    GuideEntry? entry,
    GuideLanguage lang, {
    required bool allowNetwork,
  }) async {
    final order = [lang, ...GuideLanguage.values.where((l) => l != lang)];
    for (final l in order) {
      final hit = await cachedDescription(scientificName, l);
      if (hit != null) return hit;
    }
    if (!allowNetwork || entry == null) return null;
    for (final l in order) {
      final title = entry.text(l)?.articleTitle;
      if (title == null) continue;
      try {
        final got = await _wiki.intros(l, [title]);
        final text = got[title];
        if (text != null) {
          await _store(scientificName, l, title, text);
          return GuideDescriptionData(text: text, lang: l, articleTitle: title);
        }
      } catch (_) {
        return null; // Offline or rate-limited: try again next time.
      }
    }
    return null;
  }

  Future<void> _store(
    String sci,
    GuideLanguage lang,
    String title,
    String text,
  ) => _db
      .into(_db.guideDescriptions)
      .insertOnConflictUpdate(
        GuideDescriptionsCompanion.insert(
          scientificName: sci,
          lang: lang.name,
          body: text,
          articleTitle: title,
          fetchedAt: DateTime.now(),
        ),
      );

  /// Downloads descriptions for [species] in [lang], [WikipediaClient.batchSize]
  /// titles per request, skipping ones already cached. Calls [onProgress] with
  /// the number of species processed.
  Future<void> downloadDescriptions(
    List<({String scientificName, String title})> species,
    GuideLanguage lang, {
    void Function(int done)? onProgress,
    bool Function()? isCancelled,
    Duration pause = const Duration(milliseconds: 700),
  }) async {
    var done = 0;
    final todo = <({String scientificName, String title})>[];
    for (final s in species) {
      if (await cachedDescription(s.scientificName, lang) == null) {
        todo.add(s);
      } else {
        done++;
      }
    }
    onProgress?.call(done);
    for (var i = 0; i < todo.length; i += WikipediaClient.batchSize) {
      if (isCancelled?.call() ?? false) return;
      final batch = todo.sublist(
        i,
        (i + WikipediaClient.batchSize).clamp(0, todo.length),
      );
      final texts = await _wiki.intros(lang, [for (final s in batch) s.title]);
      await _db.transaction(() async {
        for (final s in batch) {
          final t = texts[s.title];
          if (t != null) await _store(s.scientificName, lang, s.title, t);
        }
      });
      done += batch.length;
      onProgress?.call(done);
      await Future<void>.delayed(pause); // be polite to Wikipedia
    }
  }

  Future<int> createPack({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required List<GuideLanguage> languages,
    required bool withPhotos,
    required List<EncyclopediaSpecies> species,
  }) => _db.transaction(() async {
    final id = await _db
        .into(_db.encyclopediaPacks)
        .insert(
          EncyclopediaPacksCompanion.insert(
            name: name,
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
            languages: languages.map((l) => l.name).join(','),
            withPhotos: Value(withPhotos),
            createdAt: DateTime.now(),
          ),
        );
    await _db.batch((b) {
      b.insertAll(_db.encyclopediaPackSpecies, [
        for (final s in species)
          EncyclopediaPackSpeciesCompanion.insert(
            packId: id,
            scientificName: s.scientificName,
            commonName: s.commonName,
          ),
      ]);
    });
    return id;
  });

  /// The species saved with pack [id], A–Z by common name.
  Future<List<EncyclopediaSpecies>> packSpecies(int id) async {
    final rows =
        await (_db.select(_db.encyclopediaPackSpecies)
              ..where((s) => s.packId.equals(id))
              ..orderBy([(s) => OrderingTerm.asc(s.commonName)]))
            .get();
    return [
      for (final r in rows)
        EncyclopediaSpecies(
          scientificName: r.scientificName,
          commonName: r.commonName,
        ),
    ];
  }

  Future<void> deletePack(int id) =>
      (_db.delete(_db.encyclopediaPacks)..where((p) => p.id.equals(id))).go();

  Stream<List<EncyclopediaPack>> watchPacks() {
    final count = _db.encyclopediaPackSpecies.scientificName.count();
    final q =
        _db.select(_db.encyclopediaPacks).join([
            leftOuterJoin(
              _db.encyclopediaPackSpecies,
              _db.encyclopediaPackSpecies.packId.equalsExp(
                _db.encyclopediaPacks.id,
              ),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.encyclopediaPacks.id])
          ..orderBy([OrderingTerm.desc(_db.encyclopediaPacks.createdAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          () {
            final p = r.readTable(_db.encyclopediaPacks);
            return EncyclopediaPack(
              id: p.id,
              name: p.name,
              latitude: p.latitude,
              longitude: p.longitude,
              radiusKm: p.radiusKm,
              languages: [
                for (final code in p.languages.split(','))
                  if (code.isNotEmpty) GuideLanguage.values.byName(code),
              ],
              withPhotos: p.withPhotos,
              speciesCount: r.read(count) ?? 0,
              createdAt: p.createdAt,
            );
          }(),
      ],
    );
  }

  /// All species across downloaded packs, de-duplicated, A–Z.
  Stream<List<EncyclopediaSpecies>> watchEncyclopediaSpecies() {
    final q = _db.selectOnly(_db.encyclopediaPackSpecies, distinct: true)
      ..addColumns([
        _db.encyclopediaPackSpecies.scientificName,
        _db.encyclopediaPackSpecies.commonName,
      ])
      ..orderBy([OrderingTerm.asc(_db.encyclopediaPackSpecies.commonName)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          EncyclopediaSpecies(
            scientificName: r.read(_db.encyclopediaPackSpecies.scientificName)!,
            commonName: r.read(_db.encyclopediaPackSpecies.commonName)!,
          ),
      ],
    );
  }
}
