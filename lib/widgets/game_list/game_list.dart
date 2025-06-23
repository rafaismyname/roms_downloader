import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class GameList extends StatelessWidget {
  final List<Game> games;
  final List<Game> allGames;
  final List<int> selectedGames;
  final List<bool> gameFileStatus;
  final bool downloading;
  final Function(int) onToggleSelection;

  const GameList({
    super.key,
    required this.games,
    required this.allGames,
    required this.selectedGames,
    required this.gameFileStatus,
    required this.downloading,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLandscape ? 6 : 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: isLandscape ? 0.5 : 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'Title',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isLandscape ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Size',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isLandscape ? 12 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isLandscape ? 12 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final gameIndex = allGames.indexWhere((g) => g.title == game.title);
              final isSelected = selectedGames.contains(gameIndex);
              final isDownloaded = gameIndex < gameFileStatus.length && gameFileStatus[gameIndex];

              return GameRow(
                game: game,
                gameIndex: gameIndex,
                isSelected: isSelected,
                isDownloaded: isDownloaded,
                downloading: downloading,
                onToggleSelection: onToggleSelection,
                isLandscape: isLandscape,
              );
            },
          ),
        ),
      ],
    );
  }
}
