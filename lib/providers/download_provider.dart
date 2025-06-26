import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';

final downloadTaskStatusProvider = Provider.family<TaskStatus?, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.taskStatus[taskId];
});

final downloadTaskProgressProvider = Provider.family<TaskProgressUpdate?, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.taskProgress[taskId];
});

final downloadTaskCompletionProvider = Provider.family<bool, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.completedTasks.contains(taskId);
});

final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final catalogNotifier = ref.read(catalogProvider.notifier);
  return DownloadNotifier(ref, catalogNotifier);
});

class DownloadNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  final Map<String, DownloadTask> _tasks = {};
  StreamSubscription<TaskUpdate>? _updateSubscription;

  final DownloadService downloadService = DownloadService();
  final CatalogNotifier catalogNotifier;

  DownloadNotifier(this._ref, this.catalogNotifier) : super(const DownloadState()) {
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

    _listenToStateChanges();
    final appState = _ref.read(appStateProvider);
    final catalogState = _ref.read(catalogProvider);
    if (catalogState.games.isNotEmpty && appState.downloadDir.isNotEmpty) {
      _checkCompletedFiles(catalogState.games, appState.downloadDir);
    }
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    taskStatus[update.task.taskId] = update.status;

    final completedTasks = Set<String>.from(state.completedTasks);
    if (update.status == TaskStatus.complete) {
      completedTasks.add(update.task.taskId);
      catalogNotifier.deselectGame(update.task.taskId);
      debugPrint('Download completed for ${update.task.taskId}');
    }

    state = state.copyWith(
      taskStatus: taskStatus,
      completedTasks: completedTasks,
    );

    _updateDownloadingState();
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final taskProgress = Map<String, TaskProgressUpdate>.from(state.taskProgress);

    taskProgress[update.task.taskId] = update;

    state = state.copyWith(
      taskProgress: taskProgress,
    );
  }

  void _updateDownloadingState() {
    final hasActiveDownloads = state.taskStatus.values.any((status) => status == TaskStatus.running || status == TaskStatus.enqueued);

    if (state.downloading != hasActiveDownloads) {
      state = state.copyWith(downloading: hasActiveDownloads);
    }
  }

  void _listenToStateChanges() {
    _ref.listen<AppState>(appStateProvider, (previous, next) {
      if (previous == null || previous.downloadDir != next.downloadDir) {
        final catalogState = _ref.read(catalogProvider);
        if (catalogState.games.isNotEmpty && next.downloadDir.isNotEmpty) {
          _checkCompletedFiles(catalogState.games, next.downloadDir);
        }
      }
    });

    _ref.listen<CatalogState>(catalogProvider, (previous, next) {
      if (previous == null || previous.games != next.games) {
        final appState = _ref.read(appStateProvider);
        if (next.games.isNotEmpty && appState.downloadDir.isNotEmpty) {
          _checkCompletedFiles(next.games, appState.downloadDir);
        }
      }
    });
  }

  // TODO1: Maybe this belongs somewhere else like in Catalog
  Future<void> _checkCompletedFiles(List<Game> catalog, String downloadDir) async {
    final completedTasks = <String>{};

    for (final game in catalog) {
      final filePath = path.join(downloadDir, game.filename);
      if (File(filePath).existsSync()) {
        completedTasks.add(game.taskId);
      }
    }

    state = state.copyWith(completedTasks: completedTasks);
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
    final catalogState = _ref.read(catalogProvider);
    if (catalogState.selectedGames.isEmpty) return;

    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);

    debugPrint('Starting downloads to directory: $downloadDir');

    try {
      for (final taskId in catalogState.selectedGames) {
        if (!isTaskDownloadable(taskId)) continue;

        final parts = taskId.split('/');
        if (parts.length != 2) continue;

        final fileName = parts[1];
        final game = games.firstWhere(
          (g) => g.filename == fileName,
          orElse: () => throw Exception('Game not found for taskId: $taskId'),
        );

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
      // _updateDownloadingState();
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
  }

  bool hasDownloadableSelectedGames() {
    final catalogState = _ref.read(catalogProvider);
    return catalogState.selectedGames.any((taskId) => isTaskDownloadable(taskId));
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }
}
