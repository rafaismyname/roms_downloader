import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/services/game_state_service.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class GameList extends ConsumerWidget {
  final List<Game> games;
  final List<Game> allGames;
  final List<int> selectedGames;
  final List<bool> gameFileStatus;
  final bool downloading;
  final Map<int, GameDownloadState> gameStats;
  final Function(int) onToggleSelection;

  const GameList({
    super.key,
    required this.games,
    required this.allGames,
    required this.selectedGames,
    required this.gameFileStatus,
    required this.downloading,
    required this.gameStats,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final gameStateService = ref.watch(gameStateServiceProvider);
    final downloadService = ref.watch(downloadServiceProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLandscape ? 6 : 12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
              final gameStatInfo = gameStats[gameIndex];

              return GameRow(
                game: game,
                gameIndex: gameIndex,
                isSelected: isSelected,
                isDownloaded: isDownloaded,
                downloading: downloading,
                gameStats: gameStatInfo,
                onToggleSelection: onToggleSelection,
                isLandscape: isLandscape,
                gameStateService: gameStateService,
                downloadService: downloadService,
              );
            },
          ),
        ),
      ],
    );
  }
}
