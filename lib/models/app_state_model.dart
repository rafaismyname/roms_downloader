import 'package:flutter/material.dart';
import 'package:roms_downloader/models/console_model.dart';

enum ViewMode { list, grid }

class AppState {
  final bool loading;
  final Map<String, Console> consoles;
  final Console? selectedConsole;
  final ViewMode viewMode;
  final ThemeMode themeMode;

  const AppState({
    this.loading = false,
    this.consoles = const {},
    this.selectedConsole,
    this.viewMode = ViewMode.grid,
    this.themeMode = ThemeMode.system,
  });

  AppState copyWith({
    bool? loading,
    Map<String, Console>? consoles,
    Console? selectedConsole,
    ViewMode? viewMode,
    ThemeMode? themeMode,
  }) {
    return AppState(
      loading: loading ?? this.loading,
      consoles: consoles ?? this.consoles,
      selectedConsole: selectedConsole ?? this.selectedConsole,
      viewMode: viewMode ?? this.viewMode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  List<Console> get consolesList => consoles.values.toList();
}
