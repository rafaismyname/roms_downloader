import 'package:background_downloader/background_downloader.dart';

class DownloadState {
  final Map<String, TaskStatus> taskStatus;
  final Map<String, double> taskProgress;
  final Set<String> selectedTasks;
  final Set<String> completedTasks;
  final bool downloading;

  const DownloadState({
    this.taskStatus = const {},
    this.taskProgress = const {},
    this.selectedTasks = const {},
    this.completedTasks = const {},
    this.downloading = false,
  });

  DownloadState copyWith({
    Map<String, TaskStatus>? taskStatus,
    Map<String, double>? taskProgress,
    Set<String>? selectedTasks,
    Set<String>? completedTasks,
    bool? downloading,
  }) {
    return DownloadState(
      taskStatus: taskStatus ?? this.taskStatus,
      taskProgress: taskProgress ?? this.taskProgress,
      selectedTasks: selectedTasks ?? this.selectedTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      downloading: downloading ?? this.downloading,
    );
  }
}
