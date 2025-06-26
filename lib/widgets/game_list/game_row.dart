import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/services/game_state_service.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';

class GameRow extends ConsumerWidget {
  final Game game;
  final bool isLandscape;

  const GameRow({
    super.key,
    required this.game,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final gameStateService = GameStateService();

    final taskId = game.taskId;
    final taskStatus = ref.watch(downloadTaskStatusProvider(taskId));
    final taskProgress = ref.watch(downloadTaskProgressProvider(taskId));
    final isCompleted = ref.watch(downloadTaskCompletionProvider(taskId));
    final isTaskSelected = ref.watch(gameSelectionProvider(taskId));

    final progress = taskProgress?.progress ?? 0.0;
    final networkSpeed = taskProgress?.networkSpeed ?? 0.0;
    final timeRemaining = taskProgress?.timeRemaining ?? Duration.zero;
    final status = gameStateService.getStatusFromTaskStatus(taskStatus, isCompleted);
    final displayStatus = gameStateService.getDisplayStatusFromTaskStatus(taskStatus, isCompleted);
    final showProgressBar = gameStateService.shouldShowProgressBarFromTaskStatus(taskStatus, isCompleted);
    final isInteractable = gameStateService.isInteractableFromTaskStatus(taskStatus, isCompleted);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isLandscape ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: isTaskSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
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
                  value: isTaskSelected,
                  onChanged: isInteractable ? (_) => catalogNotifier.toggleGameSelection(taskId) : null,
                ),
              ),
              Expanded(
                child: Text(
                  game.title,
                  style: TextStyle(
                    fontSize: isLandscape ? 13 : 15,
                    color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
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
                              onPressed: () => downloadNotifier.pauseTask(taskId),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Pause',
                            ),
                          IconButton(
                            icon: const Icon(Icons.cancel, size: 20),
                            onPressed: () => downloadNotifier.cancelTask(taskId),
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
                        onPressed: () => downloadNotifier.resumeTask(taskId),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isLandscape ? 9 : 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${formatNetworkSpeed(networkSpeed)} • ${formatTimeRemaining(timeRemaining)}',
                            style: TextStyle(
                              fontSize: isLandscape ? 9 : 10,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
  }
}
