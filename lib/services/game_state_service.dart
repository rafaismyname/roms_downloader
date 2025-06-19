import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/directory_service.dart';

final gameStateServiceProvider = Provider<GameStateService>((ref) {
  final directoryService = ref.watch(directoryServiceProvider);
  return GameStateService(directoryService);
});

class GameStateService {
  final DirectoryService directoryService;
  final Map<int, GameDownloadState> _gameStates = {};
  final Map<int, bool> _libraryStatus = {};

  GameStateService(this.directoryService);

  GameDownloadStatus getStatus(int gameIndex, Game game) {
    if (_libraryStatus.containsKey(gameIndex) && _libraryStatus[gameIndex] == true) {
      return GameDownloadStatus.inLibrary;
    }

    if (_gameStates.containsKey(gameIndex)) {
      return _gameStates[gameIndex]!.status;
    }

    return GameDownloadStatus.ready;
  }

  double getProgress(int gameIndex) {
    if (_gameStates.containsKey(gameIndex)) {
      return _gameStates[gameIndex]!.progress;
    }
    return 0.0;
  }

  void updateGameState(int gameIndex, GameDownloadStatus status, [double progress = 0.0]) {
    final currentState = _gameStates[gameIndex] ?? const GameDownloadState();
    _gameStates[gameIndex] = currentState.copyWith(
      status: status,
      progress: progress,
    );

    if (status == GameDownloadStatus.completed) {
      _libraryStatus[gameIndex] = true;
    }
  }

  GameDownloadState getGameDownloadState(int gameIndex) {
    return _gameStates[gameIndex] ?? const GameDownloadState();
  }

  void updateGameDownloadStats(int gameIndex, int downloadedBytes, int totalBytes, [int? speed]) {
    final currentState = _gameStates[gameIndex] ?? const GameDownloadState();
    _gameStates[gameIndex] = currentState.copyWith(
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      speed: speed,
    );
  }

  Future<List<bool>> checkFilesExist(List<Game> catalog) async {
    final downloadDir = await directoryService.getDownloadDir();
    final results = <bool>[];

    for (int i = 0; i < catalog.length; i++) {
      final game = catalog[i];
      final uri = Uri.parse(game.url);
      final filename = uri.pathSegments.last;
      final filePath = path.join(downloadDir, filename);
      final exists = File(filePath).existsSync();

      _libraryStatus[i] = exists;
      results.add(exists);
    }

    return results;
  }

  Future<bool> isInLibrary(int gameIndex, Game game) async {
    if (_libraryStatus.containsKey(gameIndex)) {
      return _libraryStatus[gameIndex]!;
    }

    final downloadDir = await directoryService.getDownloadDir();
    final uri = Uri.parse(game.url);
    final filename = uri.pathSegments.last;
    final filePath = path.join(downloadDir, filename);
    final exists = File(filePath).existsSync();

    _libraryStatus[gameIndex] = exists;
    return exists;
  }

  void resetStates() {
    _gameStates.clear();
  }

  void cleanupCompletedDownloads() {
    _gameStates.forEach((gameIndex, state) {
      if (state.status == GameDownloadStatus.completed) {
        _libraryStatus[gameIndex] = true;
      }
    });

    _gameStates.removeWhere((key, value) =>
        value.status == GameDownloadStatus.downloading || value.status == GameDownloadStatus.queued || value.status == GameDownloadStatus.processing);
  }

  bool isGameActive(int gameIndex) {
    if (!_gameStates.containsKey(gameIndex)) return false;

    final status = _gameStates[gameIndex]!.status;
    return status == GameDownloadStatus.downloading || status == GameDownloadStatus.queued || status == GameDownloadStatus.processing;
  }

  String getDisplayStatus(int gameIndex, Game game) {
    final status = getStatus(gameIndex, game);

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
      case GameDownloadStatus.error:
        return "Error";
    }
  }

  bool isInteractable(int gameIndex, Game game, bool isCancelling) {
    final status = getStatus(gameIndex, game);
    return status != GameDownloadStatus.inLibrary && status != GameDownloadStatus.downloading && status != GameDownloadStatus.processing && !isCancelling;
  }

  bool shouldShowProgressBar(int gameIndex, GameDownloadState? gameStats) {
    if (gameStats != null && gameStats.downloadedBytes > 0) {
      return true;
    }

    if (!_gameStates.containsKey(gameIndex)) {
      return false;
    }

    final status = _gameStates[gameIndex]!.status;
    return status == GameDownloadStatus.downloading || status == GameDownloadStatus.processing;
  }

  Map<int, GameDownloadState> getAllGameStates() {
    return Map.from(_gameStates);
  }
}
