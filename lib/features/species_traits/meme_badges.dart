import '../../services/species_guide/species_guide.dart';
import '../progress/rarity.dart';

/// A fun "personality" badge for a species, decided by facts about it.
/// The stickers were generated with Google Flow for BirdQuest.
enum MemeBadge {
  speedDemon(
    en: 'Speed demon',
    ru: 'Скоростной демон',
    whyEn: 'Flies at 100 km/h or faster.',
    whyRu: 'Летает со скоростью 100 км/ч и больше.',
  ),
  nightShift(
    en: 'Night shift',
    ru: 'Сова не спит',
    whyEn: 'Active at night: owls and nightjars.',
    whyRu: 'Ночная птица: совы и козодои.',
  ),
  bigBrain(
    en: 'Big brain',
    ru: 'Мозг вороны',
    whyEn: 'Crows and their kin are among the smartest birds.',
    whyRu: 'Врановые — одни из самых умных птиц.',
  ),
  citySlicker(
    en: 'City slicker',
    ru: 'Городской пацан',
    whyEn: 'Thrives in towns, right next to people.',
    whyRu: 'Отлично живёт в городе, рядом с людьми.',
  ),
  localLegend(
    en: 'Local legend',
    ru: 'Легенда района',
    whyEn: 'Rare or not expected in your region.',
    whyRu: 'Редкий или неожиданный гость в вашем регионе.',
  ),
  grounded(
    en: 'Grounded',
    ru: 'Не летает, но старается',
    whyEn: 'A flightless bird.',
    whyRu: 'Нелетающая птица.',
  ),
  goneFishing(
    en: 'Gone fishing',
    ru: 'Рыбак',
    whyEn: 'Catches fish for a living.',
    whyRu: 'Ловит рыбу — это её работа.',
  ),
  drummer(
    en: 'Drummer',
    ru: 'Барабанщик',
    whyEn: 'Woodpeckers drum on trees to talk.',
    whyRu: 'Дятлы общаются барабанной дробью по деревьям.',
  ),
  partyAnimal(
    en: 'Party animal',
    ru: 'Тусовщик',
    whyEn: 'Lives in big, noisy flocks.',
    whyRu: 'Живёт большими шумными стаями.',
  ),
  earlyBird(
    en: 'Early bird',
    ru: 'Ранняя пташка',
    whyEn: 'You mostly heard it before 7 am.',
    whyRu: 'Вы чаще слышали её до 7 утра.',
  ),
  hoverMode(
    en: 'Hover mode',
    ru: 'Режим вертолёта',
    whyEn: 'Hummingbirds can hover and even fly backwards.',
    whyRu: 'Колибри зависают в воздухе и летают задом наперёд.',
  ),
  pirate(
    en: 'Pirate',
    ru: 'Пират',
    whyEn: 'Steals food from other birds in flight.',
    whyRu: 'Отбирает добычу у других птиц прямо в полёте.',
  ),
  hooligan(
    en: 'Hooligan',
    ru: 'Хулиган',
    whyEn: 'Gulls will snatch your chips.',
    whyRu: 'Чайка может утащить еду прямо из рук.',
  ),
  mimic(
    en: 'Mimic',
    ru: 'Пародист',
    whyEn: 'Copies the songs of other birds and sounds.',
    whyRu: 'Копирует голоса других птиц и звуки.',
  ),
  dramaQueen(
    en: 'Drama queen',
    ru: 'Звезда сцены',
    whyEn: 'Famous for showy courtship displays.',
    whyRu: 'Знаменита эффектными брачными танцами.',
  ),
  marathoner(
    en: 'Marathoner',
    ru: 'Марафонец',
    whyEn: 'One of the record long-distance migrants.',
    whyRu: 'Один из рекордсменов дальних перелётов.',
  ),
  broodParasite(
    en: 'Brood parasite',
    ru: 'Подкидыш',
    whyEn: 'Many cuckoos lay eggs in other birds’ nests.',
    whyRu: 'Многие кукушки подкладывают яйца в чужие гнёзда.',
  );

  const MemeBadge({
    required this.en,
    required this.ru,
    required this.whyEn,
    required this.whyRu,
  });

