import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/services/download_service.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final catalogService = CatalogService();
  final directoryService = DirectoryService();
  final downloadService = DownloadService();
  return AppStateNotifier(catalogService, directoryService, downloadService);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final CatalogService catalogService;
  final DirectoryService directoryService;
  final DownloadService downloadService;

  final Map<String, DownloadTask> _downloadTasks = {};
  StreamSubscription<TaskUpdate>? _downloadUpdateSubscription;

  AppStateNotifier(this.catalogService, this.directoryService, this.downloadService) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final fileDownloader = await DownloadService().initialize();
    
    _downloadUpdateSubscription = fileDownloader.updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          _handleDownloadStatusUpdate(update);
        case TaskProgressUpdate():
          _handleDownloadProgressUpdate(update);
      }
    });

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

  void _handleDownloadStatusUpdate(TaskStatusUpdate update) {
    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    taskStatus[update.task.taskId] = update.status;

    if (update.status == TaskStatus.complete) {
      final completedTasks = state.completedTasks.toSet();
      completedTasks.add(update.task.taskId);

      state = state.copyWith(
        taskStatus: taskStatus,
        completedTasks: completedTasks,
        selectedTasks: state.selectedTasks.where((id) => id != update.task.taskId).toSet(),
      );
    } else {
      state = state.copyWith(taskStatus: taskStatus);
    }

    _updateDownloadingState();
  }

  void _handleDownloadProgressUpdate(TaskProgressUpdate update) {
    final taskProgress = Map<String, double>.from(state.taskProgress);
    taskProgress[update.task.taskId] = update.progress;

    state = state.copyWith(taskProgress: taskProgress);
  }

  void _updateDownloadingState() {
    final hasActiveDownloads = state.taskStatus.values.any((status) => status == TaskStatus.running || status == TaskStatus.enqueued);

    if (state.downloading != hasActiveDownloads) {
      state = state.copyWith(downloading: hasActiveDownloads);
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
      await _checkCompletedFiles(catalog);

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

  Future<void> _checkCompletedFiles(List<Game> catalog) async {
    final completedTasks = <String>{};

    for (final game in catalog) {
      final taskId = game.taskId(state.selectedConsole!.id);
      final filePath = path.join(state.downloadDir, game.filename);

      if (File(filePath).existsSync()) {
        completedTasks.add(taskId);
      }
    }

    state = state.copyWith(completedTasks: completedTasks);
  }

  Future<void> handleDirectoryChange() async {
    final selected = await directoryService.selectDownloadDirectory();
    if (selected != null) {
      state = state.copyWith(downloadDir: selected);
      if (state.catalog.isNotEmpty) {
        await _checkCompletedFiles(state.catalog);
      }
    }
  }

  void updateFilterText(String filter) {
    state = state.copyWith(filterText: filter);
  }

  void toggleGameSelection(int gameIndex) {
    if (gameIndex >= state.catalog.length) return;

    final game = state.catalog[gameIndex];
    final taskId = game.taskId(state.selectedConsole!.id);

    if (state.completedTasks.contains(taskId)) return;

    final selectedTasks = Set<String>.from(state.selectedTasks);
    if (selectedTasks.contains(taskId)) {
      selectedTasks.remove(taskId);
    } else {
      selectedTasks.add(taskId);
    }

    state = state.copyWith(selectedTasks: selectedTasks);
  }

  Future<void> startDownloads() async {
    if (state.selectedTasks.isEmpty || state.downloading) return;

    final downloadTaskStatuses = Map<String, TaskStatus>.from(state.taskStatus);

    debugPrint('Starting downloads to directory: ${state.downloadDir}');
    try {
      for (final taskId in state.selectedTasks) {
        final parts = taskId.split('/');
        if (parts.length != 2) continue;

        final fileName = parts[1];
        final game = state.catalog.firstWhere(
          (g) => g.filename == fileName,
          orElse: () => throw Exception('Game not found for taskId: $taskId'),
        );

        debugPrint('Creating download task for: $taskId -> ${state.downloadDir}/$fileName');

        _downloadTasks[taskId] = downloadService.createDownloadTask(
          taskId: taskId,
          url: game.url,
          fileName: fileName,
          directory: state.downloadDir,
          group: state.selectedConsole!.id,
        );

        final enqueued = await downloadService.enqueuedTask(_downloadTasks[taskId]!);
        if (enqueued) {
          downloadTaskStatuses[taskId] = TaskStatus.enqueued;
        }
      }

      state = state.copyWith(taskStatus: downloadTaskStatuses, downloading: true);
    } catch (e) {
      debugPrint('Error starting downloads: $e');
    }
  }

  Future<void> pauseTask(String taskId) async {
    final task = _downloadTasks[taskId];
    if (task != null) await downloadService.pauseTask(task);
  }

  Future<void> resumeTask(String taskId) async {
    final task = _downloadTasks[taskId];
    if (task != null) await downloadService.resumeTask(task);
  }

  Future<void> cancelTask(String taskId) async {
    final task = _downloadTasks[taskId];
    if (task != null) await downloadService.cancelTask(task);
    _removeDownloadTask(taskId);
  }

  void _removeDownloadTask(String taskId) {
    final downloadTasksStatuses = Map<String, TaskStatus>.from(state.taskStatus);
    final downloadTasksProgresses = Map<String, double>.from(state.taskProgress);
    final selectedDownloadTasks = Set<String>.from(state.selectedTasks);

    downloadTasksStatuses.remove(taskId);
    downloadTasksProgresses.remove(taskId);
    selectedDownloadTasks.remove(taskId);

    state = state.copyWith(
      taskStatus: downloadTasksStatuses,
      taskProgress: downloadTasksProgresses,
      selectedTasks: selectedDownloadTasks,
    );
  }

  @override
  void dispose() {
    _downloadUpdateSubscription?.cancel();
    super.dispose();
  }
}
