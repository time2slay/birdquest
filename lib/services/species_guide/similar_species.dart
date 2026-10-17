import 'species_guide.dart';

/// How a similar species relates to the one being viewed.
enum Kinship { genus, family, order }

class SimilarSpecies {
  const SimilarSpecies(this.scientificName, this.kinship);
  final String scientificName;
  final Kinship kinship;
}

/// Species that are easy to confuse with [scientificName]: the same genus
/// first, then the same family, then the same order. Within each tier birds
/// of the user's region ([regional]) and ones already [collected] come
/// first, so the suggestions are the look-alikes that matter here.
///
/// [orderOf] maps scientific names to their order (from the region profile
/// or the model labels); order-level matches are only taken from it.
List<SimilarSpecies> similarSpecies(
  String scientificName,
  SpeciesGuide guide, {
  Set<String> regional = const {},
  Set<String> collected = const {},
  Map<String, String> orderOf = const {},
  int limit = 6,
}) {
  final seen = {scientificName};
  final out = <SimilarSpecies>[];

  int rank(String s) =>
      (regional.contains(s) ? 0 : 2) + (collected.contains(s) ? 0 : 1);

  void take(Iterable<String> candidates, Kinship kinship) {
    final fresh = candidates.where(seen.add).toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });
    for (final s in fresh) {
      if (out.length >= limit) return;
      out.add(SimilarSpecies(s, kinship));
    }
  }

  final genus = SpeciesGuide.genusOf(scientificName);
  if (genus != null) take(guide.genusMembers(genus), Kinship.genus);
  final family = guide[scientificName]?.family;
  if (family != null && out.length < limit) {
    take(guide.familyMembers(family), Kinship.family);
  }
  final order = orderOf[scientificName];
  if (order != null && out.length < limit) {
    take(
      orderOf.entries.where((e) => e.value == order).map((e) => e.key),
      Kinship.order,
    );
  }
  return out;
}
