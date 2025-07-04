import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';

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
        if (!titleMatch && !originalMatch) return false;
      }

      final metadata = game.metadata;
      if (metadata == null) return true;

      if (filter.regions.isNotEmpty && !filter.regions.any((region) => metadata.regions.contains(region) || metadata.regions.isEmpty)) {
        return false;
      }

      if (filter.languages.isNotEmpty && !filter.languages.any((language) => metadata.languages.contains(language) || metadata.languages.isEmpty)) {
        return false;
      }

      if (filter.categories.isNotEmpty && !filter.categories.any((category) => metadata.categories.contains(category))) {
        return false;
      }

      if (filter.mediaTypes.isNotEmpty && !filter.mediaTypes.contains(metadata.mediaType)) {
        return false;
      }

      if (filter.dumpQualities.isNotEmpty) {
        if (metadata.dumpQualities.isEmpty) {
          if (!filter.dumpQualities.contains('goodDump')) return false;
        } else {
          final hasAllowedDumpQuality = metadata.dumpQualities.any((quality) => filter.dumpQualities.contains(quality.name));
          if (!hasAllowedDumpQuality) return false;
        }
      }

      if (filter.romTypes.isNotEmpty) {
        if (metadata.romTypes.isEmpty) {
          if (!filter.romTypes.contains('normal')) return false;
        } else {
          final hasAllowedRomType = metadata.romTypes.any((type) => filter.romTypes.contains(type.name));
          if (!hasAllowedRomType) return false;
        }
      }

      if (filter.modifications.isNotEmpty) {
        if (metadata.modifications.isEmpty) {
          if (!filter.modifications.contains('none')) return false;
        } else {
          final hasAllowedModification = metadata.modifications.any((mod) => filter.modifications.contains(mod.name));
          if (!hasAllowedModification) return false;
        }
      }

      if (filter.distributionTypes.isNotEmpty) {
        if (metadata.distributionTypes.isEmpty) {
          if (!filter.distributionTypes.contains('standard')) return false;
        } else {
          final hasAllowedDistribution = metadata.distributionTypes.any((dist) => filter.distributionTypes.contains(dist.name));
          if (!hasAllowedDistribution) return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aTitle = a.displayTitle.toLowerCase();
      final bTitle = b.displayTitle.toLowerCase();
      return aTitle.compareTo(bTitle);
    });

    return filtered;
  }

  List<Game> get paginatedFilteredGames {
    return filteredGames.take(displayedCount).toList();
  }

  bool get hasMoreItems {
    return displayedCount < filteredGames.length;
  }
}
