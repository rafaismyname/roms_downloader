import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/task_queue_model.dart';
import 'package:roms_downloader/providers/task_queue_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';

class TaskQueueService {
  static void startDownloads(WidgetRef ref, List<Game> games, String? consoleId) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final downloadDir = settingsNotifier.getDownloadDir(consoleId);
    final queueNotifier = ref.read(taskQueueProvider.notifier);

    for (final game in games) {
      queueNotifier.enqueue(game.gameId, TaskType.download, {
        'game': game.toJson(),
        'downloadDir': downloadDir,
        'group': consoleId ?? 'default',
      });
    }
  }

  static void startExtraction(WidgetRef ref, String taskId) {
    final queueNotifier = ref.read(taskQueueProvider.notifier);
    queueNotifier.enqueue(taskId, TaskType.extraction, {'taskId': taskId});
  }

  static void cancelTask(WidgetRef ref, Game game, GameState gameState) {
    final taskId = game.gameId;

    if (gameState.status == GameStatus.downloading || gameState.status == GameStatus.downloadPaused || gameState.status == GameStatus.downloadFailed) {
      final downloadNotifier = ref.read(downloadProvider.notifier);
      downloadNotifier.cancelTask(taskId);
      return;
    }

    final queueState = ref.read(taskQueueProvider);
    final hasQueued = queueState.tasks.any((t) => t.id == taskId && (t.status == TaskQueueStatus.waiting || t.status == TaskQueueStatus.failed));
    if (!hasQueued) return;

    final queueNotifier = ref.read(taskQueueProvider.notifier);
    queueNotifier.cancelQueuedTask(taskId);
  }

  static void pauseDownloadTask(WidgetRef ref, String taskId) {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    downloadNotifier.pauseTask(taskId);
  }

  static void resumeDownloadTask(WidgetRef ref, String taskId) {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    downloadNotifier.resumeTask(taskId);
  }

  static Future<void> executeTask(Ref ref, TaskQueueNotifier notifier, QueuedTask task) async {
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

  static Future<void> _executeDownloadTask(Ref ref, QueuedTask task, TaskQueueNotifier notifier) async {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final game = Game.fromJson(task.params['game']);
    final downloadDir = task.params['downloadDir'] as String;
    final group = task.params['group'] as String;

    downloadNotifier.executeDownload(game, downloadDir, group);
  }

  static Future<void> _executeExtractionTask(Ref ref, QueuedTask task, TaskQueueNotifier notifier) async {
    final extractionNotifier = ref.read(extractionProvider.notifier);
    final taskId = task.params['taskId'] as String;

    extractionNotifier.extractFile(taskId);
  }
}
