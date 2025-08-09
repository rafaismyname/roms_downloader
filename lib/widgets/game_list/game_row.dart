import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/widgets/game_list/game_title.dart';
import 'package:roms_downloader/widgets/game_list/game_tags.dart';
import 'package:roms_downloader/widgets/game_list/game_action_buttons.dart';
import 'package:roms_downloader/widgets/game_list/game_progress_bar.dart';
import 'package:roms_downloader/widgets/game_list/game_boxart.dart';

class GameRow extends ConsumerStatefulWidget {
  final Game game;
  final bool isNarrow;
  final double sizeColumnWidth;
  final double statusColumnWidth;
  final double actionsColumnWidth;
  final bool selectable;

  const GameRow({
    super.key,
    required this.game,
    this.isNarrow = false,
    this.sizeColumnWidth = 100,
    this.statusColumnWidth = 100,
    this.actionsColumnWidth = 100,
    this.selectable = true,
  });

  @override
  ConsumerState<GameRow> createState() => _GameRowState();
}

class _GameRowState extends ConsumerState<GameRow> {
  @override
  Widget build(BuildContext context) {
    final catalogNotifier = ref.read(catalogProvider.notifier);

    final gameId = widget.game.gameId;
    final gameState = ref.watch(gameStateProvider(widget.game));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: gameState.isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(50) : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.selectable) ...[
            SizedBox(
              width: 20,
              child: Checkbox(
                value: gameState.isSelected,
                onChanged: gameState.isInteractable ? (_) => catalogNotifier.toggleGameSelection(gameId) : null,
              ),
            ),
            SizedBox(width: 6),
          ],
          GameBoxart(
            game: widget.game,
            size: (widget.isNarrow ? 50 : 60) + (widget.selectable ? 0 : 20),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GameTitle(
                              game: widget.game,
                              gameState: gameState,
                            ),
                            Row(
                              children: [
                                if (widget.isNarrow)
                                  Text(
                                    formatBytes(widget.game.size),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (widget.isNarrow) SizedBox(width: 8),
                                Expanded(child: GameTags(game: widget.game)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isNarrow)
                        SizedBox(
                          width: widget.sizeColumnWidth,
                          child: Text(
                            formatBytes(widget.game.size),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: widget.statusColumnWidth,
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
                        width: widget.actionsColumnWidth,
                        child: GameActionButtons(
                          game: widget.game,
                          gameState: gameState,
                          isNarrow: widget.isNarrow,
                        ),
                      ),
                    ],
                  ),
                  if (gameState.showProgressBar)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GameProgressBar(gameState: gameState),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
