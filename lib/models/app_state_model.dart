import 'package:roms_downloader/models/console_model.dart';

enum ViewMode { list, grid }

class AppState {
  final bool loading;
  final Map<String, Console> consoles;
  final Console? selectedConsole;
  final ViewMode viewMode;

  const AppState({
    this.loading = false,
    this.consoles = const {},
    this.selectedConsole,
    this.viewMode = ViewMode.list,
  });

  AppState copyWith({
    bool? loading,
    Map<String, Console>? consoles,
    Console? selectedConsole,
    ViewMode? viewMode,
  }) {
    return AppState(
      loading: loading ?? this.loading,
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  List<Console> get consolesList => consoles.values.toList();
}
