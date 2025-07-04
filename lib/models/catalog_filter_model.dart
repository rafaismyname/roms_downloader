class CatalogFilter {
  final Set<String> regions;
  final Set<String> languages;
  final Set<String> categories;
  final Set<String> mediaTypes;
  final Set<String> publishers;
  final Set<String> series;

  final Set<String> allowedDumpQualities;
  final Set<String> allowedRomTypes;
  final Set<String> allowedModifications;
  final Set<String> allowedDistributionTypes;

  final String versionFilter;
  final int? minYear;
  final int? maxYear;

  const CatalogFilter({
    this.regions = const {'World', 'USA'},
    this.languages = const {},
    this.categories = const {},
    this.mediaTypes = const {},
    this.publishers = const {},
    this.series = const {},
    this.allowedDumpQualities = const {'goodDump'},
    this.allowedRomTypes = const {'normal'},
    this.allowedModifications = const {'none'},
    this.allowedDistributionTypes = const {'standard', 'enhanced', 'specialEdition', 'multiCart'},
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
    Set<String>? allowedDumpQualities,
    Set<String>? allowedRomTypes,
    Set<String>? allowedModifications,
    Set<String>? allowedDistributionTypes,
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
      allowedDumpQualities: allowedDumpQualities ?? this.allowedDumpQualities,
      allowedRomTypes: allowedRomTypes ?? this.allowedRomTypes,
      allowedModifications: allowedModifications ?? this.allowedModifications,
      allowedDistributionTypes: allowedDistributionTypes ?? this.allowedDistributionTypes,
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
        allowedDumpQualities.isNotEmpty ||
        allowedRomTypes.isNotEmpty ||
        allowedModifications.isNotEmpty ||
        allowedDistributionTypes.isNotEmpty ||
        versionFilter.isNotEmpty ||
        minYear != null ||
        maxYear != null;
  }
}
