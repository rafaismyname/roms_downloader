enum ExtractionStatus {
  idle,
  extracting,
  completed,
  failed,
}

class ExtractionTaskState {
  final String taskId;
  final ExtractionStatus status;
  final double progress;
  final String? error;

  const ExtractionTaskState({
    required this.taskId,
    this.status = ExtractionStatus.idle,
    this.progress = 0.0,
    this.error,
  });

  ExtractionTaskState copyWith({
    String? taskId,
    ExtractionStatus? status,
    double? progress,
    String? error,
  }) {
    return ExtractionTaskState(
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}

class ExtractionState {
  final Map<String, ExtractionTaskState> tasks;
  final bool isExtracting;

  const ExtractionState({
    this.tasks = const {},
    this.isExtracting = false,
  });

  ExtractionState copyWith({
    Map<String, ExtractionTaskState>? tasks,
    bool? isExtracting,
  }) {
    return ExtractionState(
      tasks: tasks ?? this.tasks,
      isExtracting: isExtracting ?? this.isExtracting,
    );
  }

  ExtractionTaskState? getTaskState(String taskId) {
    return tasks[taskId];
  }

  bool isTaskExtracting(String taskId) {
    final task = getTaskState(taskId);
    return task?.status == ExtractionStatus.extracting;
  }

  bool isTaskCompleted(String taskId) {
    final task = getTaskState(taskId);
    return task?.status == ExtractionStatus.completed;
  }

  bool isTaskFailed(String taskId) {
    final task = getTaskState(taskId);
    return task?.status == ExtractionStatus.failed;
  }
}
