import '../../data/models.dart';

/// Short original field-guide notes for common species. Species without a
/// note show a "no description yet" message.
const fieldGuideSpecies = [
  SpeciesInfo(
    scientificName: 'Turdus merula',
    commonName: 'Common Blackbird',
    taxonOrder: 'Passeriformes',
    description:
        'A thrush of gardens and woodland edges. Males are glossy black '
        'with an orange bill; the fluting, unhurried song carries far at '
        'dawn and dusk.',
  ),
  SpeciesInfo(
    scientificName: 'Erithacus rubecula',
    commonName: 'European Robin',
    taxonOrder: 'Passeriformes',
    description:
        'A small, round chat with an orange-red face and breast. Sings '
        'a wistful, liquid warble through most of the year, even at night '
        'near street lights.',
  ),
  SpeciesInfo(
    scientificName: 'Cyanistes caeruleus',
    commonName: 'Eurasian Blue Tit',
    taxonOrder: 'Passeriformes',
    description:
        'A lively blue-and-yellow tit that often hangs upside down while '
        'feeding. Its call is a bright "tsee-tsee-chu-chu-chu".',
  ),
  SpeciesInfo(
    scientificName: 'Alcedo atthis',
    commonName: 'Common Kingfisher',
    taxonOrder: 'Coraciiformes',
    description:
        'A dazzling turquoise-and-orange bird of slow rivers. Usually '
        'noticed first by its shrill, whistled "tsiii" as it flashes past '
        'low over the water.',
  ),
  SpeciesInfo(
    scientificName: 'Fringilla coelebs',
    commonName: 'Common Chaffinch',
    taxonOrder: 'Passeriformes',
    description:
        'A finch with bold white wing bars. Its cheerful descending song '
        'ends in a flourish, like a bowler running up to bowl.',
  ),
];
final _bySci = {for (final s in fieldGuideSpecies) s.scientificName: s};

String? fieldNoteFor(String scientificName) =>
    _bySci[scientificName]?.description;
