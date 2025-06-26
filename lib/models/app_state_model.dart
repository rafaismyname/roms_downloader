import 'package:roms_downloader/models/console_model.dart';

class AppState {
  final bool loading;
  final List<Console> consoles;
  final Console? selectedConsole;
  final String downloadDir;

  const AppState({
    this.loading = false,
    this.consoles = const [],
    this.selectedConsole,
    this.downloadDir = '',
  });

  AppState copyWith({
    bool? loading,
    List<Console>? consoles,
    Console? selectedConsole,
    String? downloadDir,
  }) {
    return AppState(
      loading: loading ?? this.loading,
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      downloadDir: downloadDir ?? this.downloadDir,
    );
  }
}
