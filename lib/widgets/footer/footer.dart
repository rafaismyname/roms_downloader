import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/widgets/footer/task_panel_modal.dart';

class Footer extends ConsumerWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final catalogState = ref.watch(catalogProvider);
    final gameStateManager = ref.watch(gameStateManagerProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = isPortrait || screenWidth < 600;

    final activeGames = gameStateManager.values.where((gameState) => gameState.isActive).toList();

    final downloadingGames = activeGames.where((state) => state.status == GameStatus.downloading || state.status == GameStatus.downloadPaused).length;
    final extractingGames = activeGames.where((state) => state.status == GameStatus.extracting).length;

    final hasActiveTasks = downloadingGames > 0 || extractingGames > 0;

    final overallProgress = _calculateOverallProgress(activeGames);

    final selectedConsole = appState.selectedConsole;
    final downloadDir = settingsNotifier.getDownloadDir(selectedConsole?.id);
    final shouldTruncate = downloadDir.length > (50 + (isNarrow ? 0 : 20));
    final truncateSize = isNarrow ? 10 : 30;
    final truncatedDownloadDir =
        shouldTruncate ? '${downloadDir.substring(0, truncateSize)}...${downloadDir.substring(downloadDir.length - truncateSize)}' : downloadDir;

    return Stack(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: hasActiveTasks ? 50 : 40,
          child: GestureDetector(
            child: InkWell(
              onTap: () => TaskPanelModal.show(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: hasActiveTasks
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                      color: hasActiveTasks
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.outline,
                      width: hasActiveTasks ? 1.5 : 0.5,
                    ),
                  ),
                ),
                child: OverflowBox(
                maxHeight: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: hasActiveTasks
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _buildStatusText(downloadingGames, extractingGames),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "${catalogState.filteredGamesCount} games",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              appState.loading ? "Loading catalog..." : "${catalogState.filteredGamesCount} games",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    SizedBox(width: 8),
                    hasActiveTasks
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  width: 132,
                                  child: LinearProgressIndicator(
                                    value: overallProgress,
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    color: Theme.of(context).colorScheme.primary,
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  truncatedDownloadDir,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            truncatedDownloadDir,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        Center(
          child: GestureDetector(
            onTap: () => TaskPanelModal.show(context),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 24,
                color: hasActiveTasks ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateOverallProgress(List<GameState> activeGames) {
    if (activeGames.isEmpty) return 0.0;
    double totalProgress = 0.0;
    for (final gameState in activeGames) {
      totalProgress += gameState.currentProgress;
    }
    return totalProgress / activeGames.length;
  }

  String _buildStatusText(int downloading, int extracting) {
    final statuses = <String>[];
    if (downloading > 0) statuses.add("Downloading $downloading");
    if (extracting > 0) statuses.add("Extracting $extracting");
    return statuses.join(" • ");
  }
}
