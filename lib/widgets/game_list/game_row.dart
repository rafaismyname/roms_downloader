import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/utils/formatters.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/widgets/game_list/game_title.dart';
import 'package:roms_downloader/widgets/game_list/game_tags.dart';
import 'package:roms_downloader/widgets/game_list/game_action_buttons.dart';
import 'package:roms_downloader/widgets/game_list/game_progress_bar.dart';

class GameRow extends ConsumerStatefulWidget {
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
  ConsumerState<GameRow> createState() => _GameRowState();
}

class _GameRowState extends ConsumerState<GameRow> {
  @override
  Widget build(BuildContext context) {
    final catalogNotifier = ref.read(catalogProvider.notifier);

    final gameId = widget.game.taskId;
    final gameState = ref.watch(gameStateProvider(widget.game));

    if (gameState.status == GameStatus.init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(gameStateManagerProvider.notifier).resolveState(gameId);
        }
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
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GameTitle(
                      game: widget.game,
                      gameState: gameState,
                    ),
                    GameTags(game: widget.game),
                    if (widget.isNarrow)
                      Text(
                        formatBytes(widget.game.size),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
          GameProgressBar(gameState: gameState),
        ],
      ),
    );
  }
}
