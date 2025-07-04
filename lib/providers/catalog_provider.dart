import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/catalog_filter.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/services/catalog_service.dart';

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

  CatalogNotifier(this.catalogService) : super(const CatalogState());

  Future<void> loadCatalog(Console console) async {
    if (state.loading) return;

    state = state.copyWith(
      loading: true,
      games: [],
      selectedGames: {},
    );

    try {
      final games = await catalogService.loadCatalog(console.id);

      final regions = <String>{};
      final languages = <String>{};

      for (final game in games) {
        if (game.metadata != null) {
          if (game.metadata!.region.isNotEmpty) {
            regions.add(game.metadata!.region);
          }
          if (game.metadata!.language.isNotEmpty) {
            languages.add(game.metadata!.language);
          }
        }
      }

      state = state.copyWith(
        games: games,
        loading: false,
        displayedCount: kDefaultCatalogDisplaySize,
        availableRegions: regions,
        availableLanguages: languages,
      );
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      state = state.copyWith(
        loading: false,
        games: [],
      );
    }
  }

  void updateFilterText(String filter) {
    state = state.copyWith(filterText: filter, displayedCount: kDefaultCatalogDisplaySize);
  }

  void loadMoreItems() {
    if (!state.hasMoreItems) return;
    state = state.copyWith(displayedCount: state.displayedCount + kDefaultCatalogDisplaySize);
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

  void updateFilter(CatalogFilter filter) {
    state = state.copyWith(filter: filter, displayedCount: kDefaultCatalogDisplaySize);
  }

  void toggleRegionFilter(String region) {
    final regions = Set<String>.from(state.filter.regions);
    if (regions.contains(region)) {
      regions.remove(region);
    } else {
      regions.add(region);
    }
    final newFilter = state.filter.copyWith(regions: regions);
    updateFilter(newFilter);
  }

  void toggleLanguageFilter(String language) {
    final languages = Set<String>.from(state.filter.languages);
    if (languages.contains(language)) {
      languages.remove(language);
    } else {
      languages.add(language);
    }
    final newFilter = state.filter.copyWith(languages: languages);
    updateFilter(newFilter);
  }

  void toggleDumpTypeFilter(String type, bool value) {
    CatalogFilter newFilter;
    switch (type) {
      case 'goodDumps':
        newFilter = state.filter.copyWith(showGoodDumps: value);
        break;
      case 'badDumps':
        newFilter = state.filter.copyWith(showBadDumps: value);
        break;
      case 'overdumps':
        newFilter = state.filter.copyWith(showOverdumps: value);
        break;
      case 'hacks':
        newFilter = state.filter.copyWith(showHacks: value);
        break;
      case 'translations':
        newFilter = state.filter.copyWith(showTranslations: value);
        break;
      case 'alternates':
        newFilter = state.filter.copyWith(showAlternates: value);
        break;
      case 'fixed':
        newFilter = state.filter.copyWith(showFixed: value);
        break;
      case 'trainer':
        newFilter = state.filter.copyWith(showTrainer: value);
        break;
      case 'unlicensed':
        newFilter = state.filter.copyWith(showUnlicensed: value);
        break;
      case 'demos':
        newFilter = state.filter.copyWith(showDemos: value);
        break;
      case 'samples':
        newFilter = state.filter.copyWith(showSamples: value);
        break;
      case 'protos':
        newFilter = state.filter.copyWith(showProtos: value);
        break;
      case 'betas':
        newFilter = state.filter.copyWith(showBetas: value);
        break;
      case 'alphas':
        newFilter = state.filter.copyWith(showAlphas: value);
        break;
      default:
        return;
    }
    updateFilter(newFilter);
  }

  void clearFilters() {
    updateFilter(const CatalogFilter());
  }
}
