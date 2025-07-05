import 'package:roms_downloader/models/console_model.dart';

class AppState {
  final bool loading;
  final Map<String, Console> consoles;
  final Console? selectedConsole;

  const AppState({
    this.loading = false,
    this.consoles = const {},
    this.selectedConsole,
  });

  AppState copyWith({
    bool? loading,
    Map<String, Console>? consoles,
    Console? selectedConsole,
  }) {
    return AppState(
      loading: loading ?? this.loading,
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
    );
  }

  List<Console> get consolesList => consoles.values.toList();
}
