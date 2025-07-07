import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/services/task_queue_service.dart';
import 'package:roms_downloader/providers/settings_provider.dart';

final taskQueueProvider = StateNotifierProvider<TaskQueueNotifier, TaskQueueState>((ref) {
  return TaskQueueNotifier(ref);
});

class TaskQueueNotifier extends StateNotifier<TaskQueueState> {
  final Ref _ref;
  final TaskQueueService _service = TaskQueueService();
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
    _processQueue();
  }

  void updateTaskStatus(String taskId, TaskQueueStatus status, {String? error}) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          status: status,
          startedAt: status == TaskQueueStatus.running ? DateTime.now() : task.startedAt,
          completedAt: status.isCompleted ? DateTime.now() : task.completedAt,
          error: error,
        );
      }
      return task;
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

    if (status.isCompleted) {
      _processQueue();
    }
  }

  void cancelTask(String taskId) {
    final task = state.tasks.firstWhere((t) => t.id == taskId, orElse: () => throw ArgumentError('Task not found'));
    
    if (task.status == TaskQueueStatus.running) {
      _service.cancelTask(task);
    }
    
    updateTaskStatus(taskId, TaskQueueStatus.cancelled);
  }

  void retryTask(String taskId) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == taskId && task.status == TaskQueueStatus.failed) {
        return task.copyWith(
          status: TaskQueueStatus.waiting,
          error: null,
          startedAt: null,
          completedAt: null,
        );
      }
      return task;
    }).toList();

    state = state.copyWith(tasks: updatedTasks);
    _processQueue();
  }

  void _startProcessing() {
    _processingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _processQueue());
  }

  void _processQueue() async {
    if (state.isProcessing) return;

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
          final waitingTasks = state.tasks
              .where((task) => task.type == type && task.status == TaskQueueStatus.waiting)
              .take(availableSlots);

          for (final task in waitingTasks) {
            updateTaskStatus(task.id, TaskQueueStatus.running);
            _service.executeTask(_ref, this, task);
          }
        }
      }
    } finally {
      state = state.copyWith(isProcessing: false);
    }
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
