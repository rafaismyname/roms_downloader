import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/models/extraction_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/services/extraction_service.dart';
import 'package:roms_downloader/services/directory_service.dart';

final gameStateProvider = Provider.family<GameState, String>((ref, gameId) {
  return ref.watch(gameStateManagerProvider)[gameId] ?? const GameState();
});

final gameStateManagerProvider = StateNotifierProvider<GameStateManager, Map<String, GameState>>((ref) {
  return GameStateManager(ref);
});

class GameStateManager extends StateNotifier<Map<String, GameState>> {
  final Ref _ref;
  final ExtractionService _extractionService = ExtractionService();

  GameStateManager(this._ref) : super({}) {
    _ref.listen(downloadProvider, (_, next) => _syncFromDownload(next));
    _ref.listen(extractionProvider, (_, next) => _syncFromExtraction(next));
    _ref.listen(appStateProvider, (prev, next) {
      if (prev?.downloadDir != next.downloadDir) _refreshFileStates();
    });
    _ref.listen(catalogProvider, (prev, next) {
      if (prev?.games != next.games) _initGames(next.games);
      if (prev?.selectedGames != next.selectedGames) _updateSelections(next.selectedGames);
    });
  }

  void _initGames(List<Game> games) {
    final downloadDir = _ref.read(appStateProvider).downloadDir;
    if (downloadDir.isEmpty) return;

    final updates = <String, GameState>{};
    for (final game in games) {
      if (!state.containsKey(game.taskId)) {
        updates[game.taskId] = GameState(
          status: GameStatus.loading,
          isInteractable: false,
          availableActions: {GameAction.loading},
        );
      }
    }

    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  void resolveFileState(String gameId) {
    final game = _findGame(gameId);
    if (game == null) return;
    
    final downloadDir = _ref.read(appStateProvider).downloadDir;
    _resolveFileState(game, downloadDir);
  }

  void _resolveFileState(Game game, String downloadDir) async {
    try {
      final data = (filename: game.filename, downloadDir: downloadDir);
      final result = await compute(DirectoryService().computeFileCheck, data);

      if (mounted) {
        final status = result.hasExtracted
            ? GameStatus.extracted
            : result.hasFile
                ? GameStatus.downloaded
                : GameStatus.ready;

        final updated = state[game.taskId]?.copyWith(
          status: status,
          fileExists: result.hasFile,
          extractedContentExists: result.hasExtracted,
          isInteractable: status == GameStatus.ready,
          availableActions: _getActions(status, game),
        );

        if (updated != null) {
          state = {...state, game.taskId: updated};
        }
      }
    } catch (_) {
      if (mounted) {
        final updated = state[game.taskId]?.copyWith(
          status: GameStatus.ready,
          isInteractable: true,
          availableActions: {GameAction.download},
        );

        if (updated != null) {
          state = {...state, game.taskId: updated};
        }
      }
    }
  }

  void _updateSelections(Set<String> selected) {
    final updates = <String, GameState>{};
    for (final entry in state.entries) {
      final isSelected = selected.contains(entry.key);
      if (entry.value.isSelected != isSelected) {
        updates[entry.key] = entry.value.copyWith(isSelected: isSelected);
      }
    }

    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  void _syncFromDownload(DownloadState downloadState) {
    final catalog = _ref.read(catalogProvider);
    final updates = <String, GameState>{};

    for (final game in catalog.games) {
      final current = state[game.taskId] ?? const GameState();
      final taskStatus = downloadState.taskStatus[game.taskId];
      final progress = downloadState.taskProgress[game.taskId];
      final isCompleted = downloadState.completedTasks.contains(game.taskId);

      final updated = _updateFromDownload(current, taskStatus, progress, isCompleted, game);
      if (updated != current) {
        updates[game.taskId] = updated;
      }
    }

    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  GameState _updateFromDownload(GameState current, TaskStatus? status, TaskProgressUpdate? progress, bool completed, Game game) {
    if (current.status == GameStatus.extracting) return current;

    if (completed) {
      final downloadDir = _ref.read(appStateProvider).downloadDir;
      _resolveFileState(game, downloadDir);
      return current.copyWith(
        status: GameStatus.loading,
        downloadProgress: 1.0,
        currentProgress: 1.0,
        showProgressBar: false,
        isInteractable: false,
        availableActions: {GameAction.loading},
      );
    }

    return switch (status) {
      TaskStatus.enqueued => current.copyWith(
          status: GameStatus.downloadQueued,
          downloadProgress: 0.0,
          currentProgress: 0.0,
          showProgressBar: true,
          isInteractable: false,
          availableActions: {GameAction.cancel},
        ),
      TaskStatus.running => current.copyWith(
          status: GameStatus.downloading,
          downloadProgress: progress?.progress ?? 0.0,
          currentProgress: progress?.progress ?? 0.0,
          networkSpeed: progress?.networkSpeed ?? 0.0,
          timeRemaining: progress?.timeRemaining ?? Duration.zero,
          showProgressBar: true,
          isInteractable: false,
          availableActions: {GameAction.pause, GameAction.cancel},
        ),
      TaskStatus.paused => current.copyWith(
          status: GameStatus.downloadPaused,
          isInteractable: false,
          availableActions: {GameAction.resume, GameAction.cancel},
        ),
      TaskStatus.failed => current.copyWith(
          status: GameStatus.downloadFailed,
          isInteractable: true,
          showProgressBar: false,
          availableActions: {GameAction.retryDownload},
          errorMessage: 'Download failed',
        ),
      _ => current.status == GameStatus.extracted || current.status == GameStatus.downloaded
          ? current
          : current.copyWith(
              status: GameStatus.ready,
              downloadProgress: 0.0,
              currentProgress: 0.0,
              showProgressBar: false,
              isInteractable: true,
              availableActions: {GameAction.download},
            ),
    };
  }

  void _syncFromExtraction(ExtractionState extractionState) {
    final updates = <String, GameState>{};
    for (final entry in state.entries) {
      final taskId = entry.key;
      final current = entry.value;
      final extractionTask = extractionState.getTaskState(taskId);

      final updated = _updateFromExtraction(current, extractionTask, taskId);
      if (updated != current) {
        updates[taskId] = updated;
      }
    }

    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  GameState _updateFromExtraction(GameState current, ExtractionTaskState? task, String taskId) {
    if (task == null || current.status == GameStatus.downloading) return current;

    return switch (task.status) {
      ExtractionStatus.extracting => current.copyWith(
          status: GameStatus.extracting,
          extractionProgress: task.progress,
          currentProgress: task.progress,
          showProgressBar: true,
          isInteractable: false,
          availableActions: {GameAction.loading},
        ),
      ExtractionStatus.completed => _handleExtractionComplete(current, taskId),
      ExtractionStatus.failed => current.copyWith(
          status: GameStatus.extractionFailed,
          isInteractable: true,
          showProgressBar: false,
          availableActions: {GameAction.retryExtraction},
          errorMessage: task.error ?? 'Extraction failed',
        ),
      _ => current,
    };
  }

  GameState _handleExtractionComplete(GameState current, String taskId) {
    final game = _findGame(taskId);
    if (game != null) {
      final downloadDir = _ref.read(appStateProvider).downloadDir;
      _resolveFileState(game, downloadDir);
    }

    return current.copyWith(
      status: GameStatus.loading,
      extractionProgress: 1.0,
      currentProgress: 1.0,
      showProgressBar: false,
      isInteractable: false,
      availableActions: {GameAction.loading},
    );
  }

  void _refreshFileStates() {
    final downloadDir = _ref.read(appStateProvider).downloadDir;
    final games = _ref.read(catalogProvider).games;

    if (downloadDir.isEmpty) return;

    final updates = <String, GameState>{};
    for (final game in games) {
      final current = state[game.taskId] ?? const GameState();

      updates[game.taskId] = current.copyWith(
        status: GameStatus.loading,
        isInteractable: false,
        availableActions: {GameAction.loading},
      );

      _resolveFileState(game, downloadDir);
    }

    if (updates.isNotEmpty) {
      state = {...state, ...updates};
    }
  }

  String? _findInLibrary(Game game, String downloadDir) {
    try {
      final dir = Directory(downloadDir);
      if (!dir.existsSync()) return null;

      final filenameBase = path.basenameWithoutExtension(game.filename);
      final gameTitle = game.title;

      for (final entity in dir.listSync()) {
        final entityName = path.basename(entity.path);
        final entityBase = path.basenameWithoutExtension(entityName);

        if (entityBase == filenameBase || entityBase == gameTitle) {
          return entity.path;
        }
      }
    } catch (e) {
      debugPrint('Error finding similar file: $e');
    }
    return null;
  }

  Set<GameAction> _getActions(GameStatus status, Game game) {
    return switch (status) {
      GameStatus.ready => {GameAction.download},
      GameStatus.downloaded => _canExtract(game) ? {GameAction.extract} : const {},
      GameStatus.extracted => const {},
      GameStatus.downloadFailed => {GameAction.retryDownload},
      GameStatus.extractionFailed => {GameAction.retryExtraction},
      GameStatus.downloadPaused => {GameAction.resume, GameAction.cancel},
      GameStatus.downloading => {GameAction.pause, GameAction.cancel},
      GameStatus.extracting => {GameAction.loading},
      GameStatus.processing => {GameAction.loading},
      GameStatus.downloadQueued => {GameAction.loading},
      GameStatus.extractionQueued => {GameAction.loading},
      GameStatus.loading => {GameAction.loading},
    };
  }

  bool _canExtract(Game game) {
    final downloadDir = _ref.read(appStateProvider).downloadDir;
    final filePath = _findInLibrary(game, downloadDir) ?? path.join(downloadDir, game.filename);

    try {
      return _extractionService.isCompressedFile(filePath);
    } catch (_) {
      return false;
    }
  }

  Game? _findGame(String taskId) {
    try {
      return _ref.read(catalogProvider).games.firstWhere((g) => g.taskId == taskId);
    } catch (_) {
      return null;
    }
  }
}
