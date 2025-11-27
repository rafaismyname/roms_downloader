import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/common/loading_indicator.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class GameList extends ConsumerStatefulWidget {
  const GameList({super.key});

  @override
  ConsumerState<GameList> createState() => _GameListState();
}

class _GameListState extends ConsumerState<GameList> {
  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final selectedConsoleId = ref.watch(appStateProvider).selectedConsole?.id ?? 'all';

    final games = catalogState.paginatedFilteredGames;
    final loadingMore = catalogState.loadingMore;

    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = isPortrait || screenWidth < 600;

    final sizeColumnWidth = isNarrow ? 60.0 : 100.0;
    final statusColumnWidth = isNarrow ? 80.0 : 100.0;
    final actionsColumnWidth = isNarrow ? 100.0 : 120.0;

    const loadMoreThresholdPx = 500.0;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(-1),
            child: Focus(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        'Title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (!isNarrow)
                      SizedBox(
                        width: sizeColumnWidth,
                        child: Text(
                          'Size',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(
                      width: statusColumnWidth,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: actionsColumnWidth - 5,
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final isScroll = notification is ScrollUpdateNotification;
                final isNearBottom = notification.metrics.pixels >= notification.metrics.maxScrollExtent - loadMoreThresholdPx;
                final isVerticalScroll = notification.metrics.axis == Axis.vertical;
                final shouldLoadMore = isScroll && isVerticalScroll && isNearBottom && !catalogState.loadingMore && catalogState.hasMoreItems;
                if (shouldLoadMore) ref.read(catalogProvider.notifier).loadMoreItems();
                return false;
              },
              child: ListView.builder(
                key: PageStorageKey('game-list-$selectedConsoleId'),
                padding: EdgeInsets.zero,
                itemCount: games.length + (loadingMore ? 1 : 0),
                cacheExtent: screenHeight * 1.5,
                itemBuilder: (context, index) {
                  if (index >= games.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: LoadingIndicator(
                          size: 24,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  final game = games[index];
                  return FocusTraversalOrder(
                    order: NumericFocusOrder(index.toDouble()),
                    child: GameRow(
                      key: ValueKey(game.gameId),
                      game: game,
                      isNarrow: isNarrow,
                      sizeColumnWidth: sizeColumnWidth,
                      statusColumnWidth: statusColumnWidth,
                      actionsColumnWidth: actionsColumnWidth,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
