import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';

class GameTitle extends StatelessWidget {
  final Game game;
  final GameState gameState;

  const GameTitle({
    super.key,
    required this.game,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: game.title,
            child: Text(
              game.metadata?.displayTitle ?? game.title,
              style: TextStyle(
                fontSize: 13,
                color: gameState.status == GameStatus.extracted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                fontWeight: gameState.status == GameStatus.extracted ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (game.metadata?.diskNumber.isNotEmpty == true) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'Disk ${game.metadata!.diskNumber}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (game.metadata?.revision.isNotEmpty == true) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'Rev ${game.metadata!.revision}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (game.metadata?.regions.isNotEmpty == true) ...[
          const SizedBox(width: 4),
          ...game.metadata!.regions.take(3).map((region) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withAlpha(60),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    region,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )),
          if (game.metadata!.regions.length > 3)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '+${game.metadata!.regions.length - 3}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
