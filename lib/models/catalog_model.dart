import 'package:roms_downloader/models/game_model.dart';

class CatalogState {
  final List<Game> games;
  final String filterText;
  final bool loading;
  final Set<String> selectedGames;

  const CatalogState({
    this.games = const [],
    this.filterText = '',
    this.loading = false,
    this.selectedGames = const {},
  });

  CatalogState copyWith({
    List<Game>? games,
    String? filterText,
    bool? loading,
    Set<String>? selectedGames,
  }) {
    return CatalogState(
      games: games ?? this.games,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      selectedGames: selectedGames ?? this.selectedGames,
    );
  }

  List<Game> get filteredGames {
    if (filterText.isEmpty) return games;
    return games.where((game) => game.title.toLowerCase().contains(filterText.toLowerCase())).toList();
  }
}
