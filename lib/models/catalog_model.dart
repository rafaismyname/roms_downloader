import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/catalog_filter.dart';

const int kDefaultCatalogDisplaySize = 20;

class CatalogState {
  final List<Game> games;
  final String filterText;
  final bool loading;
  final Set<String> selectedGames;
  final int displayedCount;
  final CatalogFilter filter;
  final Set<String> availableRegions;
  final Set<String> availableLanguages;

  final Set<String> availableCategories;
  final Set<String> availableMediaTypes;
  final Set<String> availablePublishers;
  final Set<String> availableSeries;

  const CatalogState({
    this.games = const [],
    this.filterText = '',
    this.loading = false,
    this.selectedGames = const {},
    this.displayedCount = 20,
    this.filter = const CatalogFilter(),
    this.availableRegions = const {},
    this.availableLanguages = const {},
    this.availableCategories = const {},
    this.availableMediaTypes = const {},
    this.availablePublishers = const {},
    this.availableSeries = const {},
  });

  CatalogState copyWith({
    List<Game>? games,
    String? filterText,
    bool? loading,
    Set<String>? selectedGames,
    int? displayedCount,
    CatalogFilter? filter,
    Set<String>? availableRegions,
    Set<String>? availableLanguages,
    Set<String>? availableCategories,
    Set<String>? availableMediaTypes,
    Set<String>? availablePublishers,
    Set<String>? availableSeries,
  }) {
    return CatalogState(
      games: games ?? this.games,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      selectedGames: selectedGames ?? this.selectedGames,
      displayedCount: displayedCount ?? this.displayedCount,
      filter: filter ?? this.filter,
      availableRegions: availableRegions ?? this.availableRegions,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      availableCategories: availableCategories ?? this.availableCategories,
      availableMediaTypes: availableMediaTypes ?? this.availableMediaTypes,
      availablePublishers: availablePublishers ?? this.availablePublishers,
      availableSeries: availableSeries ?? this.availableSeries,
    );
  }

  List<Game> get filteredGames {
    var filtered = games.where((game) {
      if (filterText.isNotEmpty) {
        final titleMatch = game.displayTitle.toLowerCase().contains(filterText.toLowerCase());
        final originalMatch = game.title.toLowerCase().contains(filterText.toLowerCase());
        final seriesMatch = game.metadata?.series.toLowerCase().contains(filterText.toLowerCase()) ?? false;
        final publisherMatch = game.metadata?.publisher.toLowerCase().contains(filterText.toLowerCase()) ?? false;
        if (!titleMatch && !originalMatch && !seriesMatch && !publisherMatch) return false;
      }

      final metadata = game.metadata;
      if (metadata == null) return true;

      if (filter.regions.isNotEmpty && !filter.regions.any((region) => 
        metadata.regions.contains(region) || metadata.region == region)) {
        return false;
      }

      if (filter.languages.isNotEmpty && !filter.languages.any((language) => 
        metadata.languages.contains(language) || metadata.language == language)) {
        return false;
      }

      if (filter.categories.isNotEmpty && !filter.categories.any((category) =>
        metadata.categories.contains(category))) {
        return false;
      }

      if (filter.mediaTypes.isNotEmpty && !filter.mediaTypes.contains(metadata.mediaType)) {
        return false;
      }

      if (filter.publishers.isNotEmpty && !filter.publishers.contains(metadata.publisher)) {
        return false;
      }

      if (filter.series.isNotEmpty && !filter.series.contains(metadata.series)) {
        return false;
      }

      if (filter.versionFilter.isNotEmpty && !metadata.version.contains(filter.versionFilter)) {
        return false;
      }

      if (filter.minYear != null || filter.maxYear != null) {
        final releaseYear = _extractYear(metadata.releaseDate);
        if (releaseYear != null) {
          if (filter.minYear != null && releaseYear < filter.minYear!) return false;
          if (filter.maxYear != null && releaseYear > filter.maxYear!) return false;
        }
      }

      if (!filter.showGoodDumps && metadata.isGoodDump) return false;
      if (!filter.showBadDumps && metadata.isBadDump) return false;
      if (!filter.showOverdumps && metadata.isOverdump) return false;
      if (!filter.showHacks && metadata.isHack) return false;
      if (!filter.showTranslations && metadata.isTranslation) return false;
      if (!filter.showAlternates && metadata.isAlternate) return false;
      if (!filter.showFixed && metadata.isFixed) return false;
      if (!filter.showTrainer && metadata.isTrainer) return false;
      if (!filter.showUnlicensed && metadata.isUnlicensed) return false;
      if (!filter.showDemos && metadata.isDemo) return false;
      if (!filter.showSamples && metadata.isSample) return false;
      if (!filter.showProtos && metadata.isProto) return false;
      if (!filter.showBetas && metadata.isBeta) return false;
      if (!filter.showAlphas && metadata.isAlpha) return false;
      if (!filter.showEnhanced && metadata.isEnhanced) return false;
      if (!filter.showSpecialEditions && metadata.isSpecialEdition) return false;
      if (!filter.showAftermarket && metadata.isAftermarket) return false;
      if (!filter.showPirate && metadata.isPirate) return false;
      if (!filter.showMultiCart && metadata.isMultiCart) return false;
      if (!filter.showCollections && metadata.collection.isNotEmpty) return false;

      if (!filter.showSinglePlayer && metadata.categories.any((cat) => cat.contains('1 Player'))) return false;
      if (!filter.showMultiplayer && metadata.categories.any((cat) => cat.contains('Player') && !cat.contains('1 Player'))) return false;
      if (!filter.showCooperative && metadata.categories.contains('Cooperative')) return false;
      if (!filter.showNTSC && metadata.categories.contains('NTSC')) return false;
      if (!filter.showPAL && metadata.categories.contains('PAL')) return false;

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aTitle = a.displayTitle.toLowerCase();
      final bTitle = b.displayTitle.toLowerCase();
      return aTitle.compareTo(bTitle);
    });

    return filtered;
  }

  int? _extractYear(String releaseDate) {
    if (releaseDate.isEmpty) return null;
    final yearMatch = RegExp(r'(\d{4})').firstMatch(releaseDate);
    return yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;
  }

  List<Game> get paginatedFilteredGames {
    return filteredGames.take(displayedCount).toList();
  }

  bool get hasMoreItems {
    return displayedCount < filteredGames.length;
  }
}
