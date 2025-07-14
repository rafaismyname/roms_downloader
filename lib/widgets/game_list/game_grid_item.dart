import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/providers/game_state_provider.dart';
import 'package:roms_downloader/widgets/game_list/game_action_buttons.dart';
import 'package:roms_downloader/widgets/game_list/game_boxart.dart';

class GameGridItem extends ConsumerStatefulWidget {
  final Game game;
  final double aspectRatio;

  const GameGridItem({
    super.key,
    required this.game,
    this.aspectRatio = 0.75,
  });

  @override
  ConsumerState<GameGridItem> createState() => _GameGridItemState();
}

class _GameGridItemState extends ConsumerState<GameGridItem> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final aspectRatio = widget.aspectRatio;
    final catalogState = ref.watch(catalogProvider);
    final catalogNotifier = ref.read(catalogProvider.notifier);
    final gameState = ref.watch(gameStateProvider(game));
    final isSelected = catalogState.selectedGames.contains(game.taskId);
    final isActive = gameState.isActive;

    if (gameState.status == GameStatus.init) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(gameStateManagerProvider.notifier).resolveState(game.taskId);
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isSelected || isActive) ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: (isSelected || isActive) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: GameBoxart(
                game: game,
                placeholder: _buildPlaceholder(context),
              ),
            ),
            if (gameState.isInteractable || isSelected) ...[
              Positioned(
                top: 8,
                left: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: gameState.isInteractable ? (_) => catalogNotifier.toggleGameSelection(game.taskId) : null,
                    shape: CircleBorder(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.displayTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gameState.showProgressBar) ...[
                      SizedBox(height: 4),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1.5),
                          child: LinearProgressIndicator(
                            value: gameState.currentProgress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (gameState.availableActions.isNotEmpty) ...[
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: GameActionButtons(
                    game: game,
                    gameState: gameState,
                    isNarrow: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videogame_asset_rounded,
                size: 32,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              SizedBox(height: 8),
              Text(
                widget.game.displayTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
