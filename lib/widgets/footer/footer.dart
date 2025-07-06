import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/providers/settings_provider.dart';
import 'package:roms_downloader/utils/formatters.dart';

class Footer extends ConsumerWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final catalogState = ref.watch(catalogProvider);
    final gameStateManager = ref.watch(gameStateManagerProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final activeGames =
        catalogState.games.map((game) => gameStateManager[game.taskId]).whereType<GameState>().where((gameState) => gameState.isActive).toList();

    final downloadingGames = activeGames.where((state) => state.status == GameStatus.downloading || state.status == GameStatus.downloadQueued).length;
    final extractingGames = activeGames.where((state) => state.status == GameStatus.extracting).length;

    final overallProgress = _calculateOverallProgress(activeGames);
    final overallNetworkSpeed = _calculateOverallNetworkSpeed(activeGames);
    final overallTimeRemaining = _calculateOverallTimeRemaining(activeGames);
    final showProgressBar = activeGames.any((state) => state.showProgressBar);

    final selectedConsole = appState.selectedConsole;
    final downloadDir = settingsNotifier.getDownloadDir(selectedConsole?.id);
    final shouldTruncate = downloadDir.length > 100;
    final truncatedDonwloadDir = shouldTruncate ? '${downloadDir.substring(0, 50)}...${downloadDir.substring(downloadDir.length - 50)}' : downloadDir;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgressBar) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _buildStatusText(appState.loading, downloadingGames, extractingGames, catalogState.filteredGamesCount),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    truncatedDonwloadDir,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: overallProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 20,
              ),
            ),
            SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(overallProgress * 100).toStringAsFixed(1)}% • ${formatNetworkSpeed(overallNetworkSpeed)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Time Remaining: ${overallTimeRemaining > Duration.zero ? formatTimeRemaining(overallTimeRemaining) : 'N/A'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appState.loading
                        ? "Loading catalog..."
                        : _buildStatusText(appState.loading, downloadingGames, extractingGames, catalogState.filteredGamesCount),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    truncatedDonwloadDir,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _calculateOverallProgress(List<GameState> activeGames) {
    if (activeGames.isEmpty) return 0.0;

    // Calculate average progress across all active games
    double totalProgress = 0.0;
    for (final gameState in activeGames) {
      totalProgress += gameState.currentProgress;
    }

    return totalProgress / activeGames.length;
  }

  double _calculateOverallNetworkSpeed(List<GameState> activeGames) {
    final speedValues = activeGames.where((state) => state.networkSpeed > 0).map((state) => state.networkSpeed);

    if (speedValues.isEmpty) return 0.0;
    return speedValues.reduce((a, b) => a + b);
  }

  Duration _calculateOverallTimeRemaining(List<GameState> activeGames) {
    final timeRemainingValues = activeGames.where((state) => state.timeRemaining > Duration.zero).map((state) => state.timeRemaining);

    if (timeRemainingValues.isEmpty) return Duration.zero;

    final totalSeconds = timeRemainingValues.map((d) => d.inSeconds).reduce((a, b) => a + b);

    return Duration(seconds: (totalSeconds / timeRemainingValues.length).round());
  }

  String _buildStatusText(bool loading, int downloading, int extracting, int totalGames) {
    if (loading) return "Loading catalog...";

    final statuses = <String>[];
    if (downloading > 0) statuses.add("Downloading $downloading ${downloading == 1 ? 'game' : 'games'}");
    if (extracting > 0) statuses.add("Extracting $extracting ${extracting == 1 ? 'game' : 'games'}");

    return statuses.isNotEmpty ? statuses.join(" • ") : "$totalGames games available";
  }
}
