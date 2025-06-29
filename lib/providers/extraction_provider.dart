import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/extraction_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/services/extraction_service.dart';

final extractionProvider = StateNotifierProvider<ExtractionNotifier, ExtractionState>((ref) {
  final gameStateManager = ref.read(gameStateManagerProvider.notifier);
  return ExtractionNotifier(ref, gameStateManager);
});

class ExtractionNotifier extends StateNotifier<ExtractionState> {
  final Ref _ref;
  final ExtractionService _extractionService = ExtractionService();
  final GameStateManager gameStateManager;

  ExtractionNotifier(this._ref, this.gameStateManager) : super(const ExtractionState());

  bool _canExtract(String taskId) {
    final game = _findGameByTaskId(taskId);
    if (game == null) return false;

    final downloadDir = _ref.read(appStateProvider).downloadDir;
    final filePath = path.join(downloadDir, game.filename);
    final file = File(filePath);

    return file.existsSync() && _extractionService.isCompressedFile(filePath);
  }

  void extractFile(String taskId) {
    final game = _findGameByTaskId(taskId);
    if (game == null) {
      debugPrint('Game not found for taskId: $taskId');
      return;
    }

    final downloadDir = _ref.read(appStateProvider).downloadDir;
    final filePath = path.join(downloadDir, game.filename);

    if (!_canExtract(taskId)) {
      debugPrint('Cannot extract file: $filePath');
      return;
    }

    final tasks = Map<String, ExtractionTaskState>.from(state.tasks);
    tasks[taskId] = ExtractionTaskState(
      taskId: taskId,
      status: ExtractionStatus.extracting,
      progress: 0.0,
    );

    state = state.copyWith(
      tasks: tasks,
      isExtracting: _hasActiveExtractions(tasks),
    );

    gameStateManager.updateExtractionState(taskId, ExtractionStatus.extracting, 0.0);

    debugPrint('Starting extraction for: $filePath');

    try {
      _extractionService.extractFile(
        filePath: filePath,
        onProgress: (progress) {
          _updateProgress(taskId, progress);
        },
        onError: (error) {
          _updateError(taskId, error);
        },
      );
    } catch (e) {
      debugPrint('Extraction error: $e');
      _updateError(taskId, e.toString());
    }
  }

  void retryExtraction(String taskId) {
    final taskState = state.getTaskState(taskId);
    if (taskState?.status == ExtractionStatus.failed) {
      extractFile(taskId);
    }
  }

  void _updateProgress(String taskId, double progress) {
    debugPrint('Updating progress for task $taskId: $progress');
    final tasks = Map<String, ExtractionTaskState>.from(state.tasks);
    final currentTask = tasks[taskId];
    if (currentTask != null) {
      tasks[taskId] = currentTask.copyWith(progress: progress);
      state = state.copyWith(tasks: tasks);
    }

    gameStateManager.updateExtractionState(taskId, ExtractionStatus.extracting, progress);

    if (progress >= 1.0) {
      _updateCompleted(taskId);
    }
  }

  void _updateCompleted(String taskId) {
    debugPrint('Marking task $taskId as completed');
    final tasks = Map<String, ExtractionTaskState>.from(state.tasks);
    final currentTask = tasks[taskId];
    if (currentTask != null) {
      tasks[taskId] = currentTask.copyWith(
        status: ExtractionStatus.completed,
        progress: 1.0,
      );
      state = state.copyWith(
        tasks: tasks,
        isExtracting: _hasActiveExtractions(tasks),
      );
    }

    gameStateManager.updateExtractionState(taskId, ExtractionStatus.completed, 1.0);

    try {
      _deleteOriginalFile(taskId);
    } catch (e) {
      debugPrint('Error deleting original file for task $taskId: $e');
    }
  }

  Future<void> _deleteOriginalFile(String taskId) async {
    final game = _findGameByTaskId(taskId);
    if (game == null) return;

    final downloadDir = _ref.read(appStateProvider).downloadDir;
    final filePath = path.join(downloadDir, game.filename);

    if (await _extractionService.deleteOriginalFile(filePath)) {
      debugPrint('Deleted original file: $filePath');
    } else {
      debugPrint('Failed to delete original file: $filePath');
    }
  }

  void _updateError(String taskId, String error) {
    final tasks = Map<String, ExtractionTaskState>.from(state.tasks);
    final currentTask = tasks[taskId];
    if (currentTask != null) {
      tasks[taskId] = currentTask.copyWith(
        status: ExtractionStatus.failed,
        error: error,
      );
      state = state.copyWith(
        tasks: tasks,
        isExtracting: _hasActiveExtractions(tasks),
      );
    }

    gameStateManager.updateExtractionState(taskId, ExtractionStatus.failed, 0.0);
  }

  bool _hasActiveExtractions(Map<String, ExtractionTaskState> tasks) {
    return tasks.values.any((task) => task.status == ExtractionStatus.extracting);
  }

  Game? _findGameByTaskId(String taskId) {
    final catalogState = _ref.read(catalogProvider);
    try {
      return catalogState.games.firstWhere((game) => game.taskId == taskId);
    } catch (e) {
      return null;
    }
  }
}
