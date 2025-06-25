import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/services/permission_service.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final catalogService = CatalogService();
  final directoryService = DirectoryService();
  final permissionService = PermissionService();
  return AppStateNotifier(catalogService, directoryService, permissionService);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final CatalogService catalogService;
  final DirectoryService directoryService;
  final PermissionService permissionService;

  AppStateNotifier(this.catalogService, this.directoryService, this.permissionService) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await permissionService.ensurePermissions();

    final downloadDir = await directoryService.getDownloadDir();
    final consoles = await catalogService.getConsoles();

    state = state.copyWith(
      downloadDir: downloadDir,
      consoles: consoles,
      selectedConsole: consoles.isNotEmpty ? consoles.first : null,
    );

    if (state.selectedConsole != null) {
      await loadCatalog(state.selectedConsole!.id);
    }
  }

  Future<void> loadCatalog(String consoleId) async {
    if (state.loading) return;

    final console = state.consoles.firstWhere((c) => c.id == consoleId);

    state = state.copyWith(
      loading: true,
      selectedConsole: console,
      catalog: [],
    );

    try {
      final catalog = await catalogService.loadCatalog(consoleId);

      state = state.copyWith(
        catalog: catalog,
        loading: false,
      );
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      state = state.copyWith(
        loading: false,
        catalog: [],
      );
    }
  }

  Future<void> handleDirectoryChange() async {
    final selected = await directoryService.selectDownloadDirectory();
    if (selected != null) {
      state = state.copyWith(downloadDir: selected);
    }
  }

  void updateFilterText(String filter) {
    state = state.copyWith(filterText: filter);
  }
}
