import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/game_state_service.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';

class GameRow extends ConsumerWidget {
  final Game game;
  final int gameIndex;
  final bool isSelected;
  final bool isDownloaded;
  final bool downloading;
  final Function(int) onToggleSelection;
  final bool isLandscape;

  const GameRow({
    super.key,
    required this.game,
    required this.gameIndex,
    required this.isSelected,
    required this.isDownloaded,
    required this.downloading,
    required this.onToggleSelection,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appStateNotifier = ref.watch(appStateProvider.notifier);
    final gameStateService = GameStateService();

    final taskId = game.taskId(appState.selectedConsole?.id ?? '');
    final taskStatus = appState.taskStatus[taskId];
    final taskProgress = appState.taskProgress[taskId];
    final isCompleted = appState.completedTasks.contains(taskId);

    final status = gameStateService.getStatusFromTaskStatus(taskStatus, isCompleted);
    final progress = gameStateService.getProgressFromTaskProgress(taskProgress);
    final displayStatus = gameStateService.getDisplayStatusFromTaskStatus(taskStatus, isCompleted);
    final showProgressBar = gameStateService.shouldShowProgressBarFromTaskStatus(taskStatus, taskProgress);
    final isInteractable = !downloading && gameStateService.isInteractableFromTaskStatus(taskStatus, isCompleted, false);

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
                    Expanded(
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : 14,
                          color: getStatusColor(context, status),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (taskStatus == TaskStatus.running || taskStatus == TaskStatus.enqueued)
                      Row(
                        children: [
                          if (taskStatus == TaskStatus.running)
                            IconButton(
                              icon: const Icon(Icons.pause, size: 20),
                              onPressed: () => appStateNotifier.pauseTask(taskId),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Pause',
                            ),
                          IconButton(
                            icon: const Icon(Icons.cancel, size: 20),
                            onPressed: () => appStateNotifier.cancelTask(taskId),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Cancel',
                          ),
                        ],
                      ),
                    if (taskStatus == TaskStatus.paused)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 20),
                        onPressed: () => appStateNotifier.resumeTask(taskId),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Resume',
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
                      value: progress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: isLandscape ? 4 : 5,
                    ),
                  ),
                  if (progress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isLandscape ? 9 : 10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
