class CatalogFilter {
  final Set<String> regions;
  final Set<String> languages;
  final Set<String> categories;
  final Set<String> mediaTypes;
  final Set<String> dumpQualities;
  final Set<String> romTypes;
  final Set<String> modifications;
  final Set<String> distributionTypes;

  const CatalogFilter({
    this.regions = const {'USA'},
    this.languages = const {},
    this.categories = const {},
    this.mediaTypes = const {},
    this.dumpQualities = const {'goodDump'},
    this.romTypes = const {'normal'},
    this.modifications = const {'none'},
    this.distributionTypes = const {'standard', 'enhanced', 'specialEdition', 'multiCart'},
  });

  CatalogFilter copyWith({
    Set<String>? regions,
    Set<String>? languages,
    Set<String>? categories,
    Set<String>? mediaTypes,
    Set<String>? publishers,
    Set<String>? series,
    Set<String>? dumpQualities,
    Set<String>? romTypes,
    Set<String>? modifications,
    Set<String>? distributionTypes,
    String? version,
    int? minYear,
    int? maxYear,
  }) {
    return CatalogFilter(
      regions: regions ?? this.regions,
      languages: languages ?? this.languages,
      categories: categories ?? this.categories,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      dumpQualities: dumpQualities ?? this.dumpQualities,
      romTypes: romTypes ?? this.romTypes,
      modifications: modifications ?? this.modifications,
      distributionTypes: distributionTypes ?? this.distributionTypes,
    );
  }

  bool get isActive {
    return regions.isNotEmpty ||
        languages.isNotEmpty ||
        categories.isNotEmpty ||
        mediaTypes.isNotEmpty ||
        dumpQualities.isNotEmpty ||
        romTypes.isNotEmpty ||
        modifications.isNotEmpty ||
        distributionTypes.isNotEmpty;
  }
}
