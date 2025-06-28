import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/app_state_model.dart';
import 'package:roms_downloader/models/catalog_model.dart';
import 'package:roms_downloader/models/download_model.dart';
import 'package:roms_downloader/models/extraction_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/services/extraction_service.dart';

final gameStateProvider = Provider.family<GameState, String>((ref, taskId) {
  final gameStates = ref.watch(gameStateManagerProvider);
  return gameStates[taskId] ?? const GameState();
});

final gameStateManagerProvider = StateNotifierProvider<GameStateManager, Map<String, GameState>>((ref) {
  return GameStateManager(ref);
});

class GameStateManager extends StateNotifier<Map<String, GameState>> {
  final Ref _ref;
  final ExtractionService _extractionService = ExtractionService();

  GameStateManager(this._ref) : super({}) {
    _initialize();
  }

  void _initialize() {
    _ref.listen<DownloadState>(downloadProvider, (previous, next) {
      _updateFromDownloadState(next);
    });

    _ref.listen<ExtractionState>(extractionProvider, (previous, next) {
      _updateFromExtractionState(next);
    });

    _ref.listen<AppState>(appStateProvider, (previous, next) {
      if (previous?.downloadDir != next.downloadDir) {
        _checkAllFileStates();
      }
    });

    _ref.listen<CatalogState>(catalogProvider, (previous, next) {
      if (previous?.games != next.games) {
        _initializeGameStates(next.games);
        _checkAllFileStates();
      }

      if (previous?.selectedGames != next.selectedGames) {
        _updateSelectionStates(next.selectedGames);
      }
    });
  }

  void _initializeGameStates(List<Game> games) {
    final newState = Map<String, GameState>.from(state);

    for (final game in games) {
      if (!newState.containsKey(game.taskId)) {
        final appState = _ref.read(appStateProvider);
        if (appState.downloadDir.isNotEmpty) {
          final fileState = _checkFileState(game, appState.downloadDir);
          final initialState = GameState(
            fileExists: fileState.fileExists,
            extractedContentExists: fileState.extractedContentExists,
            similarContentExists: fileState.similarContentExists,
          );

          GameStatus initialStatus;
          if (fileState.extractedContentExists || fileState.similarContentExists) {
            initialStatus = GameStatus.extracted;
          } else if (fileState.fileExists) {
            initialStatus = GameStatus.downloaded;
          } else {
            initialStatus = GameStatus.ready;
          }

          newState[game.taskId] = initialState.copyWith(
            status: initialStatus,
            isInteractable: initialStatus != GameStatus.extracted,
            availableActions: _computeAvailableActions(initialState.copyWith(status: initialStatus), game.taskId),
          );
        } else {
          newState[game.taskId] = const GameState();
        }
      }
    }

    state = newState;
  }

  void _updateSelectionStates(Set<String> selectedGames) {
    final newState = Map<String, GameState>.from(state);
    bool hasChanges = false;

    for (final entry in newState.entries) {
      final isSelected = selectedGames.contains(entry.key);
      if (entry.value.isSelected != isSelected) {
        newState[entry.key] = entry.value.copyWith(isSelected: isSelected);
        hasChanges = true;
      }
    }

    if (hasChanges) {
      state = newState;
    }
  }

