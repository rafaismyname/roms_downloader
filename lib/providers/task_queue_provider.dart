import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/services/task_queue_service.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';

final taskQueueProvider = StateNotifierProvider<TaskQueueNotifier, TaskQueueState>((ref) {
  return TaskQueueNotifier(ref);
});

class TaskQueueNotifier extends StateNotifier<TaskQueueState> {
  final Ref _ref;
  Timer? _processingTimer;

  TaskQueueNotifier(this._ref) : super(const TaskQueueState()) {
    _startProcessing();
  }

  void enqueue(String taskId, TaskType type, Map<String, dynamic> params) {
    final task = QueuedTask(
      id: taskId,
      type: type,
      params: params,
      createdAt: DateTime.now(),
    );

    final updatedTasks = [...state.tasks, task];
    state = state.copyWith(tasks: updatedTasks);

    final gameStateManager = _ref.read(gameStateManagerProvider.notifier);
    gameStateManager.updateQueueState(taskId, type);

    _startTimerIfNeeded();
    _processQueue();
  }

  void updateTaskStatus(String taskId, TaskQueueStatus status, {String? error}) {
    final updatedTasks = state.tasks.map((currentTask) {
      if (currentTask.id == taskId) {
        return currentTask.copyWith(
          status: status,
          startedAt: status == TaskQueueStatus.running ? DateTime.now() : currentTask.startedAt,
          completedAt: status.isCompleted ? DateTime.now() : currentTask.completedAt,
          error: error,
        );
      }
      return currentTask;
    }).toList();

    final runningCounts = <TaskType, int>{};
    for (final task in updatedTasks) {
      if (task.status == TaskQueueStatus.running) {
        runningCounts[task.type] = (runningCounts[task.type] ?? 0) + 1;
      }
    }

    state = state.copyWith(
      tasks: updatedTasks,
      runningCounts: runningCounts,
    );

    _processQueue();
  }

  void _startProcessing() {
    _processingTimer ??= Timer.periodic(const Duration(seconds: 2), (_) => _processQueue());
  }

  void _stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  void _startTimerIfNeeded() {
    if (_processingTimer == null) {
      _startProcessing();
    }
  }

  void _processQueue() async {
    if (state.isProcessing) return;
    debugPrint('Processing task queue...');
    state = state.copyWith(isProcessing: true);

    try {
      final settingsNotifier = _ref.read(settingsProvider.notifier);
      final maxDownloads = settingsNotifier.getMaxParallelDownloads();
      final maxExtractions = settingsNotifier.getMaxParallelExtractions();

      final limits = {
        TaskType.download: maxDownloads,
        TaskType.extraction: maxExtractions,
      };

      for (final type in TaskType.values) {
        final runningCount = state.runningCounts[type] ?? 0;
        final maxCount = limits[type] ?? 1;
        final availableSlots = maxCount - runningCount;

        if (availableSlots > 0) {
          final waitingTasks = state.tasks.where((task) => task.type == type && task.status == TaskQueueStatus.waiting).take(availableSlots);

          for (final task in waitingTasks) {
            updateTaskStatus(task.id, TaskQueueStatus.running);

            TaskQueueService.executeTask(_ref, this, task).catchError((e) {
              updateTaskStatus(task.id, TaskQueueStatus.failed, error: e.toString());
            });
          }
        }
      }

      if (!_hasPendingTasks()) {
        _stopProcessing();
      }
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  void cancelQueuedTask(String taskId) {
    final remaining = state.tasks.where((t) => !(t.id == taskId && t.status == TaskQueueStatus.waiting)).toList();
    final runningCounts = Map<TaskType, int>.from(state.runningCounts);

    state = state.copyWith(tasks: remaining, runningCounts: runningCounts);

    final gameStateManager = _ref.read(gameStateManagerProvider.notifier);
    gameStateManager.resolveState(taskId);

    if (_hasPendingTasks()) {
      _startTimerIfNeeded();
    }
  }

  bool _hasPendingTasks() {
    return state.tasks.any((task) => task.status == TaskQueueStatus.waiting || task.status == TaskQueueStatus.running);
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }
}

extension on TaskQueueStatus {
  bool get isCompleted => this == TaskQueueStatus.completed || this == TaskQueueStatus.failed || this == TaskQueueStatus.cancelled;
}
