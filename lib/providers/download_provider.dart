import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';

final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final catalogNotifier = ref.read(catalogProvider.notifier);
  final gameStateManager = ref.read(gameStateManagerProvider.notifier);
  return DownloadNotifier(ref, catalogNotifier, gameStateManager);
});

class DownloadNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  final Map<String, DownloadTask> _tasks = {};
  StreamSubscription<TaskUpdate>? _updateSubscription;

  final DownloadService downloadService = DownloadService();
  final CatalogNotifier catalogNotifier;
  final GameStateManager gameStateManager;

  DownloadNotifier(this._ref, this.catalogNotifier, this.gameStateManager) : super(const DownloadState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final fileDownloader = await downloadService.initialize();

    _updateSubscription = fileDownloader.updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          _handleStatusUpdate(update);
        case TaskProgressUpdate():
          _handleProgressUpdate(update);
      }
    });

    await fileDownloader.resumeFromBackground();

    await _syncWithBackgroundTasks();
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    taskStatus[update.task.taskId] = update.status;

    if (!_tasks.containsKey(update.task.taskId) && update.task is DownloadTask) {
      _tasks[update.task.taskId] = update.task as DownloadTask;
      debugPrint('Registered background task ${update.task.taskId} with status ${update.status}');
    }

    final completedTasks = Set<String>.from(state.completedTasks);
    if (update.status == TaskStatus.complete) {
      completedTasks.add(update.task.taskId);
      catalogNotifier.deselectGame(update.task.taskId);
      debugPrint('Download completed for ${update.task.taskId}');
      _triggerAutoExtraction(update.task.taskId);
    }

    state = state.copyWith(
      taskStatus: taskStatus,
      completedTasks: completedTasks,
    );

    gameStateManager.updateDownloadState(
      update.task.taskId,
      update.status,
      state.taskProgress[update.task.taskId],
      update.status == TaskStatus.complete,
    );

    _updateDownloadingState();
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final taskProgress = Map<String, TaskProgressUpdate>.from(state.taskProgress);
    final taskStatus = state.taskStatus[update.task.taskId];

    if (!_tasks.containsKey(update.task.taskId) && update.task is DownloadTask) {
      _tasks[update.task.taskId] = update.task as DownloadTask;
      debugPrint('Registered background task ${update.task.taskId} from progress update');
    }

    if (taskStatus == TaskStatus.paused || update.progress <= 0.0) {
      final lastProgress = state.taskProgress[update.task.taskId];
      if (lastProgress != null && lastProgress.progress > 0.0) {
        update = TaskProgressUpdate(lastProgress.task, lastProgress.progress);
      }
    }

    taskProgress[update.task.taskId] = update;

    state = state.copyWith(
      taskProgress: taskProgress,
    );

    gameStateManager.updateDownloadState(
      update.task.taskId,
      taskStatus,
      update,
      false,
    );
  }

  void _updateDownloadingState() {
    final hasActiveDownloads = state.taskStatus.values.any((status) => status == TaskStatus.running || status == TaskStatus.enqueued);

    if (state.downloading != hasActiveDownloads) {
      state = state.copyWith(downloading: hasActiveDownloads);
    }
  }

  void _triggerAutoExtraction(String taskId) {
    final gameState = gameStateManager.state[taskId];
    if (gameState == null) return;

    final game = gameState.game;
    final settingsNotifier = _ref.read(settingsProvider.notifier);

    final autoExtract = settingsNotifier.getAutoExtract(game.consoleId);
    if (!autoExtract) return;

    debugPrint('Auto-extracting for task: $taskId');
    final extractionNotifier = _ref.read(extractionProvider.notifier);
    extractionNotifier.extractFile(taskId);
  }

  bool isTaskDownloadable(String taskId) {
    if (state.completedTasks.contains(taskId)) return false;
    final taskStatus = state.taskStatus[taskId];
    switch (taskStatus) {
      case null:
      case TaskStatus.canceled:
      case TaskStatus.complete:
      case TaskStatus.failed:
        return true;
      default:
        return false;
    }
  }

  Future<void> startDownloads(List<Game> games, String downloadDir, String? group) async {
    if (games.isEmpty) return;

    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);

    debugPrint('Starting downloads to directory: $downloadDir');

    try {
      for (final game in games) {
        final taskId = game.taskId;
        final fileName = game.filename;

        if (!isTaskDownloadable(taskId)) continue;
        debugPrint('Creating download task for: $taskId -> $downloadDir/$fileName');

        final downloadTask = downloadService.createDownloadTask(
          taskId: taskId,
          url: game.url,
          fileName: fileName,
          directory: downloadDir,
          group: group ?? 'default',
        );

        _tasks[taskId] = downloadTask;

        final enqueued = await downloadService.enqueuedTask(downloadTask);
        if (enqueued) {
          taskStatus[taskId] = TaskStatus.enqueued;
        }
      }

      state = state.copyWith(taskStatus: taskStatus);
    } catch (e) {
      debugPrint('Error starting downloads: $e');
    }
  }

  Future<void> startSelectedDownloads(String downloadDir, String? group) async {
    final catalogState = _ref.read(catalogProvider);
    if (catalogState.selectedGames.isEmpty) return;

    final games = catalogState.games.where((game) => catalogState.selectedGames.contains(game.taskId)).toList();

    await startDownloads(games, downloadDir, group);
  }

  Future<void> startSingleDownload(Game game) async {
    final settingsNotifier = _ref.read(settingsProvider.notifier);
    final downloadDir = settingsNotifier.getDownloadDir(game.consoleId);
    await startDownloads([game], downloadDir, game.consoleId);
    catalogNotifier.deselectGame(game.taskId);
  }

  Future<void> pauseTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await downloadService.pauseTask(task);
    }
  }

  Future<void> resumeTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await downloadService.resumeTask(task);
    }
  }

  Future<void> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await downloadService.cancelTask(task);
    } else {
      await downloadService.cancelTaskById(taskId);
    }

    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    final taskProgress = Map<String, TaskProgressUpdate>.from(state.taskProgress);

    taskStatus.remove(taskId);
    taskProgress.remove(taskId);
    _tasks.remove(taskId);

    catalogNotifier.deselectGame(taskId);

    state = state.copyWith(
      taskStatus: taskStatus,
      taskProgress: taskProgress,
    );

    gameStateManager.updateDownloadState(
      taskId,
      TaskStatus.canceled,
      null,
      false,
    );
  }

  bool hasDownloadableSelectedGames() {
    final catalogState = _ref.read(catalogProvider);
    return catalogState.selectedGames.any((taskId) => isTaskDownloadable(taskId));
  }

  Future<void> _syncWithBackgroundTasks() async {
    try {
      final allTasks = await FileDownloader().allTasks();
      
      final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
      final taskProgress = Map<String, TaskProgressUpdate>.from(state.taskProgress);
      
      for (final task in allTasks) {
        if (task is DownloadTask) {
          _tasks[task.taskId] = task;

          if (!taskStatus.containsKey(task.taskId)) {
            taskStatus[task.taskId] = TaskStatus.running;
            debugPrint('Discovered background task ${task.taskId}');
          }
        }
      }
      
      state = state.copyWith(
        taskStatus: taskStatus,
        taskProgress: taskProgress,
      );
      
      _updateDownloadingState();
    } catch (e) {
      debugPrint('Error syncing with background tasks: $e');
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }
}
