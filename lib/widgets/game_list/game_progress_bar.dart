import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/utils/formatters.dart';

class GameProgressBar extends StatelessWidget {
  final GameState gameState;

  const GameProgressBar({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    if (!gameState.showProgressBar) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 6, top: 6),
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
    );
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
