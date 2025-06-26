import 'package:background_downloader/background_downloader.dart';

enum GameDownloadStatus {
  ready,
  queued,
  downloading,
  processing,
  completed,
  inLibrary,
  error,
  paused,
}

class GameStateService {
  GameDownloadStatus getStatusFromTaskStatus(TaskStatus? taskStatus, bool isCompleted) {
    if (isCompleted) return GameDownloadStatus.inLibrary;

    switch (taskStatus) {
      case TaskStatus.enqueued:
        return GameDownloadStatus.queued;
      case TaskStatus.running:
        return GameDownloadStatus.downloading;
      case TaskStatus.complete:
        return GameDownloadStatus.completed;
      case TaskStatus.paused:
        return GameDownloadStatus.paused;
      case TaskStatus.failed:
        return GameDownloadStatus.error;
      case TaskStatus.notFound:
        return GameDownloadStatus.error;
      case TaskStatus.waitingToRetry:
        return GameDownloadStatus.queued;
      default:
        return GameDownloadStatus.ready;
    }
  }

  String getDisplayStatusFromTaskStatus(TaskStatus? taskStatus, bool isCompleted) {
    final status = getStatusFromTaskStatus(taskStatus, isCompleted);
    switch (status) {
      case GameDownloadStatus.ready:
        return "Ready";
      case GameDownloadStatus.queued:
        return "Queued";
      case GameDownloadStatus.downloading:
        return "Downloading";
      case GameDownloadStatus.processing:
        return "Processing";
      case GameDownloadStatus.completed:
        return "Complete";
      case GameDownloadStatus.inLibrary:
        return "In Library";
      case GameDownloadStatus.paused:
        return "Paused";
      case GameDownloadStatus.error:
        return "Error";
    }
  }

  bool isInteractableFromTaskStatus(TaskStatus? taskStatus, bool isCompleted) {
    final status = getStatusFromTaskStatus(taskStatus, isCompleted);
    return status == GameDownloadStatus.ready || status == GameDownloadStatus.error;
  }

  bool shouldShowProgressBarFromTaskStatus(TaskStatus? taskStatus, bool isCompleted) {
    if (isCompleted) return false;
    switch (taskStatus) {
      case TaskStatus.running:
      case TaskStatus.enqueued:
      case TaskStatus.waitingToRetry:
      case TaskStatus.paused:
        return true;
      default:
        return false;
    }
  }
}
