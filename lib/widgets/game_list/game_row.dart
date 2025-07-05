import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/game_metadata_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';

class GameRow extends ConsumerWidget {
  final Game game;
  final bool isNarrow;
  final double sizeColumnWidth;
  final double statusColumnWidth;
  final double actionsColumnWidth;

  const GameRow({
    super.key,
    required this.game,
    this.isNarrow = false,
    this.sizeColumnWidth = 100,
    this.statusColumnWidth = 100,
    this.actionsColumnWidth = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final downloadNotifier = ref.read(downloadProvider.notifier);
    final extractionNotifier = ref.read(extractionProvider.notifier);

    final gameId = game.taskId;
    final gameState = ref.watch(gameStateProvider(game));

    if (gameState.status == GameStatus.init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameStateManagerProvider.notifier).resolveState(gameId);
      });
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: gameState.isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
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
                width: 30,
                child: Checkbox(
                  value: gameState.isSelected,
                  onChanged: gameState.isInteractable ? (_) => catalogNotifier.toggleGameSelection(gameId) : null,
                ),
              ),                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.metadata?.displayTitle ?? game.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: gameState.status == GameStatus.extracted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                              fontWeight: gameState.status == GameStatus.extracted ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (game.metadata?.diskNumber.isNotEmpty == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Disk ${game.metadata!.diskNumber}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        if (game.metadata?.revision.isNotEmpty == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Rev ${game.metadata!.revision}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_getGameTags().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 3,
                        runSpacing: 2,
                        children: _getGameTags().map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    if (isNarrow)
                      Text(
                        formatBytes(game.size),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isNarrow)
                SizedBox(
                  width: sizeColumnWidth,
                  child: Text(
                    formatBytes(game.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: statusColumnWidth,
                child: Text(
                  gameState.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: getStatusColor(context, gameState.status),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: actionsColumnWidth,
                child: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  children: _buildActionButtons(context, gameState, downloadNotifier, extractionNotifier),
                ),
              ),
            ],
          ),
          if (gameState.showProgressBar)
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: gameState.currentProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 4,
                    ),
                  ),
                  if (gameState.currentProgress > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(gameState.currentProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            _getProgressText(gameState),
                            style: TextStyle(
                              fontSize: 9,
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

  List<Widget> _buildActionButtons(
    BuildContext context,
    GameState gameState,
    DownloadNotifier downloadNotifier,
    ExtractionNotifier extractionNotifier,
  ) {
    final List<Widget> buttons = [];

    final buttonSize = isNarrow ? 20.0 : 24.0;
    final buttonConstraints = BoxConstraints(minWidth: isNarrow ? 24 : 30, minHeight: isNarrow ? 24 : 30);

    for (final action in gameState.availableActions) {
      switch (action) {
        case GameAction.download:
          buttons.add(
            Tooltip(
              message: 'Download',
              child: IconButton(
                icon: Icon(Icons.download, size: buttonSize),
                onPressed: () => downloadNotifier.startSingleDownload(game),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.pause:
          buttons.add(
            Tooltip(
              message: 'Pause',
              child: IconButton(
                icon: Icon(Icons.pause, size: buttonSize),
                onPressed: () => downloadNotifier.pauseTask(game.taskId),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.resume:
          buttons.add(
            Tooltip(
              message: 'Resume',
              child: IconButton(
                icon: Icon(Icons.play_arrow, size: buttonSize),
                onPressed: () => downloadNotifier.resumeTask(game.taskId),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.cancel:
          buttons.add(
            Tooltip(
              message: 'Cancel',
              child: IconButton(
                icon: Icon(Icons.close, size: buttonSize),
                onPressed: () => downloadNotifier.cancelTask(game.taskId),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.extract:
          buttons.add(
            Tooltip(
              message: 'Extract',
              child: IconButton(
                icon: Icon(Icons.archive, size: buttonSize),
                onPressed: () => extractionNotifier.extractFile(game.taskId),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.retryDownload:
          buttons.add(
            Tooltip(
              message: 'Retry Download',
              child: IconButton(
                icon: Icon(Icons.refresh, size: buttonSize),
                onPressed: () => downloadNotifier.startSingleDownload(game),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.retryExtraction:
          buttons.add(
            Tooltip(
              message: 'Retry Extraction',
              child: IconButton(
                icon: Icon(Icons.refresh, size: buttonSize),
                onPressed: () => extractionNotifier.extractFile(game.taskId),
                constraints: buttonConstraints,
                padding: EdgeInsets.zero,
              ),
            ),
          );
          break;
        case GameAction.loading:
          buttons.add(
            SizedBox(
              width: buttonConstraints.minWidth,
              height: buttonConstraints.minHeight,
              child: Center(
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
          break;
        case GameAction.none:
          break;
      }
    }

    return buttons;
  }

  String _getProgressText(GameState gameState) {
    switch (gameState.status) {
      case GameStatus.downloading:
        final speed = formatNetworkSpeed(gameState.networkSpeed);
        final timeLeft = formatTimeRemaining(gameState.timeRemaining);
        if (timeLeft.isNotEmpty) {
          return '$speed - $timeLeft left';
        }
        return speed;
      case GameStatus.extracting:
        return 'Extracting...';
      case GameStatus.downloadQueued:
        return 'Queued for download';
      case GameStatus.extractionQueued:
        return 'Queued for extraction';
      case GameStatus.downloadPaused:
        return 'Download paused';
      case GameStatus.processing:
        return 'Processing...';
      default:
        return '';
    }
  }

  List<String> _getGameTags() {
    final tags = <String>[];
    final metadata = game.metadata;
    if (metadata == null) return tags;

    if (metadata.dumpQualities.contains(DumpQuality.badDump)) tags.add('Bad');
    if (metadata.dumpQualities.contains(DumpQuality.overdump)) tags.add('Over');
    
    if (metadata.romTypes.contains(RomType.demo)) tags.add('Demo');
    if (metadata.romTypes.contains(RomType.sample)) tags.add('Sample');
    if (metadata.romTypes.contains(RomType.proto)) tags.add('Proto');
    if (metadata.romTypes.contains(RomType.beta)) tags.add('Beta');
    if (metadata.romTypes.contains(RomType.alpha)) tags.add('Alpha');
    
    if (metadata.modifications.contains(ModificationType.hack)) tags.add('Hack');
    if (metadata.modifications.contains(ModificationType.translation)) tags.add('Transl.');
    if (metadata.modifications.contains(ModificationType.fixed)) tags.add('Fixed');
    if (metadata.modifications.contains(ModificationType.trainer)) tags.add('Trainer');

    if (metadata.distributionTypes.contains(DistributionType.alternate)) tags.add('Alt');
    if (metadata.distributionTypes.contains(DistributionType.unlicensed)) tags.add('Unlic');
    if (metadata.distributionTypes.contains(DistributionType.aftermarket)) tags.add('After');
    if (metadata.distributionTypes.contains(DistributionType.pirate)) tags.add('Pirate');

    return tags;
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Bad':
      case 'Over':
        return Colors.red.shade600;
      case 'Demo':
      case 'Sample':
      case 'Proto':
      case 'Beta':
      case 'Alpha':
        return Colors.orange.shade600;
      case 'Hack':
      case 'Trans':
      case 'Fixed':
      case 'Trainer':
        return Colors.blue.shade600;
      case 'Alt':
      case 'Unlic':
      case 'After':
      case 'Pirate':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
