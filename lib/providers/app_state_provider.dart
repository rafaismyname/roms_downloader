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
  final catalogService = ref.watch(catalogServiceProvider);
  final directoryService = ref.watch(directoryServiceProvider);
  final downloadService = ref.watch(downloadServiceProvider);
  return AppStateNotifier(catalogService, directoryService, downloadService);
});

class AppStateNotifier extends StateNotifier<AppState> {
  final CatalogService catalogService;
  final DirectoryService directoryService;
  final DownloadService downloadService;
  StreamSubscription<TaskUpdate>? _updateSubscription;

  AppStateNotifier(this.catalogService, this.directoryService, this.downloadService) : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await FileDownloader().trackTasks();

    await _requestNotificationPermissions();

    FileDownloader().configure(
      globalConfig: [
        (Config.holdingQueue, true),
        (Config.requestTimeout, 60),
        (Config.resourceTimeout, 3600),
      ],
      androidConfig: [
        (Config.useCacheDir, Config.never),
        // (Config.useExternalStorage, Config.whenAble),
        (Config.runInForeground, Config.whenAble),
      ],
    );

    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading ROM: {filename}',
        'Progress: {progress}% • {networkSpeed} • {timeRemaining}',
      ),
      complete: const TaskNotification(
        'Download Complete',
        '{filename} downloaded successfully',
      ),
      error: const TaskNotification(
        'Download Failed',
        '{filename} failed to download',
      ),
      paused: const TaskNotification(
        'Download Paused',
        '{filename} is paused',
      ),
      progressBar: true,
      tapOpensFile: false,
    );

    await FileDownloader().start();

    _updateSubscription = FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          _handleStatusUpdate(update);
        case TaskProgressUpdate():
          _handleProgressUpdate(update);
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

  Future<void> _requestNotificationPermissions() async {
    try {
      final permissionStatus = await FileDownloader().permissions.status(PermissionType.notifications);
      if (permissionStatus != PermissionStatus.granted) {
        await FileDownloader().permissions.request(PermissionType.notifications);
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
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

  void _handleProgressUpdate(TaskProgressUpdate update) {
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

    final tasks = <DownloadTask>[];

    debugPrint('Starting downloads to directory: ${state.downloadDir}');

    for (final taskId in state.selectedTasks) {
      final parts = taskId.split('/');
      if (parts.length != 2) continue;

      final fileName = parts[1];
      final game = state.catalog.firstWhere(
        (g) => g.filename == fileName,
        orElse: () => throw Exception('Game not found for taskId: $taskId'),
      );

      debugPrint('Creating download task for: $taskId -> ${state.downloadDir}/$fileName');

      final downloadTask = DownloadTask(
        taskId: taskId,
        url: game.url,
        filename: fileName,
        baseDirectory: BaseDirectory.root,
        directory: state.downloadDir,
        group: state.selectedConsole!.id,
        updates: Updates.statusAndProgress,
        allowPause: true,
        priority: 5,
        retries: 3,
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)'},
      );

      tasks.add(downloadTask);
      downloadService.registerTask(taskId, downloadTask);
    }

    try {
      final results = await FileDownloader().enqueueAll(tasks);

      final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
      for (int i = 0; i < tasks.length; i++) {
        if (results[i]) {
          taskStatus[tasks[i].taskId] = TaskStatus.enqueued;
        }
      }

      state = state.copyWith(taskStatus: taskStatus, downloading: true);
    } catch (e) {
      debugPrint('Error starting downloads: $e');
    }
  }

  Future<void> pauseTask(String taskId) async {
    await downloadService.pauseTask(taskId);
  }

  Future<void> resumeTask(String taskId) async {
    await downloadService.resumeTask(taskId);
  }

  Future<void> cancelTask(String taskId) async {
    await downloadService.cancelTask(taskId);
    _removeTask(taskId);
  }

  void _removeTask(String taskId) {
    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    final taskProgress = Map<String, double>.from(state.taskProgress);
    final selectedTasks = Set<String>.from(state.selectedTasks);

    taskStatus.remove(taskId);
    taskProgress.remove(taskId);
    selectedTasks.remove(taskId);

    state = state.copyWith(
      taskStatus: taskStatus,
      taskProgress: taskProgress,
      selectedTasks: selectedTasks,
    );
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }
}
