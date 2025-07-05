import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/providers/download_provider.dart';
import 'package:roms_downloader/providers/extraction_provider.dart';

class GameActionButtons extends StatelessWidget {
  final Game game;
  final GameState gameState;
  final DownloadNotifier downloadNotifier;
  final ExtractionNotifier extractionNotifier;
  final bool isNarrow;

  const GameActionButtons({
    super.key,
    required this.game,
    required this.gameState,
    required this.downloadNotifier,
    required this.extractionNotifier,
    this.isNarrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildActionButtons(context)
              .map((button) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: Platform.isAndroid ? 0 : 8),
                    child: button,
                  ))
              .toList(),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    final buttonSize = isNarrow ? 20.0 : 24.0;
    final buttonConstraints = BoxConstraints(minWidth: 20, minHeight: 20);

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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
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
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
          break;
        case GameAction.loading:
          buttons.add(
            SizedBox(
              width: 36,
              height: 36,
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
}
