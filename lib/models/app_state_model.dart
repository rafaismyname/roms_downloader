import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';

class AppState {
  final List<Console> consoles;
  final Console? selectedConsole;
  final List<Game> catalog;
  final String filterText;
  final bool loading;
  final String downloadDir;

  const AppState({
    this.consoles = const [],
    this.selectedConsole,
    this.catalog = const [],
    this.filterText = '',
    this.loading = false,
    this.downloadDir = '',
  });

  AppState copyWith({
    List<Console>? consoles,
    Console? selectedConsole,
    List<Game>? catalog,
    String? filterText,
    bool? loading,
    String? downloadDir,
  }) {
    return AppState(
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      catalog: catalog ?? this.catalog,
      filterText: filterText ?? this.filterText,
      loading: loading ?? this.loading,
      downloadDir: downloadDir ?? this.downloadDir,
    );
  }

  List<Game> get filteredCatalog {
    if (filterText.isEmpty) return catalog;
    return catalog.where((game) => game.title.toLowerCase().contains(filterText.toLowerCase())).toList();
  }
}
