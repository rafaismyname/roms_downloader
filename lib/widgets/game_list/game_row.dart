import 'package:flutter/material.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/download_service.dart';
import 'package:roms_downloader/services/game_state_service.dart';
import 'package:roms_downloader/utils/formatters.dart';

class GameRow extends StatelessWidget {
  final Game game;
  final int gameIndex;
  final bool isSelected;
  final bool isDownloaded;
  final bool downloading;
  final GameDownloadState? gameStats;
  final Function(int) onToggleSelection;
  final bool isLandscape;
  final GameStateService gameStateService;
  final DownloadService downloadService;

  const GameRow({
    super.key,
    required this.game,
    required this.gameIndex,
    required this.isSelected,
    required this.isDownloaded,
    required this.downloading,
    required this.gameStats,
    required this.onToggleSelection,
    required this.isLandscape,
    required this.gameStateService,
    required this.downloadService,
  });

  @override
  Widget build(BuildContext context) {
    final status = gameStateService.getStatus(gameIndex, game);
    final displayStatus = gameStateService.getDisplayStatus(gameIndex, game);
    final showProgressBar = gameStateService.shouldShowProgressBar(gameIndex, gameStats);

    return FutureBuilder<bool>(
        future: downloadService.isGameCancelling(gameIndex),
        initialData: false,
        builder: (context, snapshot) {
          final isCancelling = snapshot.data ?? false;
          final isInteractable = !downloading && gameStateService.isInteractable(gameIndex, game, isCancelling);

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isLandscape ? 6 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
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
                        value: isSelected,
                        onChanged: isInteractable ? (_) => onToggleSelection(gameIndex) : null,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        game.title,
                        style: TextStyle(
                          fontSize: isLandscape ? 13 : 15,
                          color: isDownloaded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isDownloaded ? FontWeight.bold : FontWeight.normal,
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
                          fontSize: isLandscape ? 12 : 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: isLandscape ? 12 : 14,
                              color: getStatusColor(context, status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (status == GameDownloadStatus.downloading || status == GameDownloadStatus.queued)
                            IconButton(
                              icon: const Icon(Icons.cancel, size: 16),
                              onPressed: () => downloadService.cancelGameDownload(gameIndex),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showProgressBar)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, right: 16, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: gameStateService.getProgress(gameIndex),
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            color: isCancelling ? Colors.grey : Theme.of(context).colorScheme.primary,
                            minHeight: isLandscape ? 4 : 5,
                          ),
                        ),
                        if (!isCancelling && gameStats != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${formatBytes(gameStats!.downloadedBytes)} / ${formatBytes(gameStats!.totalBytes)}',
                                  style: TextStyle(
                                    fontSize: isLandscape ? 9 : 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                if (gameStats?.speed != null && gameStats!.speed! > 0)
                                  Text(
                                    ' @ ${formatSpeed(gameStats!.speed!)}',
                                    style: TextStyle(
                                      fontSize: isLandscape ? 9 : 10,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
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
        });
  }
}
