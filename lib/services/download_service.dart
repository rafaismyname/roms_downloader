import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/services/catalog_service.dart';
import 'package:roms_downloader/services/game_state_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final directoryService = ref.watch(directoryServiceProvider);
  final catalogService = ref.watch(catalogServiceProvider);
  final gameStateService = ref.watch(gameStateServiceProvider);
  return DownloadService(directoryService, catalogService, gameStateService);
});

class DownloadService {
  final DirectoryService directoryService;
  final CatalogService catalogService;
  final GameStateService gameStateService;
  final Dio _dio = Dio();

  List<int> _selectedGames = [];
  bool _isDownloading = false;
  final Map<int, CancelToken> _cancelTokens = {};
  final Map<int, bool> _gamesCancelling = {};
  final Map<int, bool> _gamesCancelled = {};

  DownloadStats _downloadStats = const DownloadStats();

  DownloadService(this.directoryService, this.catalogService, this.gameStateService);

  Future<void> selectGames(List<int> indices) async {
    _selectedGames = List.from(indices);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedGames', indices.map((i) => i.toString()).toList());
  }

  Future<void> startDownloads() async {
    if (_selectedGames.isEmpty || _isDownloading) {
      return;
    }

    _isDownloading = true;
    _gamesCancelling.clear();
    _gamesCancelled.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloading', true);

    final catalog = await catalogService.getCatalog();
    final downloadDir = await directoryService.getDownloadDir();
    final console = await _getSelectedConsole();

    if (console == null) {
      _isDownloading = false;
      return;
    }

    int totalSize = 0;
    for (final gameIdx in _selectedGames) {
      if (gameIdx < catalog.length) {
        final game = catalog[gameIdx];
        totalSize += game.size;
      }
    }

    _downloadStats = DownloadStats(
      totalSize: totalSize,
      totalDownloaded: 0,
      downloadSpeed: 0,
      activeDownloads: 0,
    );

    final maxConcurrent = 2;
    int activeDownloads = 0;

    for (final gameIdx in _selectedGames) {
      if (gameIdx >= catalog.length) continue;

      while (activeDownloads >= maxConcurrent && _isDownloading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_isDownloading) break;

      activeDownloads++;
      _downloadStats = _downloadStats.copyWith(activeDownloads: activeDownloads);

      _downloadGame(gameIdx, catalog[gameIdx], console, downloadDir).then((_) {
        activeDownloads--;
        _downloadStats = _downloadStats.copyWith(activeDownloads: activeDownloads);
      });
    }
  }

