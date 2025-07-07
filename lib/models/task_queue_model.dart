enum TaskType { download, extraction }

enum TaskQueueStatus { waiting, running, completed, failed, cancelled }

class QueuedTask {
  final String id;
  final TaskType type;
  final TaskQueueStatus status;
  final Map<String, dynamic> params;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? error;

  const QueuedTask({
    required this.id,
    required this.type,
    this.status = TaskQueueStatus.waiting,
    this.params = const {},
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.error,
  });

  QueuedTask copyWith({
    String? id,
    TaskType? type,
    TaskQueueStatus? status,
    Map<String, dynamic>? params,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
  }) {
    return QueuedTask(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      params: params ?? this.params,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }
}

class TaskQueueState {
  final List<QueuedTask> tasks;
  final Map<TaskType, int> runningCounts;
  final bool isProcessing;

  const TaskQueueState({
    this.tasks = const [],
    this.runningCounts = const {},
    this.isProcessing = false,
  });

  TaskQueueState copyWith({
    List<QueuedTask>? tasks,
    Map<TaskType, int>? runningCounts,
    bool? isProcessing,
  }) {
    return TaskQueueState(
      tasks: tasks ?? this.tasks,
      runningCounts: runningCounts ?? this.runningCounts,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
