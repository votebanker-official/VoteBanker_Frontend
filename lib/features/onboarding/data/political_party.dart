/// One party in the leader-profile selector.
///
/// [representativeIcon] records the brief icon from the source list. The
/// dropdown draws [symbolAsset], not that icon.
class PartyOption {
  const PartyOption({
    required this.name,
    required this.abbreviation,
    required this.symbolName,
    required this.symbolAsset,
    required this.group,
    this.homeState,
    this.representativeIcon,
  });

  final String name;
  final String abbreviation;
  final String? homeState;
  final String symbolName;
  final String symbolAsset;
  final PartyGroup group;
  final String? representativeIcon;

  static const fallbackAsset = 'assets/images/parties/fallback.svg';

  static const national = <PartyOption>[
    PartyOption(
      name: 'Bharatiya Janata Party',
      abbreviation: 'BJP',
      symbolName: 'Lotus',
      symbolAsset: 'assets/images/parties/bjp.svg',
      group: PartyGroup.national,
      representativeIcon: '🪷',
    ),
    PartyOption(
      name: 'Indian National Congress',
      abbreviation: 'INC',
      symbolName: 'Hand',
      symbolAsset: 'assets/images/parties/inc.svg',
      group: PartyGroup.national,
      representativeIcon: '✋',
    ),
    PartyOption(
      name: 'Aam Aadmi Party',
      abbreviation: 'AAP',
      symbolName: 'Broom',
      symbolAsset: 'assets/images/parties/aap.png',
      group: PartyGroup.national,
      representativeIcon: '🧹',
    ),
    PartyOption(
      name: 'Bahujan Samaj Party',
      abbreviation: 'BSP',
      symbolName: 'Elephant',
      symbolAsset: 'assets/images/parties/bsp.png',
      group: PartyGroup.national,
      representativeIcon: '🐘',
    ),
    PartyOption(
      name: 'Communist Party of India (Marxist)',
      abbreviation: 'CPI(M)',
      symbolName: 'Hammer, Sickle and Star',
      symbolAsset: 'assets/images/parties/cpim.svg',
      group: PartyGroup.national,
      representativeIcon: '☭',
    ),
    PartyOption(
      name: 'National People\'s Party',
      abbreviation: 'NPP',
      symbolName: 'Book',
      symbolAsset: 'assets/images/parties/npp.svg',
      group: PartyGroup.national,
      representativeIcon: '📖',
    ),
  ];

  static const regional = <PartyOption>[
    PartyOption(
      name: 'Samajwadi Party',
      abbreviation: 'SP',
      homeState: 'Uttar Pradesh',
      symbolName: 'Bicycle',
      symbolAsset: 'assets/images/parties/sp.png',
      group: PartyGroup.regional,
      representativeIcon: '🚲',
    ),
    PartyOption(
      name: 'Dravida Munnetra Kazhagam',
      abbreviation: 'DMK',
      homeState: 'Tamil Nadu',
      symbolName: 'Rising Sun',
      symbolAsset: 'assets/images/parties/dmk.svg',
      group: PartyGroup.regional,
      representativeIcon: '🌅',
    ),
    PartyOption(
      name: 'All India Anna Dravida Munnetra Kazhagam',
      abbreviation: 'AIADMK',
      homeState: 'Tamil Nadu',
      symbolName: 'Two Leaves',
      symbolAsset: 'assets/images/parties/aiadmk.svg',
      group: PartyGroup.regional,
      representativeIcon: '🍃',
    ),
    PartyOption(
      name: 'Telugu Desam Party',
      abbreviation: 'TDP',
      homeState: 'Andhra Pradesh',
      symbolName: 'Bicycle',
      symbolAsset: 'assets/images/parties/tdp.png',
      group: PartyGroup.regional,
      representativeIcon: '🚲',
    ),
    PartyOption(
      name: 'Rashtriya Janata Dal',
      abbreviation: 'RJD',
      homeState: 'Bihar',
      symbolName: 'Hurricane Lamp',
      symbolAsset: 'assets/images/parties/rjd.png',
      group: PartyGroup.regional,
      representativeIcon: '🪔',
    ),
    PartyOption(
      name: 'Shiv Sena',
      abbreviation: 'SHS',
      homeState: 'Maharashtra',
      symbolName: 'Bow and Arrow',
      symbolAsset: 'assets/images/parties/shiv_sena.svg',
      group: PartyGroup.regional,
      representativeIcon: '🏹',
    ),
    PartyOption(
      name: 'Janata Dal (United)',
      abbreviation: 'JD(U)',
      homeState: 'Bihar',
      symbolName: 'Arrow',
      symbolAsset: 'assets/images/parties/jdu.svg',
      group: PartyGroup.regional,
      representativeIcon: '🏹',
    ),
    PartyOption(
      name: 'Biju Janata Dal',
      abbreviation: 'BJD',
      homeState: 'Odisha',
      symbolName: 'Conch',
      symbolAsset: 'assets/images/parties/bjd.svg',
      group: PartyGroup.regional,
      representativeIcon: '🐚',
    ),
    PartyOption(
      name: 'Shiromani Akali Dal',
      abbreviation: 'SAD',
      homeState: 'Punjab',
      symbolName: 'Weighing Scale',
      symbolAsset: 'assets/images/parties/sad.png',
      group: PartyGroup.regional,
      representativeIcon: '⚖️',
    ),
    PartyOption(
      name: 'Nationalist Congress Party',
      abbreviation: 'NCP',
      homeState: 'Maharashtra',
      symbolName: 'Clock',
      symbolAsset: 'assets/images/parties/ncp.png',
      group: PartyGroup.regional,
      representativeIcon: '⏱️',
    ),
    PartyOption(
      name: 'All India Trinamool Congress',
      abbreviation: 'AITC / TMC',
      homeState: 'West Bengal',
      symbolName: 'Flowers and Grass',
      symbolAsset: 'assets/images/parties/aitc.png',
      group: PartyGroup.regional,
      representativeIcon: '🪻',
    ),
    PartyOption(
      name: 'All India Majlis-e-Ittehadul Muslimeen',
      abbreviation: 'AIMIM',
      homeState: 'Telangana',
      symbolName: 'Kite',
      symbolAsset: 'assets/images/parties/aimim.png',
      group: PartyGroup.regional,
      representativeIcon: '🪁',
    ),
    PartyOption(
      name: 'Naam Tamilar Katchi',
      abbreviation: 'NTK',
      homeState: 'Tamil Nadu',
      symbolName: 'Farmer Carrying Plough',
      symbolAsset: 'assets/images/parties/ntk.png',
      group: PartyGroup.regional,
      representativeIcon: '🧑‍🌾',
    ),
    PartyOption(
      name: 'Indian National Lok Dal',
      abbreviation: 'INLD',
      homeState: 'Haryana',
      symbolName: 'Spectacles',
      symbolAsset: 'assets/images/parties/inld.png',
      group: PartyGroup.regional,
      representativeIcon: '👓',
    ),
  ];

  static const all = <PartyOption>[...national, ...regional];

  static List<String> get names => [for (final party in all) party.name];

  static PartyOption? findByName(String name) {
    for (final party in all) {
      if (party.name == name) return party;
    }
    return null;
  }

  static String symbolFor(String name) =>
      findByName(name)?.symbolAsset ?? fallbackAsset;

  /// Matches a full name or an abbreviation, including "TMC" inside "AITC / TMC".
  static List<PartyOption> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final party in all)
        if (party.name.toLowerCase().contains(q) ||
            party.abbreviation.toLowerCase().contains(q))
          party,
    ];
  }
}

enum PartyGroup { national, regional }
