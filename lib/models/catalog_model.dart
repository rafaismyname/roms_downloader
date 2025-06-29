import 'package:roms_downloader/models/game_model.dart';

const int kDefaultCatalogDisplaySize = 20;

class CatalogState {
  final List<Game> games;
  final String filterText;
  final bool loading;
  final Set<String> selectedGames;
  final int displayedCount;

  const CatalogState({
    this.games = const [],
    this.filterText = '',
    this.loading = false,
    this.selectedGames = const {},
    this.displayedCount = 20,
  });

  CatalogState copyWith({
    List<Game>? games,
    String? filterText,
    bool? loading,
    Set<String>? selectedGames,
    int? displayedCount,
  }) {
    return CatalogState(
      games: games ?? this.games,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      selectedGames: selectedGames ?? this.selectedGames,
      displayedCount: displayedCount ?? this.displayedCount,
    );
  }

  List<Game> get filteredGames {
    return filterText.isEmpty ? games : games.where((game) => game.title.toLowerCase().contains(filterText.toLowerCase())).toList();
  }

  List<Game> get paginatedFilteredGames {
    return filteredGames.take(displayedCount).toList();
  }

  bool get hasMoreItems {
    return displayedCount < filteredGames.length;
  }
}
