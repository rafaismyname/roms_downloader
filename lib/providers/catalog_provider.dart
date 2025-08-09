import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/favorites_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/library_snapshot_model.dart';
import 'package:roms_downloader/providers/library_snapshot_provider.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/filtering_service.dart';
import 'package:roms_downloader/providers/favorites_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';

final gameSelectionProvider = Provider.family<bool, String>((ref, gameId) {
  final catalogState = ref.watch(catalogProvider);
  return catalogState.selectedGames.contains(gameId);
});

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((ref) {
  final catalogService = CatalogService();
  return CatalogNotifier(ref, catalogService);
});

class CatalogNotifier extends StateNotifier<CatalogState> {
  final CatalogService catalogService;
  final Ref _ref;

  bool _loadingMore = false;

  CatalogNotifier(this._ref, this.catalogService) : super(const CatalogState()) {
    _ref.listen<Favorites>(favoritesProvider, (previous, current) {
      if (state.filter.showFavoritesOnly && previous?.gameIds != current.gameIds) {
        updateFilteredGames();
      }
    });
  }

  Future<void> loadCatalog(Console console) async {
    if (state.loading) return;

    state = state.copyWith(
      loading: true,
      games: [],
      selectedGames: {},
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

      final settingsNotifier = _ref.read(settingsProvider.notifier);
      final downloadDir = settingsNotifier.getDownloadDir(console.id);
      _ref.listen(librarySnapshotProvider(downloadDir), (_, __) {
        if (state.filter.showInLibraryOnly) updateFilteredGames();
      });

      state = state.copyWith(
        games: games,
        loading: false,
        availableRegions: regions,
        availableLanguages: languages,
        availableCategories: categories,
      );

      await updateFilteredGames();
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      state = state.copyWith(
        loading: false,
        games: [],
      );
    }
  }

  Future<Map<String, GameStatus>> getLibraryStatus() async {
    final consoleId = state.games.isNotEmpty ? state.games.first.consoleId : null;
    if (consoleId == null) return {};

    final settingsNotifier = _ref.read(settingsProvider.notifier);
    final downloadDir = settingsNotifier.getDownloadDir(consoleId);
    if (downloadDir.isEmpty) return {};

    final snap = _ref.read(librarySnapshotProvider(downloadDir).notifier);
    final statuses = await snap.getStatuses(state.games.map((g) => g.filename));
    final result = <String, GameStatus>{};
    for (final game in state.games) {
      result[game.gameId] = (statuses[game.filename] ?? LibraryPresence.none).toGameStatus();
    }
    return result;
  }

  Future<FilterResult> _runFilterAndPaginate({required int skip, required int limit}) async {
    final favs = state.filter.showFavoritesOnly ? _ref.read(favoritesProvider).gameIds : null;
    final lib = state.filter.showInLibraryOnly ? await getLibraryStatus() : null;

    return compute(
      FilteringService.filterAndPaginate,
      FilterInput(
        games: state.games,
        filterText: state.filterText,
        filter: state.filter,
        skip: skip,
        limit: limit,
        favoriteGameIds: favs,
        inLibraryStatus: lib,
      ),
    );
  }

  Future<void> updateFilteredGames() async {
    if (state.games.isEmpty) return;

    try {
      final filteredAndPaginated = await _runFilterAndPaginate(skip: 0, limit: kDefaultCatalogDisplaySize);
      state = state.copyWith(
        cachedFilteredGames: filteredAndPaginated.games,
        cachedTotalCount: filteredAndPaginated.totalCount,
        cachedHasMore: filteredAndPaginated.hasMore,
      );
    } catch (e) {
      debugPrint('Error filtering games: $e');
    }
  }

  Future<void> loadMoreItems() async {
    if (_loadingMore || !state.hasMoreItems) return;

    _loadingMore = true;
    state = state.copyWith(loadingMore: true);

    try {
      final filteredAndPaginated = await _runFilterAndPaginate(skip: state.paginatedFilteredGames.length, limit: kDefaultCatalogDisplaySize);
      state = state.copyWith(
        cachedFilteredGames: [...state.paginatedFilteredGames, ...filteredAndPaginated.games],
        cachedTotalCount: filteredAndPaginated.totalCount,
        cachedHasMore: filteredAndPaginated.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more items: $e');
    } finally {
      _loadingMore = false;
      state = state.copyWith(loadingMore: false);
    }
  }

  void updateFilterText(String filter) async {
    state = state.copyWith(filterText: filter);
    await updateFilteredGames();
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
    await updateFilteredGames();
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

  void toggleLatestRevisionOnly() async {
    final newFilter = state.filter.copyWith(
      showLatestRevisionOnly: !state.filter.showLatestRevisionOnly,
    );
    updateFilter(newFilter);
  }

  void toggleFavoritesOnly() async {
    final newFilter = state.filter.copyWith(
      showFavoritesOnly: !state.filter.showFavoritesOnly,
    );
    updateFilter(newFilter);
  }

  void toggleLibraryOnly() async {
    final newFilter = state.filter.copyWith(
      showInLibraryOnly: !state.filter.showInLibraryOnly,
    );
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
      showFavoritesOnly: false,
      showInLibraryOnly: false,
    ));
  }

  void defaultFilters() async {
    updateFilter(const CatalogFilter());
  }

  Future<void> clearCatalogCache([String? consoleId]) async {
    await catalogService.clearCatalogCache(consoleId);
  }

  Future<void> refreshCatalog() async {
    if (state.games.isEmpty) return;

    final consoleId = state.games.first.consoleId;
    final consoles = await catalogService.getConsoles();
    final console = consoles[consoleId];
    if (console == null) return;

    state = state.copyWith(
      games: [],
      cachedFilteredGames: [],
      cachedTotalCount: 0,
      cachedHasMore: false,
      selectedGames: {},
      availableRegions: {},
      availableLanguages: {},
      availableCategories: {},
    );
    await loadCatalog(console);
  }
}
