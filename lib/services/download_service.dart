import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

class DownloadService {
  final Map<String, DownloadTask> _tasks = {};

  void registerTask(String taskId, DownloadTask task) {
    _tasks[taskId] = task;
  }

  DownloadTask? getTask(String taskId) {
    return _tasks[taskId];
  }

  Future<bool> pauseTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      return await FileDownloader().pause(task);
    }
    return false;
  }

  Future<bool> resumeTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      return await FileDownloader().resume(task);
    }
    return false;
  }

  Future<bool> cancelTask(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      final removed = await FileDownloader().cancelTaskWithId(taskId);
      if (removed) {
        _tasks.remove(taskId);
        return true;
      }
    }
    return false;
  }
}
