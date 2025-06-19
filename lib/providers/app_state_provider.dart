import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/services/game_state_service.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(
    catalogService: ref.watch(catalogServiceProvider),
    downloadService: ref.watch(downloadServiceProvider),
    directoryService: ref.watch(directoryServiceProvider),
    gameStateService: ref.watch(gameStateServiceProvider),
  );
});

class AppStateNotifier extends StateNotifier<AppState> {
  final CatalogService catalogService;
  final DownloadService downloadService;
  final DirectoryService directoryService;
  final GameStateService gameStateService;

  AppStateNotifier({
    required this.catalogService,
    required this.downloadService,
    required this.directoryService,
    required this.gameStateService,
  }) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(
        downloadDir: await directoryService.getDownloadDir(),
        consoles: await catalogService.getConsoles(),
      );

      if (state.consoles.isNotEmpty) {
        await loadCatalog(state.consoles.first);
      }
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  Future<void> loadCatalog(Console console) async {
    state = state.copyWith(
      loading: true,
      catalog: [],
      gameFileStatus: [],
      selectedConsole: console,
      selectedGames: [],
    );

    try {
      final result = await catalogService.loadCatalog(console.id);
      final fileStatus = await gameStateService.checkFilesExist(result);

      state = state.copyWith(
        catalog: result,
        gameFileStatus: fileStatus,
        loading: false,
      );
    } catch (e) {
      // Catalog loading in background, start polling
      _monitorCatalogLoading();
    }
  }

  void _monitorCatalogLoading() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!state.loading) return;

      try {
        final loadingStatus = await catalogService.getLoadingStatus();

        if (loadingStatus == null) {
          final updatedCatalog = await catalogService.getCatalog();
          final fileStatus = await gameStateService.checkFilesExist(updatedCatalog);

          state = state.copyWith(
            catalog: updatedCatalog,
            gameFileStatus: fileStatus,
            loading: false,
          );
        } else {
          // Still loading, continue polling
          _monitorCatalogLoading();
        }
      } catch (e) {
        final updatedCatalog = await catalogService.getCatalog();
        if (updatedCatalog.isNotEmpty) {
          state = state.copyWith(
            catalog: updatedCatalog,
            gameFileStatus: await gameStateService.checkFilesExist(updatedCatalog),
            loading: false,
          );
        } else {
          _monitorCatalogLoading();
        }
      }
    });
  }

  Future<void> refreshCatalog() async {
    final updatedCatalog = await catalogService.getCatalog();
    final fileStatus = await gameStateService.checkFilesExist(updatedCatalog);
    state = state.copyWith(catalog: updatedCatalog, gameFileStatus: fileStatus);
  }

  Future<void> handleDirectoryChange() async {
    final selected = await directoryService.selectDownloadDirectory();
    if (selected != null) {
      state = state.copyWith(downloadDir: selected);
      await refreshCatalog();
    }
  }

  Future<void> startDownloads() async {
    if (state.selectedGames.isEmpty) return;

    state = state.copyWith(
      downloading: true,
      downloadStats: const DownloadStats(),
      gameStats: {},
    );

    await downloadService.selectGames(state.selectedGames);
    await downloadService.startDownloads();
    _monitorDownloadProgress();
  }

  void _monitorDownloadProgress() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!state.downloading) return;

      try {
        final isStillDownloading = await downloadService.isDownloading();
        final isComplete = await downloadService.checkDownloadCompletion();

        if (!isStillDownloading || isComplete) {
          await _resetDownloadState();
          return;
        }

        state = state.copyWith(
          downloadStats: await downloadService.getDownloadStats(),
          gameStats: await _getUpdatedGameStats(),
        );

        // Continue polling
        _monitorDownloadProgress();
      } catch (e) {
        print('Error monitoring download: $e');
        if (!await downloadService.isDownloading()) {
          await _resetDownloadState();
        } else {
          _monitorDownloadProgress();
        }
      }
    });
  }

  Future<Map<int, GameDownloadState>> _getUpdatedGameStats() async {
    final newGameStats = <int, GameDownloadState>{};
    for (final gameIdx in state.selectedGames.take(10)) {
      try {
        newGameStats[gameIdx] = await downloadService.getGameStats(gameIdx);
      } catch (_) {}
    }
    return {...state.gameStats, ...newGameStats};
  }

  Future<void> _resetDownloadState() async {
    await downloadService.resetDownloadState();
    gameStateService.cleanupCompletedDownloads();

    state = state.copyWith(
      downloading: false,
      gameStats: {},
      selectedGames: [],
      downloadStats: const DownloadStats(),
    );

    await refreshCatalog();
  }

  void toggleGameSelection(int idx) {
    if (state.gameFileStatus.length > idx && state.gameFileStatus[idx]) return;

    final isSelected = state.selectedGames.contains(idx);
    final newSelection = isSelected ? state.selectedGames.where((i) => i != idx).toList() : [...state.selectedGames, idx];

    downloadService.selectGames(newSelection);
    state = state.copyWith(selectedGames: newSelection);
  }

  void updateFilterText(String text) {
    state = state.copyWith(filterText: text);
  }

  List<Game> getFilteredCatalog() {
    if (state.filterText.isEmpty) return state.catalog;

    final filterTextLower = state.filterText.toLowerCase();
    return state.catalog.where((game) => game.title.toLowerCase().contains(filterTextLower)).toList();
  }
}
