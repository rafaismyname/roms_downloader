import 'package:background_downloader/background_downloader.dart';

class DownloadService {
  Future<FileDownloader> initialize() async {
    await FileDownloader().trackTasks();

    FileDownloader().configure(
      globalConfig: [
        (Config.holdingQueue, true),
        (Config.requestTimeout, 60),
        (Config.resourceTimeout, 3600),
      ],
      androidConfig: [
        (Config.useCacheDir, Config.never),
        (Config.runInForeground, Config.always),
      ],
    );

    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading ROM: {filename}',
        'Progress: {progress} • {networkSpeed} • {timeRemaining}',
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

    return FileDownloader();
  }
  
  DownloadTask createDownloadTask({
    required String taskId,
    required String url,
    required String fileName,
    required String directory,
    String group = 'default',
  }) {
    return DownloadTask(
      taskId: taskId,
      url: url,
      filename: fileName,
      baseDirectory: BaseDirectory.root,
      directory: directory,
      group: group,
      updates: Updates.statusAndProgress,
      allowPause: true,
      priority: 5,
      retries: 3,
    );
  }

  Future<bool> enqueuedTask(DownloadTask task) async {
    return FileDownloader().enqueue(task);
  }

  Future<bool> pauseTask(DownloadTask task) async {
    return await FileDownloader().pause(task);
  }

  Future<bool> resumeTask(DownloadTask task) async {
    return await FileDownloader().resume(task);
  }

  Future<bool> cancelTask(DownloadTask task) async {
    return await FileDownloader().cancel(task);
  }

  Future<bool> cancelTaskById(String taskId) async {
    return await FileDownloader().cancelTaskWithId(taskId);
  }
}
