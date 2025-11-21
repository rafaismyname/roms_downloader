import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/permission_service.dart';

const _viewModeKey = 'view_mode';
const _selectedConsoleKey = 'selected_console';
const _themeModeKey = 'theme_mode';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final catalogService = CatalogService();
  final catalogNotifier = ref.read(catalogProvider.notifier);
  return AppStateNotifier(ref, catalogService, catalogNotifier);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  final CatalogService catalogService;
  final CatalogNotifier catalogNotifier;

  AppStateNotifier(this._ref, this.catalogService, this.catalogNotifier) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await PermissionService.ensurePermissions();

    final prefs = await SharedPreferences.getInstance();
    final viewModeKey = prefs.getString(_viewModeKey) ?? 'grid';
    final savedViewMode = viewModeKey == 'list' ? ViewMode.list : ViewMode.grid;
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final savedThemeMode = ThemeMode.values[themeModeIndex];

    final consoles = await catalogService.getConsoles();
    
    final savedConsoleId = prefs.getString(_selectedConsoleKey);
    final selectedConsole = (savedConsoleId != null && consoles.containsKey(savedConsoleId))
        ? consoles[savedConsoleId]
        : consoles.isNotEmpty ? consoles.values.first : null;

    state = state.copyWith(
      consoles: consoles,
      selectedConsole: selectedConsole,
      viewMode: savedViewMode,
      themeMode: savedThemeMode,
    );

    _listenToLoadingNotifications();

    catalogNotifier.loadCatalog(state.selectedConsole!);
  }

  void _listenToLoadingNotifications() {
    _ref.listen<CatalogState>(catalogProvider, (previous, next) {
      if (previous?.loading != next.loading) {
        state = state.copyWith(loading: next.loading);
      }
    });
  }

  void selectConsole(Console console) {
    state = state.copyWith(selectedConsole: console);
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_selectedConsoleKey, console.id));
    catalogNotifier.loadCatalog(console);
  }

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }

  void toggleViewMode() {
    final newMode = state.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    state = state.copyWith(viewMode: newMode);
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_viewModeKey, newMode.name));
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
    SharedPreferences.getInstance().then((prefs) => prefs.setString(_viewModeKey, mode.name));
  }

  void toggleThemeMode() {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    SharedPreferences.getInstance().then((prefs) => prefs.setInt(_themeModeKey, newMode.index));
  }
}
