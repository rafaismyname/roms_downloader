import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';

const int kDefaultCatalogDisplaySize = 20;

class CatalogState {
  final List<Game> games;
  final String filterText;
  final bool loading;
  final Set<String> selectedGames;
  final CatalogFilter filter;
  final Set<String> availableRegions;
  final Set<String> availableLanguages;
  final Set<String> availableCategories;
  final Set<String> availableMediaTypes;
  final Set<String> availablePublishers;
  final Set<String> availableSeries;
  final List<Game> _cachedFilteredGames;
  final int _cachedTotalCount;
  final bool _cachedHasMore;

  const CatalogState({
    this.games = const [],
    this.filterText = '',
    this.loading = false,
    this.selectedGames = const {},
    this.filter = const CatalogFilter(),
    this.availableRegions = const {},
    this.availableLanguages = const {},
    this.availableCategories = const {},
    this.availableMediaTypes = const {},
    this.availablePublishers = const {},
    this.availableSeries = const {},
    List<Game>? cachedFilteredGames,
    int? cachedTotalCount,
    bool? cachedHasMore,
  }) : _cachedFilteredGames = cachedFilteredGames ?? const [],
       _cachedTotalCount = cachedTotalCount ?? 0,
       _cachedHasMore = cachedHasMore ?? false;

  CatalogState copyWith({
    List<Game>? games,
    String? filterText,
    bool? loading,
    Set<String>? selectedGames,
    CatalogFilter? filter,
    Set<String>? availableRegions,
    Set<String>? availableLanguages,
    Set<String>? availableCategories,
    Set<String>? availableMediaTypes,
    Set<String>? availablePublishers,
    Set<String>? availableSeries,
    List<Game>? cachedFilteredGames,
    int? cachedTotalCount,
    bool? cachedHasMore,
  }) {
    return CatalogState(
      games: games ?? this.games,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      selectedGames: selectedGames ?? this.selectedGames,
      filter: filter ?? this.filter,
      availableRegions: availableRegions ?? this.availableRegions,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      availableCategories: availableCategories ?? this.availableCategories,
      availableMediaTypes: availableMediaTypes ?? this.availableMediaTypes,
      availablePublishers: availablePublishers ?? this.availablePublishers,
      availableSeries: availableSeries ?? this.availableSeries,
      cachedFilteredGames: cachedFilteredGames ?? _cachedFilteredGames,
      cachedTotalCount: cachedTotalCount ?? _cachedTotalCount,
      cachedHasMore: cachedHasMore ?? _cachedHasMore,
    );
  }

  List<Game> get paginatedFilteredGames => _cachedFilteredGames;
  
  bool get hasMoreItems => _cachedHasMore;

  int get filteredGamesCount => _cachedTotalCount;
}