  void _updateFromDownloadState(DownloadState downloadState) {
    final newState = Map<String, GameState>.from(state);
    final catalogState = _ref.read(catalogProvider);
    bool hasChanges = false;

    // First, ensure all games from catalog have entries in the state
    for (final game in catalogState.games) {
      if (!newState.containsKey(game.taskId)) {
        newState[game.taskId] = const GameState();
        hasChanges = true;
      }
    }

    // Then update based on download state changes
    for (final entry in newState.entries) {
      final taskId = entry.key;
      final currentState = entry.value;
      final taskStatus = downloadState.taskStatus[taskId];
      final taskProgress = downloadState.taskProgress[taskId];
      final isCompleted = downloadState.completedTasks.contains(taskId);

      final updatedState = _computeStateFromDownload(
        currentState,
        taskStatus,
        taskProgress,
        isCompleted,
        taskId, // Pass taskId for proper action computation
      );

      if (updatedState != currentState) {
        newState[taskId] = updatedState;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      state = newState;
    }
  }

  void _updateFromExtractionState(ExtractionState extractionState) {
    final newState = Map<String, GameState>.from(state);
    bool hasChanges = false;

    for (final entry in newState.entries) {
      final taskId = entry.key;
      final currentState = entry.value;
      final extractionTask = extractionState.getTaskState(taskId);

      final updatedState = _computeStateFromExtraction(currentState, extractionTask, taskId);

      if (updatedState != currentState) {
        newState[taskId] = updatedState;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      state = newState;
    }
  }

  GameState _computeStateFromDownload(
    GameState currentState,
    TaskStatus? taskStatus,
    TaskProgressUpdate? taskProgress,
    bool isCompleted,
    String taskId,
  ) {
    if (isCompleted) {
      // When download completes, re-check file states to update fileExists
      final game = _findGameByTaskId(taskId);
      GameState completedState;

      if (game != null) {
        final appState = _ref.read(appStateProvider);
        final fileState = _checkFileState(game, appState.downloadDir);

        completedState = currentState.copyWith(
          status: GameStatus.downloaded,
          downloadProgress: 1.0,
          isInteractable: true,
          showProgressBar: false,
          currentProgress: 1.0,
          fileExists: fileState.fileExists,
          extractedContentExists: fileState.extractedContentExists,
          similarContentExists: fileState.similarContentExists,
        );

        // Check if should show as extracted after computing file states
        final hasExtractedContent = completedState.extractedContentExists || completedState.similarContentExists;

        return completedState.copyWith(
          status: hasExtractedContent ? GameStatus.extracted : GameStatus.downloaded,
          isInteractable: !hasExtractedContent, // Extracted games should not be interactable
          availableActions: _computeAvailableActions(completedState, taskId),
        );
      } else {
        completedState = currentState.copyWith(
          status: GameStatus.downloaded,
          downloadProgress: 1.0,
          isInteractable: true,
          showProgressBar: false,
          currentProgress: 1.0,
        );

        return completedState.copyWith(
          availableActions: _computeAvailableActions(completedState, taskId),
        );
      }
    }

    switch (taskStatus) {
      case TaskStatus.enqueued:
        return currentState.copyWith(
          status: GameStatus.downloadQueued,
          downloadProgress: 0.0, // Ensure progress starts at 0
          networkSpeed: 0.0, // Reset network speed
          timeRemaining: Duration.zero, // Reset time remaining
          isInteractable: false,
          availableActions: {GameAction.cancel},
          showProgressBar: true,
          currentProgress: 0.0, // Ensure current progress starts at 0
        );

      case TaskStatus.running:
        final progress = taskProgress?.progress ?? 0.0;
        return currentState.copyWith(
          status: GameStatus.downloading,
          downloadProgress: progress,
          networkSpeed: taskProgress?.networkSpeed ?? 0.0,
          timeRemaining: taskProgress?.timeRemaining ?? Duration.zero,
          isInteractable: false,
          availableActions: {GameAction.pause, GameAction.cancel},
          showProgressBar: true,
          currentProgress: progress,
        );

      case TaskStatus.paused:
        return currentState.copyWith(
          status: GameStatus.downloadPaused,
          isInteractable: false,
          availableActions: {GameAction.resume, GameAction.cancel},
          showProgressBar: true,
          currentProgress: currentState.downloadProgress, // Keep current progress
        );

      case TaskStatus.failed:
        return currentState.copyWith(
          status: GameStatus.downloadFailed,
          isInteractable: true,
          availableActions: {GameAction.retryDownload},
          showProgressBar: false,
          errorMessage: 'Download failed',
        );

      default:
        // Don't reset status for games that are already extracted
        if (currentState.status == GameStatus.extracted) {
          return currentState.copyWith(
            downloadProgress: 0.0,
            networkSpeed: 0.0,
            timeRemaining: Duration.zero,
            showProgressBar: false,
            availableActions: _computeAvailableActions(currentState, taskId),
          );
        }

        // For other states, reset to ready
        return currentState.copyWith(
          status: GameStatus.ready,
          downloadProgress: 0.0,
          networkSpeed: 0.0,
          timeRemaining: Duration.zero,
          isInteractable: true,
          availableActions: _computeAvailableActions(currentState, taskId),
          showProgressBar: false,
          currentProgress: 0.0,
        );
    }
  }

  GameState _computeStateFromExtraction(
    GameState currentState,
    ExtractionTaskState? extractionTask,
    String taskId,
  ) {
    if (extractionTask == null) {
      return currentState.copyWith(
        extractionProgress: 0.0,
        availableActions: _computeAvailableActions(currentState, taskId),
      );
    }

    switch (extractionTask.status) {
      case ExtractionStatus.extracting:
        return currentState.copyWith(
          status: GameStatus.extracting,
          extractionProgress: extractionTask.progress,
          isInteractable: false,
          availableActions: const {},
          showProgressBar: true,
          currentProgress: extractionTask.progress,
        );

      case ExtractionStatus.completed:
        // When extraction completes, re-check file states and update library status
        final game = _findGameByTaskId(taskId);
        GameState completedState;

        if (game != null) {
          final appState = _ref.read(appStateProvider);
          final fileState = _checkFileState(game, appState.downloadDir);

          completedState = currentState.copyWith(
            status: GameStatus.extracted,
            extractionProgress: 1.0,
            showProgressBar: false,
            currentProgress: 1.0,
            fileExists: fileState.fileExists,
            extractedContentExists: fileState.extractedContentExists,
            similarContentExists: fileState.similarContentExists,
          );

          // After extraction, always show as extracted
          return completedState.copyWith(
            status: GameStatus.extracted,
            isInteractable: false, // Extracted games should not be interactable
            availableActions: const {},
          );
        } else {
          completedState = currentState.copyWith(
            status: GameStatus.extracted,
            extractionProgress: 1.0,
            showProgressBar: false,
            currentProgress: 1.0,
          );

          return completedState.copyWith(
            availableActions: const {},
          );
        }

      case ExtractionStatus.failed:
        return currentState.copyWith(
          status: GameStatus.extractionFailed,
          isInteractable: true,
          availableActions: {GameAction.retryExtraction},
          showProgressBar: false,
          errorMessage: extractionTask.error ?? 'Extraction failed',
        );

      default:
        return currentState;
    }
  }

  void _checkAllFileStates() {
    final appState = _ref.read(appStateProvider);
    final catalogState = _ref.read(catalogProvider);

    if (appState.downloadDir.isEmpty || catalogState.games.isEmpty) return;

    final newState = Map<String, GameState>.from(state);
    bool hasChanges = false;

    for (final game in catalogState.games) {
      final currentState = newState[game.taskId] ?? const GameState();
      final fileState = _checkFileState(game, appState.downloadDir);

      final stateWithFileInfo = currentState.copyWith(
        fileExists: fileState.fileExists,
        extractedContentExists: fileState.extractedContentExists,
        similarContentExists: fileState.similarContentExists,
      );

      final hasExtractedContent = stateWithFileInfo.extractedContentExists || stateWithFileInfo.similarContentExists;

      // Determine proper status based on file state and current status
      GameStatus newStatus;
      if (hasExtractedContent) {
        newStatus = GameStatus.extracted;
      } else if (stateWithFileInfo.fileExists) {
        // File exists - show as downloaded (with extract button for archives)
        newStatus = GameStatus.downloaded;
      } else {
        // No file exists - reset to ready
        newStatus = GameStatus.ready;
      }

      final updatedState = stateWithFileInfo.copyWith(
        status: newStatus,
        isInteractable: newStatus != GameStatus.extracted &&
            newStatus != GameStatus.downloading &&
            newStatus != GameStatus.extracting &&
            newStatus != GameStatus.downloadQueued &&
            newStatus != GameStatus.extractionQueued &&
            newStatus != GameStatus.processing, // More explicit active state check
        availableActions: _computeAvailableActions(stateWithFileInfo.copyWith(status: newStatus), game.taskId),
      );

      if (updatedState != currentState) {
        newState[game.taskId] = updatedState;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      state = newState;
    }
  }

  ({bool fileExists, bool extractedContentExists, bool similarContentExists}) _checkFileState(Game game, String downloadDir) {
    final expectedFilePath = path.join(downloadDir, game.filename);
    final expectedFile = File(expectedFilePath);

    // First check if exact filename exists
    bool fileExists = expectedFile.existsSync();

    // If exact file doesn't exist, try to find similar files
    // This handles cases where the downloaded filename differs from the URL filename
    if (!fileExists) {
      try {
        final dir = Directory(downloadDir);
        if (dir.existsSync()) {
          // Get the base name without extension from the expected filename
          final expectedBaseName = path.basenameWithoutExtension(game.filename);
          final expectedExtension = path.extension(game.filename);

          final files = dir.listSync().whereType<File>();
          for (final file in files) {
            final fileName = path.basename(file.path);
            final fileBaseName = path.basenameWithoutExtension(fileName);
            final fileExtension = path.extension(fileName);

            // Check if this could be the same file with a slightly different name
            if (fileExtension == expectedExtension) {
              // Remove common differences and normalize for comparison
              final normalizedExpected = _normalizeFilename(expectedBaseName);
              final normalizedActual = _normalizeFilename(fileBaseName);

              if (normalizedExpected == normalizedActual || normalizedActual.contains(normalizedExpected) || normalizedExpected.contains(normalizedActual)) {
                fileExists = true;
                debugPrint('Found matching file: ${file.path} for expected: $expectedFilePath');
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error searching for similar files: $e');
      }
    }

    final extractedContentExists = _extractionService.hasExtractedContent(expectedFilePath);
    final similarContent = _extractionService.findSimilarContent(expectedFilePath, downloadDir);
    final similarContentExists = similarContent.isNotEmpty;

    return (
      fileExists: fileExists,
      extractedContentExists: extractedContentExists,
      similarContentExists: similarContentExists,
    );
  }

  String _normalizeFilename(String filename) {
    return filename
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') // Remove all whitespace
        .replaceAll(RegExp(r'[^\w\d]'), '') // Remove special characters except word chars and digits
        .trim();
  }

  Set<GameAction> _computeAvailableActions(GameState gameState, [String? taskId]) {
    // If currently active, no actions available
    if (gameState.isActive && gameState.status != GameStatus.downloadPaused) {
      if (gameState.status == GameStatus.downloading) {
        return {GameAction.pause, GameAction.cancel};
      }
      return const {};
    }

    // If paused, can resume or cancel
    if (gameState.status == GameStatus.downloadPaused) {
      return {GameAction.resume, GameAction.cancel};
    }

    // If failed, can retry
    if (gameState.status == GameStatus.downloadFailed) {
      return {GameAction.retryDownload};
    }
    if (gameState.status == GameStatus.extractionFailed) {
      return {GameAction.retryExtraction};
    }

    // If download completed and file can be extracted
    if (gameState.status == GameStatus.downloaded && taskId != null) {
      final game = _findGameByTaskId(taskId);
      if (game != null) {
        final appState = _ref.read(appStateProvider);

        // Use the enhanced file state check to find the actual file
        final fileState = _checkFileState(game, appState.downloadDir);

        if (fileState.fileExists) {
          // Try to find the actual file path for archive checking
          final actualFilePath = _findActualFilePath(game, appState.downloadDir);
          if (actualFilePath != null) {
            try {
              if (_extractionService.isSupportedArchive(actualFilePath)) {
                return {GameAction.extract};
              } else {
                // Non-extractable file - no actions available
                return const {};
              }
            } catch (e) {
              debugPrint('Error checking archive support for $actualFilePath: $e');
              // If we can't check, assume non-extractable
              return const {};
            }
          }
        }
      }
      // If we can't determine file type, assume non-extractable
      return const {};
    }

    // If extracted, no actions available
    if (gameState.status == GameStatus.extracted) {
      return const {};
    }

    // Default: can download
    return {GameAction.download};
  }

  Game? _findGameByTaskId([String? taskId]) {
    if (taskId == null) return null;

    final catalogState = _ref.read(catalogProvider);
    try {
      return catalogState.games.firstWhere((game) => game.taskId == taskId);
    } catch (e) {
      return null;
    }
  }

  String? _findActualFilePath(Game game, String downloadDir) {
    final expectedFilePath = path.join(downloadDir, game.filename);
    final expectedFile = File(expectedFilePath);

    // First check if exact filename exists
    if (expectedFile.existsSync()) {
      return expectedFilePath;
    }

    // If exact file doesn't exist, try to find similar files
    try {
      final dir = Directory(downloadDir);
      if (dir.existsSync()) {
        final expectedBaseName = path.basenameWithoutExtension(game.filename);
        final expectedExtension = path.extension(game.filename);

        final files = dir.listSync().whereType<File>();
        for (final file in files) {
          final fileName = path.basename(file.path);
          final fileBaseName = path.basenameWithoutExtension(fileName);
          final fileExtension = path.extension(fileName);

          // Check if this could be the same file with a slightly different name
          if (fileExtension == expectedExtension) {
            final normalizedExpected = _normalizeFilename(expectedBaseName);
            final normalizedActual = _normalizeFilename(fileBaseName);

            if (normalizedExpected == normalizedActual || normalizedActual.contains(normalizedExpected) || normalizedExpected.contains(normalizedActual)) {
              return file.path;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding actual file path: $e');
    }

    return null;
  }
}
