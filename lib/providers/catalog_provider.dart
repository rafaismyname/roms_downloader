import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/filtering_service.dart';

final gameSelectionProvider = Provider.family<bool, String>((ref, gameId) {
  final catalogState = ref.watch(catalogProvider);
  return catalogState.selectedGames.contains(gameId);
});

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final catalogService = CatalogService();
  return CatalogNotifier(catalogService);
});

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService catalogService;

  bool _loadingMore = false;

  CatalogNotifier(this.catalogService) : super(const CatalogState());

  Future<void> loadCatalog(Console console) async {
    if (state.loading) return;

    state = state.copyWith(
      loading: true,
      games: [],
      selectedGames: {},
      filter: const CatalogFilter(),
    );

    try {
      final games = await catalogService.loadCatalog(console.id);

      Set<String> regions = <String>{};
      Set<String> languages = <String>{};
      Set<String> categories = <String>{};

      for (final game in games) {
        if (game.metadata != null) {
          if (game.metadata!.regions.isNotEmpty) {
            regions.addAll(game.metadata!.regions);
          }
          if (game.metadata!.languages.isNotEmpty) {
            languages.addAll(game.metadata!.languages);
          }
          if (game.metadata!.categories.isNotEmpty) {
            categories.addAll(game.metadata!.categories);
          }
        }
      }

      state = state.copyWith(
        games: games,
        loading: false,
        availableRegions: regions,
        availableLanguages: languages,
        availableCategories: categories,
      );

      await _updateFilteredGames();
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      state = state.copyWith(
        loading: false,
        games: [],
      );
    }
  }

  Future<void> _updateFilteredGames() async {
    if (state.games.isEmpty) return;

    try {
      final result = await compute(
          FilteringService.filterAndPaginate,
          FilterInput(
            games: state.games,
            filterText: state.filterText,
            filter: state.filter,
            skip: 0,
            limit: kDefaultCatalogDisplaySize,
          ));

      state = state.copyWith(
        cachedFilteredGames: result.games,
        cachedTotalCount: result.totalCount,
        cachedHasMore: result.hasMore,
      );
    } catch (e) {
      debugPrint('Error filtering games: $e');
    }
  }

  void updateFilterText(String filter) async {
    state = state.copyWith(filterText: filter);
    await _updateFilteredGames();
  }

  void loadMoreItems() async {
    if (_loadingMore || !state.hasMoreItems) return;

    _loadingMore = true;
    state = state.copyWith(loadingMore: true);

    try {
      final result = await compute(
          FilteringService.filterAndPaginate,
          FilterInput(
            games: state.games,
            filterText: state.filterText,
            filter: state.filter,
            skip: state.paginatedFilteredGames.length,
            limit: kDefaultCatalogDisplaySize,
          ));

      state = state.copyWith(
        cachedFilteredGames: [...state.paginatedFilteredGames, ...result.games],
        cachedTotalCount: result.totalCount,
        cachedHasMore: result.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      _loadingMore = false;
      state = state.copyWith(loadingMore: false);
    }
  }

  void toggleGameSelection(String gameId) {
    final selectedGames = Set<String>.from(state.selectedGames);

    if (selectedGames.contains(gameId)) {
      selectedGames.remove(gameId);
    } else {
      selectedGames.add(gameId);
    }

    state = state.copyWith(selectedGames: selectedGames);
  }

  void selectGame(String gameId) {
    final selectedGames = Set<String>.from(state.selectedGames);
    selectedGames.add(gameId);
    state = state.copyWith(selectedGames: selectedGames);
  }

  void deselectGame(String gameId) {
    final selectedGames = Set<String>.from(state.selectedGames);
    selectedGames.remove(gameId);
    state = state.copyWith(selectedGames: selectedGames);
  }

  void updateFilter(CatalogFilter filter) async {
    state = state.copyWith(filter: filter);
    await _updateFilteredGames();
  }

  void toggleRegionFilter(String region) async {
    final regions = Set<String>.from(state.filter.regions);
    if (regions.contains(region)) {
      regions.remove(region);
    } else {
      regions.add(region);
    }
    final newFilter = state.filter.copyWith(regions: regions);
    updateFilter(newFilter);
  }

  void toggleLanguageFilter(String language) async {
    final languages = Set<String>.from(state.filter.languages);
    if (languages.contains(language)) {
      languages.remove(language);
    } else {
      languages.add(language);
    }
    final newFilter = state.filter.copyWith(languages: languages);
    updateFilter(newFilter);
  }

  void toggleFlagFilter(String flagType, String flag) async {
    CatalogFilter newFilter;
    switch (flagType) {
      case 'dumpQualities':
        final flags = Set<String>.from(state.filter.dumpQualities);
        if (flags.contains(flag)) {
          flags.remove(flag);
        } else {
          flags.add(flag);
        }
        newFilter = state.filter.copyWith(dumpQualities: flags);
        break;
      case 'romTypes':
        final flags = Set<String>.from(state.filter.romTypes);
        if (flags.contains(flag)) {
          flags.remove(flag);
        } else {
          flags.add(flag);
        }
        newFilter = state.filter.copyWith(romTypes: flags);
        break;
      case 'modifications':
        final flags = Set<String>.from(state.filter.modifications);
        if (flags.contains(flag)) {
          flags.remove(flag);
        } else {
          flags.add(flag);
        }
        newFilter = state.filter.copyWith(modifications: flags);
        break;
      case 'distributionTypes':
        final flags = Set<String>.from(state.filter.distributionTypes);
        if (flags.contains(flag)) {
          flags.remove(flag);
        } else {
          flags.add(flag);
        }
        newFilter = state.filter.copyWith(distributionTypes: flags);
        break;
      default:
        return;
    }
    updateFilter(newFilter);
  }

  void clearFilters() async {
    updateFilter(const CatalogFilter(
      regions: {},
      languages: {},
      dumpQualities: {},
      romTypes: {},
      modifications: {},
      distributionTypes: {},
    ));
  }

  void defaultFilters() async {
    updateFilter(const CatalogFilter());
  }
}
