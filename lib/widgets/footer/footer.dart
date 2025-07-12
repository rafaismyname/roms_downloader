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

    final activeGames = gameStateManager.values.where((gameState) => gameState.isActive).toList();

    final downloadingGames = activeGames.where((state) => 
      state.status == GameStatus.downloading ||
      state.status == GameStatus.downloadPaused ||
      state.status == GameStatus.downloadQueued
    ).length;
    debugPrint("Downloading games: $downloadingGames");
    final extractingGames = activeGames.where((state) => 
      state.status == GameStatus.extracting || 
      state.status == GameStatus.extractionQueued
    ).length;
    debugPrint("Extracting games: $extractingGames");

    final hasActiveTasks = downloadingGames > 0 || extractingGames > 0;

    final overallProgress = _calculateOverallProgress(activeGames);

    final selectedConsole = appState.selectedConsole;
    final downloadDir = settingsNotifier.getDownloadDir(selectedConsole?.id);
    final shouldTruncate = downloadDir.length > 60;
    final truncatedDownloadDir = shouldTruncate ? '${downloadDir.substring(0, 30)}...${downloadDir.substring(downloadDir.length - 30)}' : downloadDir;

    return Stack(
      children: [
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 40,
          child: GestureDetector(
            onTap: () => TaskPanelModal.show(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: hasActiveTasks 
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasActiveTasks 
                        ? _buildStatusText(downloadingGames, extractingGames)
                        : appState.loading
                            ? "Loading catalog..."
                            : "${catalogState.filteredGamesCount} games available",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasActiveTasks ? FontWeight.w500 : FontWeight.normal,
                        color: hasActiveTasks 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActiveTasks) ...[
                    SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 3,
                      ),
                    ),
                  ] else ...[
                    SizedBox(width: 8),
                    Text(
                      truncatedDownloadDir,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
                color: hasActiveTasks 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
