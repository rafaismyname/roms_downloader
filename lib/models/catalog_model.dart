import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';

const int kDefaultCatalogDisplaySize = 64;

class CatalogState {
  final List<Game> games;
  final String filterText;
  final bool loading; // loading the catalog
  final bool loadingMore; // loading more games in the list
  final Set<String> selectedGames;
  final CatalogFilter filter;
  final Set<String> availableRegions;
  final Set<String> availableLanguages;
  final Set<String> availableCategories;
  final List<Game> _cachedFilteredGames;
  final int _cachedTotalCount;
  final bool _cachedHasMore;

  const CatalogState({
    this.games = const [],
    this.filterText = '',
    this.loading = false,
    this.loadingMore = false,
    this.selectedGames = const {},
    this.filter = const CatalogFilter(),
    this.availableRegions = const {},
    this.availableLanguages = const {},
    this.availableCategories = const {},
    List<Game>? cachedFilteredGames,
    int? cachedTotalCount,
    bool? cachedHasMore,
  })  : _cachedFilteredGames = cachedFilteredGames ?? const [],
        _cachedTotalCount = cachedTotalCount ?? 0,
        _cachedHasMore = cachedHasMore ?? false;

  CatalogState copyWith({
    List<Game>? games,
    String? filterText,
    bool? loading,
    bool? loadingMore,
    Set<String>? selectedGames,
    CatalogFilter? filter,
    Set<String>? availableRegions,
    Set<String>? availableLanguages,
    Set<String>? availableCategories,
    List<Game>? cachedFilteredGames,
    int? cachedTotalCount,
    bool? cachedHasMore,
  }) {
    return CatalogState(
      games: games ?? this.games,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      selectedGames: selectedGames ?? this.selectedGames,
      filter: filter ?? this.filter,
      availableRegions: availableRegions ?? this.availableRegions,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      availableCategories: availableCategories ?? this.availableCategories,
      cachedFilteredGames: cachedFilteredGames ?? _cachedFilteredGames,
      cachedTotalCount: cachedTotalCount ?? _cachedTotalCount,
      cachedHasMore: cachedHasMore ?? _cachedHasMore,
    );
  }

  List<Game> get paginatedFilteredGames => _cachedFilteredGames;

  bool get hasMoreItems => _cachedHasMore;

  int get filteredGamesCount => _cachedTotalCount;
}
