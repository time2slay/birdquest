import 'package:birdquest/features/progress/rarity.dart';
import 'package:birdquest/features/species_traits/meme_badges.dart';
import 'package:birdquest/services/species_guide/species_guide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the peregrine is a speed demon, an owl works night shifts', () {
    expect(
      memeBadgesFor(
        scientificName: 'Falco peregrinus',
        family: 'Falconidae',
        speed: const GuideSpeed(
          horizontal: 160,
          dive: 389,
          source: SpeedSource.species,
        ),
      ),
      [MemeBadge.speedDemon],
    );
    expect(memeBadgesFor(scientificName: 'Bubo bubo', family: 'Strigidae'), [
      MemeBadge.nightShift,
    ]);
  });

  test('at most two, most telling first, without duplicates', () {
    final badges = memeBadgesFor(
      scientificName: 'Apus apus',
      family: 'Apodidae',
      speed: const GuideSpeed(horizontal: 112, source: SpeedSource.species),
      rarity: Rarity.rare,
    );
    expect(badges, [MemeBadge.speedDemon, MemeBadge.marathoner]);
    expect(
      memeBadgesFor(scientificName: 'Apus apus', family: 'Apodidae', max: 4),
      [MemeBadge.marathoner, MemeBadge.citySlicker],
    );
  });

  test('legendary visitors lead; rare ones come last', () {
    expect(
      memeBadgesFor(
        scientificName: 'Passer domesticus',
        family: 'Passeridae',
        rarity: Rarity.legendary,
      ).first,
      MemeBadge.localLegend,
    );
    expect(
      memeBadgesFor(
        scientificName: 'Pica pica',
        family: 'Corvidae',
        rarity: Rarity.rare,
      ),
      [MemeBadge.bigBrain, MemeBadge.citySlicker],
    );
  });

  test('early bird comes from the user’s own dawn sightings', () {
    expect(
      memeBadgesFor(
        scientificName: 'Erithacus rubecula',
        family: 'Muscicapidae',
        dawnShare: 0.6,
      ),
      [MemeBadge.earlyBird],
    );
    expect(
      memeBadgesFor(
        scientificName: 'Erithacus rubecula',
        family: 'Muscicapidae',
        dawnShare: 0.2,
      ),
      isEmpty,
    );
  });

  test('every badge has its sticker in the bundle', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    for (final b in MemeBadge.values) {
      expect(assets, contains(b.asset), reason: b.name);
    }
  });
}
