import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';

class GameRow extends ConsumerWidget {
  final Game game;

  const GameRow({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final extractionNotifier = ref.read(extractionProvider.notifier);

    final gameId = game.taskId;
    final gameState = ref.watch(gameStateProvider(game));

    if (gameState.status == GameStatus.init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameStateManagerProvider.notifier).resolveState(gameId);
      });
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: gameState.isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: gameState.isSelected,
                  onChanged: gameState.isInteractable ? (_) => catalogNotifier.toggleGameSelection(gameId) : null,
                ),
              ),
              Expanded(
                child: Text(
                  game.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: gameState.status == GameStatus.extracted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: gameState.status == GameStatus.extracted ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  formatBytes(game.size),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  gameState.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: getStatusColor(context, gameState.status),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildActionButtons(context, gameState, downloadNotifier, extractionNotifier),
                ),
              ),
            ],
          ),
          if (gameState.showProgressBar)
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: gameState.currentProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 4,
                    ),
                  ),
                  if (gameState.currentProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(gameState.currentProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            _getProgressText(gameState),
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    GameState gameState,
    DownloadNotifier downloadNotifier,
    ExtractionNotifier extractionNotifier,
  ) {
    final List<Widget> buttons = [];

    for (final action in gameState.availableActions) {
      switch (action) {
        case GameAction.download:
          buttons.add(
            Tooltip(
              message: 'Download',
              child: IconButton(
                icon: const Icon(Icons.download, size: 16),
                onPressed: () => downloadNotifier.startSingleDownload(game),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.pause:
          buttons.add(
            Tooltip(
              message: 'Pause',
              child: IconButton(
                icon: const Icon(Icons.pause, size: 16),
                onPressed: () => downloadNotifier.pauseTask(game.taskId),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.resume:
          buttons.add(
            Tooltip(
              message: 'Resume',
              child: IconButton(
                icon: const Icon(Icons.play_arrow, size: 16),
                onPressed: () => downloadNotifier.resumeTask(game.taskId),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.cancel:
          buttons.add(
            Tooltip(
              message: 'Cancel',
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => downloadNotifier.cancelTask(game.taskId),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.extract:
          buttons.add(
            Tooltip(
              message: 'Extract',
              child: IconButton(
                icon: const Icon(Icons.archive, size: 16),
                onPressed: () => extractionNotifier.extractFile(game.taskId),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.retryDownload:
          buttons.add(
            Tooltip(
              message: 'Retry Download',
              child: IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                onPressed: () => downloadNotifier.startSingleDownload(game),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.retryExtraction:
          buttons.add(
            Tooltip(
              message: 'Retry Extraction',
              child: IconButton(
                icon: const Icon(Icons.refresh, size: 16),
                onPressed: () => extractionNotifier.extractFile(game.taskId),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.loading:
          buttons.add(
            SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
          break;
        case GameAction.none:
          break;
      }
    }

    return buttons;
  }

  String _getProgressText(GameState gameState) {
    switch (gameState.status) {
      case GameStatus.downloading:
        final speed = formatNetworkSpeed(gameState.networkSpeed);
        final timeLeft = formatTimeRemaining(gameState.timeRemaining);
        if (timeLeft.isNotEmpty) {
          return '$speed - $timeLeft left';
        }
        return speed;
      case GameStatus.extracting:
        return 'Extracting...';
      case GameStatus.downloadQueued:
        return 'Queued for download';
      case GameStatus.extractionQueued:
        return 'Queued for extraction';
      case GameStatus.downloadPaused:
        return 'Download paused';
      case GameStatus.processing:
        return 'Processing...';
      default:
        return '';
    }
  }
}
