import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/services/permission_service.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final catalogService = CatalogService();
  final directoryService = DirectoryService();
  final permissionService = PermissionService();
  final catalogNotifier = ref.read(catalogProvider.notifier);
  return AppStateNotifier(ref, catalogService, directoryService, permissionService, catalogNotifier);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  final CatalogService catalogService;
  final DirectoryService directoryService;
  final PermissionService permissionService;
  final CatalogNotifier catalogNotifier;

  AppStateNotifier(this._ref, this.catalogService, this.directoryService, this.permissionService, this.catalogNotifier) : super(const AppState()) {
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

  Future<void> handleDirectoryChange() async {
    final selected = await directoryService.selectDownloadDirectory();
    if (selected != null) {
      state = state.copyWith(downloadDir: selected);
    }
  }

  void selectConsole(Console console) {
    state = state.copyWith(selectedConsole: console);
    catalogNotifier.loadCatalog(console);
  }

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading);
  }
}
