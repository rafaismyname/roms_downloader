import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/extraction_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/services/extraction_service.dart';
import 'package:roms_downloader/services/directory_service.dart';

final gameStateProvider = Provider.family<GameState, Game>((ref, game) {
  return ref.watch(gameStateManagerProvider)[game.taskId] ?? GameState(game: game);
});

final gameStateManagerProvider = StateNotifierProvider<GameStateManager, Map<String, GameState>>((ref) {
  return GameStateManager(ref);
});

class GameStateManager extends StateNotifier<Map<String, GameState>> {
  final Ref _ref;
  final Map<String, bool> _resolving = {};

  GameStateManager(this._ref) : super({}) {
    _ref.listen(catalogProvider, (prev, next) {
      if (prev?.games != next.games) _initGames(next.games);
      if (prev?.selectedGames != next.selectedGames) _updateSelections(next.selectedGames);
    });
  }

  void updateDownloadState(String gameId, TaskStatus? status, TaskProgressUpdate? progress, bool isCompleted) {
    final current = state[gameId];
    if (current == null || current.status == GameStatus.extracting) return;

    GameState? updated;
    if (isCompleted) {
      resolveFileState(gameId);
    } else if (status == TaskStatus.canceled) {
      updated = current.copyWith(
        status: GameStatus.ready,
        downloadProgress: 0.0,
        currentProgress: 0.0,
        networkSpeed: 0.0,
        timeRemaining: Duration.zero,
        showProgressBar: false,
        isInteractable: true,
        availableActions: {GameAction.download},
      );
    } else if (status == TaskStatus.running) {
      updated = current.copyWith(
        status: GameStatus.downloading,
        downloadProgress: progress?.progress ?? 0.0,
        currentProgress: progress?.progress ?? 0.0,
        networkSpeed: progress?.networkSpeed ?? 0.0,
        timeRemaining: progress?.timeRemaining ?? Duration.zero,
        showProgressBar: true,
        isInteractable: false,
        availableActions: {GameAction.pause, GameAction.cancel},
      );
    } else if (status == TaskStatus.enqueued) {
      updated = current.copyWith(
        status: GameStatus.downloadQueued,
        showProgressBar: true,
        isInteractable: false,
        availableActions: {GameAction.cancel},
      );
    } else if (status == TaskStatus.paused) {
      updated = current.copyWith(
        status: GameStatus.downloadPaused,
        isInteractable: false,
        availableActions: {GameAction.resume, GameAction.cancel},
      );
    } else if (status == TaskStatus.failed) {
      updated = current.copyWith(
        status: GameStatus.downloadFailed,
        isInteractable: true,
        showProgressBar: false,
        availableActions: {GameAction.retryDownload},
      );
    }

    if (updated != null && updated != current) {
      state = {...state, gameId: updated};
    }
  }

  void updateExtractionState(String gameId, ExtractionStatus status, double progress) {
    final current = state[gameId];
    if (current == null || current.status == GameStatus.downloading) return;

    GameState? updated;
    if (status == ExtractionStatus.extracting) {
      updated = current.copyWith(
        status: GameStatus.extracting,
        extractionProgress: progress,
        currentProgress: progress,
        showProgressBar: true,
        isInteractable: false,
        availableActions: {GameAction.loading},
      );
    } else if (status == ExtractionStatus.completed) {
      resolveFileState(gameId);
    } else if (status == ExtractionStatus.failed) {
      updated = current.copyWith(
        status: GameStatus.extractionFailed,
        isInteractable: true,
        showProgressBar: false,
        availableActions: {GameAction.retryExtraction},
      );
    }

    if (updated != null && updated != current) {
      state = {...state, gameId: updated};
    }
  }

  void _initGames(List<Game> games) {
    final updates = <String, GameState>{};
    for (final game in games) {
      // use taskId as game identifier for now
      if (!state.containsKey(game.taskId)) {
        updates[game.taskId] = GameState(game: game);
      }
    }
    if (updates.isNotEmpty) state = {...state, ...updates};
  }

  void resolveFileState(String gameId) async {
    if (_resolving[gameId] == true) return;

    final gameState = state[gameId];
    final downloadDir = _ref.read(appStateProvider).downloadDir;
    if (gameState == null || downloadDir.isEmpty) return;

    final game = gameState.game;
    _resolving[gameId] = true;
    _updateState(
        gameId,
        (s) => s.copyWith(
              status: GameStatus.loading,
              isInteractable: false,
              showProgressBar: false,
              availableActions: {GameAction.loading},
            ));

    try {
      final data = (filename: game.filename, downloadDir: downloadDir);
      final result = await compute(DirectoryService().computeFileCheck, data);

      final status = result.hasExtracted
          ? GameStatus.extracted
          : result.hasFile
              ? GameStatus.downloaded
              : GameStatus.ready;

      _updateState(
          gameId,
          (s) => s.copyWith(
                status: status,
                fileExists: result.hasFile,
                extractedContentExists: result.hasExtracted,
                showProgressBar: false,
                isInteractable: status == GameStatus.ready,
                availableActions: _getActions(status, game),
              ));
    } catch (_) {
      _updateState(
          gameId,
          (s) => s.copyWith(
                status: GameStatus.error,
                isInteractable: false,
                showProgressBar: false,
                availableActions: {},
              ));
    } finally {
      _resolving.remove(gameId);
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
    if (updates.isNotEmpty) state = {...state, ...updates};
  }

  void _updateState(String gameId, GameState Function(GameState) updater) {
    final current = state[gameId];
    if (current != null) {
      state = {...state, gameId: updater(current)};
    }
  }

  Set<GameAction> _getActions(GameStatus status, Game game) => switch (status) {
        GameStatus.ready => {GameAction.download},
        GameStatus.downloaded => _canExtract(game) ? {GameAction.extract} : const {},
        GameStatus.extracted => const {},
        GameStatus.downloadFailed => {GameAction.retryDownload},
        GameStatus.extractionFailed => {GameAction.retryExtraction},
        GameStatus.downloadPaused => {GameAction.resume, GameAction.cancel},
        GameStatus.downloading => {GameAction.pause, GameAction.cancel},
        _ => {GameAction.loading},
      };

  bool _canExtract(Game game) {
    try {
      final downloadDir = _ref.read(appStateProvider).downloadDir;
      final filePath = path.join(downloadDir, game.filename);
      return ExtractionService().isCompressedFile(filePath);
    } catch (_) {
      return false;
    }
  }
}
