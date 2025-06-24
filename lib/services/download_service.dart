import 'package:flutter/foundation.dart';
import 'package:background_downloader/background_downloader.dart';
class DownloadService {

  Future<FileDownloader> initialize() async {
    await FileDownloader().trackTasks();

    await _requestNotificationPermissions();

    FileDownloader().configure(
      globalConfig: [
        (Config.holdingQueue, true),
        (Config.requestTimeout, 60),
        (Config.resourceTimeout, 3600),
      ],
      androidConfig: [
        (Config.useCacheDir, Config.never),
        // (Config.useExternalStorage, Config.whenAble),
        (Config.runInForeground, Config.whenAble),
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

  // TODO1: implement notification service
  Future<void> _requestNotificationPermissions() async {
    try {
      final permissionStatus = await FileDownloader().permissions.status(PermissionType.notifications);
      if (permissionStatus != PermissionStatus.granted) {
        await FileDownloader().permissions.request(PermissionType.notifications);
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
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
}
