import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/widgets/game_list/game_boxart.dart';
import 'package:roms_downloader/widgets/game_list/game_action_buttons.dart';

class TaskGameRow extends ConsumerWidget {
  final GameState gameState;

  const TaskGameRow({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = gameState.game;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            GameBoxart(
              game: game,
              size: 40,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.metadata?.displayTitle ?? game.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    gameState.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: getStatusColor(context, gameState.status),
                    ),
                  ),
                  if (gameState.currentProgress > 0) ...[
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: gameState.currentProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(gameState.currentProgress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        if (gameState.status == GameStatus.downloading && gameState.networkSpeed > 0)
                          Text(
                            formatNetworkSpeed(gameState.networkSpeed),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            GameActionButtons(
              game: game,
              gameState: gameState,
              isNarrow: true,
            ),
          ],
        ),
      ),
    );
  }
}
