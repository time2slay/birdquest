import 'package:birdquest/services/species_guide/similar_species.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:birdquest/shared/widgets/species_extras.dart';
import 'package:flutter_test/flutter_test.dart';

GuideEntry _e(String fam) => GuideEntry(texts: const {}, family: fam);

final _guide = SpeciesGuide({
  'Turdus merula': _e('Turdidae'),
  'Turdus philomelos': _e('Turdidae'),
  'Turdus pilaris': _e('Turdidae'),
  'Turdus migratorius': _e('Turdidae'),
  'Zoothera dauma': _e('Turdidae'),
  'Erithacus rubecula': _e('Muscicapidae'),
  'Sturnus vulgaris': _e('Sturnidae'),
});

List<String> _names(List<SimilarSpecies> l) => [
  for (final s in l) s.scientificName,
];

void main() {
  test('genus first, then family, then order; never the bird itself', () {
    final similar = similarSpecies(
      'Turdus merula',
      _guide,
      orderOf: const {
        'Turdus merula': 'Passeriformes',
        'Sturnus vulgaris': 'Passeriformes',
      },
    );
    expect(_names(similar).take(3).toSet(), {
      'Turdus philomelos',
      'Turdus pilaris',
      'Turdus migratorius',
    });
    expect(similar[3].scientificName, 'Zoothera dauma');
    expect(similar[3].kinship, Kinship.family);
    expect(similar.last.scientificName, 'Sturnus vulgaris');
    expect(similar.last.kinship, Kinship.order);
    expect(_names(similar), isNot(contains('Turdus merula')));
  });

  test('local and collected look-alikes come first within a tier', () {
    final similar = similarSpecies(
      'Turdus merula',
      _guide,
      regional: const {'Turdus pilaris', 'Turdus philomelos'},
      collected: const {'Turdus philomelos', 'Turdus migratorius'},
    );
    expect(_names(similar).take(3).toList(), [
      'Turdus philomelos', // regional + collected
      'Turdus pilaris', // regional
      'Turdus migratorius', // collected
    ]);
  });

  test('respects the limit', () {
    expect(similarSpecies('Turdus merula', _guide, limit: 2), hasLength(2));
  });

  test('flight speed wording', () {
    const peregrine = GuideSpeed(
      horizontal: 160,
      dive: 389,
      source: SpeedSource.species,
    );
    expect(
      speedText(peregrine, ru: false),
      'up to 160 km/h in flight · up to 389 km/h in a dive',
    );
    expect(
      speedText(peregrine, ru: true),
      'до 160 км/ч в полёте · в пике до 389 км/ч',
    );
    const family = GuideSpeed(horizontal: 87, source: SpeedSource.family);
    expect(
      speedText(family, ru: false),
      'up to ~87 km/h · typical of its family',
    );
  });
}
