import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class TaskListView extends StatelessWidget {
  final List<GameState> games;
  final String emptyMessage;
  final IconData emptyIcon;

  const TaskListView({
    super.key,
    required this.games,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final gameState = games[index];
        return GameRow(
          key: ValueKey(gameState.game.gameId),
          game: gameState.game,
          isNarrow: true,
          statusColumnWidth: 80,
          actionsColumnWidth: 100,
          selectable: false,
        );
      },
    );
  }
}
