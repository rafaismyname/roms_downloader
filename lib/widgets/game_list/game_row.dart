import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late FocusScopeNode _node;
  late FocusNode _checkboxFocusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _node = FocusScopeNode();
    _node.addListener(_onFocusChange);
    _checkboxFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _node.dispose();
    _checkboxFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _node.hasFocus;
    if (_hasFocus != hasFocus) {
      setState(() {
        _hasFocus = hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogNotifier = ref.read(catalogProvider.notifier);

    final gameId = widget.game.gameId;
    final gameState = ref.watch(gameStateProvider(widget.game));
    final isSelected = ref.watch(gameSelectionProvider(gameId));

    return FocusScope(
      node: _node,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
            LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(TraversalDirection.up),
            LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(TraversalDirection.down),
          },
          child: Actions(
            actions: {
              DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                onInvoke: (intent) {
                  if (intent.direction == TraversalDirection.up) {
                    return FocusScope.of(context).previousFocus();
                  } else if (intent.direction == TraversalDirection.down) {
                    return FocusScope.of(context).nextFocus();
                  }
                  return null;
                },
              ),
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected || _hasFocus ? Theme.of(context).colorScheme.primaryContainer.withAlpha(isSelected ? 50 : 30) : null,
                border: Border(
                  bottom: BorderSide(
                    color: _hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                    width: _hasFocus ? 2.0 : 0.5,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.selectable) ...[
                    FocusTraversalOrder(
                      order: NumericFocusOrder(1),
                      child: SizedBox(
                        width: 20,
                        child: ListenableBuilder(
                          listenable: _checkboxFocusNode,
                          builder: (context, child) {
                            final hasFocus = _checkboxFocusNode.hasFocus;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: hasFocus ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : null,
                                border: hasFocus ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                              ),
                              child: child,
                            );
                          },
                          child: Checkbox(
                            value: isSelected,
                            onChanged: gameState.isInteractable ? (_) => catalogNotifier.toggleGameSelection(gameId) : null,
                            focusNode: _checkboxFocusNode,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                  ],
                  FocusTraversalOrder(
                    order: NumericFocusOrder(2),
                    child: GameBoxart(
                      game: widget.game,
                      size: (widget.isNarrow ? 50 : 60) + (widget.selectable ? 0 : 20),
                    ),
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
                              FocusTraversalOrder(
                                order: NumericFocusOrder(3),
                                child: SizedBox(
                                  width: widget.actionsColumnWidth,
                                  child: GameActionButtons(
                                    game: widget.game,
                                    gameState: gameState,
                                    isNarrow: widget.isNarrow,
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