  final String en;
  final String ru;
  final String whyEn;
  final String whyRu;

  String title(GuideLanguage lang) => lang == GuideLanguage.ru ? ru : en;
  String why(GuideLanguage lang) => lang == GuideLanguage.ru ? whyRu : whyEn;

  /// Sticker asset.
  String get asset => 'assets/memes/${_snake(name)}.webp';

  static String _snake(String s) =>
      s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

const _night = {
  'Strigidae', 'Tytonidae', 'Caprimulgidae', 'Podargidae', 'Nyctibiidae', //
  'Aegothelidae', 'Steatornithidae',
};
const _flightless = {
  'Spheniscidae', 'Struthionidae', 'Rheidae', 'Casuariidae', 'Dromaiidae', //
  'Apterygidae',
};
const _fishers = {
  'Alcedinidae', 'Ardeidae', 'Pandionidae', 'Phalacrocoracidae', //
  'Pelecanidae', 'Anhingidae',
};
const _flocks = {'Sturnidae', 'Ploceidae', 'Estrildidae'};
const _pirates = {'Stercorariidae', 'Fregatidae'};
const _mimics = {'Mimidae', 'Menuridae'};
const _showy = {'Paradisaeidae', 'Pipridae'};

/// Synanthropes: birds that do best around people.
const _city = {
  'Columba livia', 'Passer domesticus', 'Passer montanus', //
  'Acridotheres tristis', 'Corvus splendens', 'Pica pica', 'Corvus cornix',
  'Corvus corone', 'Hirundo rustica', 'Delichon urbicum', 'Apus apus',
  'Streptopelia chinensis', 'Streptopelia decaocto', 'Sturnus vulgaris',
  'Spilopelia chinensis', 'Pycnonotus jocosus',
};

/// Record long-distance migrants.
const _marathon = {
  'Sterna paradisaea', 'Limosa lapponica', 'Ardenna grisea', //
  'Hirundo rustica', 'Apus apus', 'Calidris canutus', 'Oenanthe oenanthe',
};

/// Up to [max] badges for a species, most telling first. [dawnShare] is
/// the share of the user's own sightings of it before 7 am (null when they
/// have fewer than two).
List<MemeBadge> memeBadgesFor({
  required String scientificName,
  String? family,
  GuideSpeed? speed,
  Rarity? rarity,
  double? dawnShare,
  int max = 2,
}) {
  final genus = SpeciesGuide.genusOf(scientificName);
  final all = <MemeBadge>[
    if (rarity == Rarity.legendary) MemeBadge.localLegend,
    if ((speed?.top ?? 0) >= 100) MemeBadge.speedDemon,
    if (_flightless.contains(family)) MemeBadge.grounded,
    if (_night.contains(family)) MemeBadge.nightShift,
    if (family == 'Trochilidae') MemeBadge.hoverMode,
    if (family == 'Corvidae') MemeBadge.bigBrain,
    if (family == 'Picidae') MemeBadge.drummer,
    if (_pirates.contains(family)) MemeBadge.pirate,
    if (family == 'Laridae' && genus == 'Larus' ||
        family == 'Laridae' && genus == 'Chroicocephalus')
      MemeBadge.hooligan,
    if (family == 'Cuculidae') MemeBadge.broodParasite,
    if (_mimics.contains(family)) MemeBadge.mimic,
    if (_showy.contains(family) || genus == 'Pavo') MemeBadge.dramaQueen,
    if (_marathon.contains(scientificName)) MemeBadge.marathoner,
    if (_fishers.contains(family)) MemeBadge.goneFishing,
    if (dawnShare != null && dawnShare >= 0.5) MemeBadge.earlyBird,
    if (_city.contains(scientificName)) MemeBadge.citySlicker,
    if (_flocks.contains(family)) MemeBadge.partyAnimal,
    if (rarity == Rarity.rare) MemeBadge.localLegend,
  ];
  final out = <MemeBadge>[];
  for (final b in all) {
    if (!out.contains(b)) out.add(b);
    if (out.length == max) break;
  }
  return out;
}
