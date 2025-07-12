import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/widgets/footer/task_game_row.dart';
import 'package:roms_downloader/widgets/footer/task_empty_state.dart';

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
      return EmptyStateWidget(
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final gameState = games[index];
        return TaskGameRow(gameState: gameState);
      },
    );
  }
}
