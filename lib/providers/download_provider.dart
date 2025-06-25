import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';

final taskStatusProvider = Provider.family<TaskStatus?, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.taskStatus[taskId];
});

final taskProgressProvider = Provider.family<double?, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.taskProgress[taskId];
});

final taskCompletionProvider = Provider.family<bool, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.completedTasks.contains(taskId);
});

final taskSelectionProvider = Provider.family<bool, String>((ref, taskId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.selectedTasks.contains(taskId);
});

final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier(ref);
});

class DownloadNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  final Map<String, DownloadTask> _tasks = {};
  StreamSubscription<TaskUpdate>? _updateSubscription;

  final DownloadService downloadService = DownloadService();

  DownloadNotifier(this._ref) : super(const DownloadState()) {
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

    _listenToAppStateChanges();
    final appState = _ref.read(appStateProvider);
    if (appState.catalog.isNotEmpty && appState.downloadDir.isNotEmpty) {
      _checkCompletedFiles(appState.catalog, appState.downloadDir);
    }
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);
    taskStatus[update.task.taskId] = update.status;

    final completedTasks = Set<String>.from(state.completedTasks);
    if (update.status == TaskStatus.complete) {
      completedTasks.add(update.task.taskId);
      toggleTaskSelection(update.task.taskId);
      debugPrint('Download completed for ${update.task.taskId}');
    }

    state = state.copyWith(
      taskStatus: taskStatus,
      completedTasks: completedTasks,
    );

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

  void _listenToAppStateChanges() {
    _ref.listen<AppState>(appStateProvider, (previous, next) {
      if (previous == null || previous.catalog != next.catalog || previous.downloadDir != next.downloadDir) {
        if (next.catalog.isNotEmpty && next.downloadDir.isNotEmpty) {
          _checkCompletedFiles(next.catalog, next.downloadDir);
        }
      }
    });
  }

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

  void toggleTaskSelection(String taskId) {
    final selectedTasks = Set<String>.from(state.selectedTasks);

    if (selectedTasks.contains(taskId)) {
      selectedTasks.remove(taskId);
    } else {
      selectedTasks.add(taskId);
    }

    state = state.copyWith(selectedTasks: selectedTasks);
  }

  Future<void> startDownloads(List<Game> games, String downloadDir, String? group) async {
    if (state.selectedTasks.isEmpty || state.downloading) return;

    final taskStatus = Map<String, TaskStatus>.from(state.taskStatus);

    debugPrint('Starting downloads to directory: $downloadDir');

    try {
      for (final taskId in state.selectedTasks) {
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

      state = state.copyWith(taskStatus: taskStatus, downloading: true);
    } catch (e) {
      debugPrint('Error starting downloads: $e');
    }
  }

  Future<void> startSelectedDownloads(String downloadDir, String? group) async {
    if (state.selectedTasks.isEmpty || state.downloading) return;

    final appState = _ref.read(appStateProvider);
    final games = appState.catalog.where((game) => state.selectedTasks.contains(game.taskId)).toList();

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
    final taskProgress = Map<String, double>.from(state.taskProgress);
    final selectedTasks = Set<String>.from(state.selectedTasks);

    taskStatus.remove(taskId);
    taskProgress.remove(taskId);
    selectedTasks.remove(taskId);
    _tasks.remove(taskId);

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