  Future<void> _downloadGame(int gameIdx, Game game, Console console, String downloadDir) async {
    final uri = Uri.parse(game.url);
    final filename = uri.pathSegments.last;

    final filePath = path.join(downloadDir, filename);
    if (File(filePath).existsSync()) {
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[gameIdx] = cancelToken;

    try {
      gameStateService.updateGameState(gameIdx, GameDownloadStatus.downloading, 0.0);

      final totalBytes = game.size;
      gameStateService.updateGameDownloadStats(gameIdx, 0, totalBytes);

      final dir = Directory(path.dirname(filePath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      DateTime lastSpeedUpdate = DateTime.now();
      int lastReceivedBytes = 0;

      await _dio.download(
        game.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (cancelToken.isCancelled) return;

          final now = DateTime.now();
          final timeSinceLastUpdate = now.difference(lastSpeedUpdate).inMilliseconds;

          int currentSpeed = 0;
          if (timeSinceLastUpdate >= 500) {
            final bytesDiff = received - lastReceivedBytes;
            final secondsDiff = timeSinceLastUpdate / 1000.0;
            if (secondsDiff > 0) {
              currentSpeed = (bytesDiff / secondsDiff).round();
            }

            lastSpeedUpdate = now;
            lastReceivedBytes = received;
          }

          final gameState = gameStateService.getGameDownloadState(gameIdx);
          gameStateService.updateGameDownloadStats(gameIdx, received, total, currentSpeed > 0 ? currentSpeed : gameState.speed);

          final progress = total > 0 ? received / total : 0.0;
          gameStateService.updateGameState(gameIdx, GameDownloadStatus.downloading, progress);

          _updateOverallStats();
        },
      );

      gameStateService.updateGameState(gameIdx, GameDownloadStatus.processing, 1.0);

      await Future.delayed(const Duration(milliseconds: 500));

      gameStateService.updateGameState(gameIdx, GameDownloadStatus.completed, 1.0);
    } catch (e) {
      if (cancelToken.isCancelled) {
        _gamesCancelled[gameIdx] = true;
        _gamesCancelling[gameIdx] = false;
        gameStateService.updateGameState(gameIdx, GameDownloadStatus.ready, 0.0);
      } else {
        gameStateService.updateGameState(gameIdx, GameDownloadStatus.error, 0.0);
        print('Error downloading game $gameIdx: $e');
      }
    } finally {
      _cancelTokens.remove(gameIdx);
      final gameState = gameStateService.getGameDownloadState(gameIdx);
      gameStateService.updateGameDownloadStats(gameIdx, gameState.downloadedBytes, gameState.totalBytes, 0);
    }
  }

  void _updateOverallStats() {
    int totalDownloaded = 0;
    int totalSize = 0;

    for (final gameIdx in _selectedGames) {
      if (_gamesCancelled[gameIdx] == true) continue;

      final gameState = gameStateService.getGameDownloadState(gameIdx);
      totalDownloaded += gameState.downloadedBytes;
      totalSize += gameState.totalBytes;
    }

    _downloadStats = _downloadStats.copyWith(
      totalDownloaded: totalDownloaded,
      totalSize: totalSize,
      downloadSpeed: _calculateAverageSpeed(),
    );
  }

  int _calculateAverageSpeed() {
    int totalSpeed = 0;

    for (final gameIdx in _selectedGames) {
      if (_gamesCancelled[gameIdx] == true) continue;

      final gameState = gameStateService.getGameDownloadState(gameIdx);
      if (gameState.speed != null && gameState.speed! > 0) {
        totalSpeed += gameState.speed!;
      }
    }

    return totalSpeed;
  }

  Future<Console?> _getSelectedConsole() async {
    final consoles = await catalogService.getConsoles();
    final prefs = await SharedPreferences.getInstance();
    final selectedConsoleId = prefs.getString('selectedConsoleId');

    if (selectedConsoleId == null || selectedConsoleId.isEmpty) {
      return consoles.isNotEmpty ? consoles.first : null;
    }

    return consoles.firstWhere(
      (c) => c.id == selectedConsoleId,
      orElse: () => consoles.first,
    );
  }

  Future<void> cancelGameDownload(int gameIdx) async {
    if (_cancelTokens.containsKey(gameIdx)) {
      _gamesCancelling[gameIdx] = true;
      _cancelTokens[gameIdx]?.cancel('User cancelled download');

      gameStateService.updateGameState(gameIdx, GameDownloadStatus.ready, 0.0);

      _gamesCancelled[gameIdx] = true;
      _gamesCancelling[gameIdx] = false;

      _updateOverallStats();
    }
  }

  Future<bool> isGameCancelling(int gameIdx) async {
    return _gamesCancelling[gameIdx] ?? false;
  }

  Future<bool> isGameCancelled(int gameIdx) async {
    return _gamesCancelled[gameIdx] ?? false;
  }

  Future<DownloadStats> getDownloadStats() async {
    return _downloadStats;
  }

  Future<GameDownloadState> getGameStats(int gameIdx) async {
    return gameStateService.getGameDownloadState(gameIdx);
  }

  Future<Map<int, GameDownloadState>> getAllGameStats() async {
    return gameStateService.getAllGameStates();
  }

  Future<bool> isDownloading() async {
    return _isDownloading;
  }

  Future<bool> checkDownloadCompletion() async {
    if (_selectedGames.isEmpty) {
      return true;
    }

    final catalog = await catalogService.getCatalog();

    bool allComplete = true;
    for (final gameIdx in _selectedGames) {
      if (gameIdx >= catalog.length) continue;

      if (_gamesCancelled[gameIdx] == true) {
        continue;
      }

      final status = gameStateService.getStatus(gameIdx, catalog[gameIdx]);
      if (status != GameDownloadStatus.completed && status != GameDownloadStatus.error && status != GameDownloadStatus.inLibrary) {
        allComplete = false;
        break;
      }
    }

    if (allComplete) {
      _isDownloading = false;

      _gamesCancelled.clear();
      _gamesCancelling.clear();

      gameStateService.cleanupCompletedDownloads();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('downloading', false);
    }

    return allComplete;
  }

  Future<void> resetDownloadState() async {
    _isDownloading = false;
    _gamesCancelled.clear();
    _gamesCancelling.clear();

    for (final token in _cancelTokens.values) {
      token.cancel('Download session ended');
    }
    _cancelTokens.clear();

    gameStateService.cleanupCompletedDownloads();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('downloading', false);
  }
}
