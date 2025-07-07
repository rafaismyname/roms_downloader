import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/providers/task_queue_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/models/game_model.dart';

class TaskQueueService {
  Future<void> executeTask(Ref ref, TaskQueueNotifier notifier, QueuedTask task) async {
    try {
      switch (task.type) {
        case TaskType.download:
          await _executeDownloadTask(ref, task, notifier);
          break;
        case TaskType.extraction:
          await _executeExtractionTask(ref, task, notifier);
          break;
      }
    } catch (e) {
      debugPrint('Task execution error for ${task.id}: $e');
      notifier.updateTaskStatus(task.id, TaskQueueStatus.failed, error: e.toString());
    }
  }

  Future<void> _executeDownloadTask(Ref ref, QueuedTask task, TaskQueueNotifier notifier) async {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final game = Game.fromJson(task.params['game']);
    final downloadDir = task.params['downloadDir'] as String;
    final group = task.params['group'] as String;
    
    await downloadNotifier.executeDownload(game, downloadDir, group);
    notifier.updateTaskStatus(task.id, TaskQueueStatus.completed);
  }

  Future<void> _executeExtractionTask(Ref ref, QueuedTask task, TaskQueueNotifier notifier) async {
    final extractionNotifier = ref.read(extractionProvider.notifier);
    final taskId = task.params['taskId'] as String;
    
    extractionNotifier.extractFile(taskId);
    notifier.updateTaskStatus(task.id, TaskQueueStatus.completed);
  }

  void cancelTask(QueuedTask task) {
    switch (task.type) {
      case TaskType.download:
        debugPrint('Cancelling download task: ${task.id}');
        break;
      case TaskType.extraction:
        debugPrint('Cancelling extraction task: ${task.id}');
        break;
    }
  }
}
