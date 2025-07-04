class CatalogFilter {
  final Set<String> regions;
  final Set<String> languages;
  final Set<String> categories;
  final Set<String> mediaTypes;
  final Set<String> publishers;
  final Set<String> series;
  final bool showGoodDumps;
  final bool showBadDumps;
  final bool showOverdumps;
  final bool showHacks;
  final bool showTranslations;
  final bool showAlternates;
  final bool showFixed;
  final bool showTrainer;
  final bool showUnlicensed;
  final bool showDemos;
  final bool showSamples;
  final bool showProtos;
  final bool showBetas;
  final bool showAlphas;
  final bool showEnhanced;
  final bool showSpecialEditions;
  final bool showAftermarket;
  final bool showPirate;
  final bool showMultiCart;
  final bool showCollections;
  final bool showSinglePlayer;
  final bool showMultiplayer;
  final bool showCooperative;
  final bool showNTSC;
  final bool showPAL;
  final String versionFilter;
  final int? minYear;
  final int? maxYear;

  const CatalogFilter({
    this.regions = const {},
    this.languages = const {},
    this.categories = const {},
    this.mediaTypes = const {},
    this.publishers = const {},
    this.series = const {},
    this.showGoodDumps = true,
    this.showBadDumps = false,
    this.showOverdumps = false,
    this.showHacks = false,
    this.showTranslations = false,
    this.showAlternates = false,
    this.showFixed = false,
    this.showTrainer = false,
    this.showUnlicensed = false,
    this.showDemos = false,
    this.showSamples = false,
    this.showProtos = false,
    this.showBetas = false,
    this.showAlphas = false,
    this.showEnhanced = true,
    this.showSpecialEditions = true,
    this.showAftermarket = false,
    this.showPirate = false,
    this.showMultiCart = true,
    this.showCollections = true,
    this.showSinglePlayer = true,
    this.showMultiplayer = true,
    this.showCooperative = true,
    this.showNTSC = true,
    this.showPAL = true,
    this.versionFilter = '',
    this.minYear,
    this.maxYear,
  });

  CatalogFilter copyWith({
    Set<String>? regions,
    Set<String>? languages,
    Set<String>? categories,
    Set<String>? mediaTypes,
    Set<String>? publishers,
    Set<String>? series,
    bool? showGoodDumps,
    bool? showBadDumps,
    bool? showOverdumps,
    bool? showHacks,
    bool? showTranslations,
    bool? showAlternates,
    bool? showFixed,
    bool? showTrainer,
    bool? showUnlicensed,
    bool? showDemos,
    bool? showSamples,
    bool? showProtos,
    bool? showBetas,
    bool? showAlphas,
    bool? showEnhanced,
    bool? showSpecialEditions,
    bool? showAftermarket,
    bool? showPirate,
    bool? showMultiCart,
    bool? showCollections,
    bool? showSinglePlayer,
    bool? showMultiplayer,
    bool? showCooperative,
    bool? showNTSC,
    bool? showPAL,
    String? versionFilter,
    int? minYear,
    int? maxYear,
  }) {
    return CatalogFilter(
      regions: regions ?? this.regions,
      languages: languages ?? this.languages,
      categories: categories ?? this.categories,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      publishers: publishers ?? this.publishers,
      series: series ?? this.series,
      showGoodDumps: showGoodDumps ?? this.showGoodDumps,
      showBadDumps: showBadDumps ?? this.showBadDumps,
      showOverdumps: showOverdumps ?? this.showOverdumps,
      showHacks: showHacks ?? this.showHacks,
      showTranslations: showTranslations ?? this.showTranslations,
      showAlternates: showAlternates ?? this.showAlternates,
      showFixed: showFixed ?? this.showFixed,
      showTrainer: showTrainer ?? this.showTrainer,
      showUnlicensed: showUnlicensed ?? this.showUnlicensed,
      showDemos: showDemos ?? this.showDemos,
      showSamples: showSamples ?? this.showSamples,
      showProtos: showProtos ?? this.showProtos,
      showBetas: showBetas ?? this.showBetas,
      showAlphas: showAlphas ?? this.showAlphas,
      showEnhanced: showEnhanced ?? this.showEnhanced,
      showSpecialEditions: showSpecialEditions ?? this.showSpecialEditions,
      showAftermarket: showAftermarket ?? this.showAftermarket,
      showPirate: showPirate ?? this.showPirate,
      showMultiCart: showMultiCart ?? this.showMultiCart,
      showCollections: showCollections ?? this.showCollections,
      showSinglePlayer: showSinglePlayer ?? this.showSinglePlayer,
      showMultiplayer: showMultiplayer ?? this.showMultiplayer,
      showCooperative: showCooperative ?? this.showCooperative,
      showNTSC: showNTSC ?? this.showNTSC,
      showPAL: showPAL ?? this.showPAL,
      versionFilter: versionFilter ?? this.versionFilter,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
    );
  }

  bool get isActive {
    return regions.isNotEmpty ||
        languages.isNotEmpty ||
        categories.isNotEmpty ||
        mediaTypes.isNotEmpty ||
        publishers.isNotEmpty ||
        series.isNotEmpty ||
        !showGoodDumps ||
        showBadDumps ||
        showOverdumps ||
        showHacks ||
        showTranslations ||
        showAlternates ||
        showFixed ||
        showTrainer ||
        showUnlicensed ||
        showDemos ||
        showSamples ||
        showProtos ||
        showBetas ||
        showAlphas ||
        !showEnhanced ||
        !showSpecialEditions ||
        showAftermarket ||
        showPirate ||
        !showMultiCart ||
        !showCollections ||
        !showSinglePlayer ||
        !showMultiplayer ||
        !showCooperative ||
        !showNTSC ||
        !showPAL ||
        versionFilter.isNotEmpty ||
        minYear != null ||
        maxYear != null;
  }
}
