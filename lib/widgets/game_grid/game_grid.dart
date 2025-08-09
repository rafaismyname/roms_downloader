import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roms_downloader/providers/app_state_provider.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/game_grid/game_grid_item.dart';

class GameGrid extends ConsumerStatefulWidget {
  const GameGrid({super.key});

  @override
  ConsumerState<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends ConsumerState<GameGrid> {
  double _aspectRatio = 0.75;
  String? _lastConsoleId;

  int _calculateCrossAxisCount(double screenWidth, double screenHeight, double aspectRatio) {
    final isLandscape = screenWidth > screenHeight;
    const double baseIdealWidth = 140;
    final double idealWidth = baseIdealWidth * (isLandscape ? 0.9 : 1.0) * (aspectRatio / 0.75);

    int columns = (screenWidth / idealWidth).floor().clamp(2, 8);

    int rows = (screenHeight / ((screenWidth / columns) / aspectRatio)).floor();
    while (rows < 2 && columns > 2) {
      columns--;
      rows = (screenHeight / ((screenWidth / columns) / aspectRatio)).floor();
    }

    if (isLandscape && aspectRatio < 1.75 && columns < 3) {
      columns = 4;
    }

    return columns;
  }

  void _updateAspectRatio(String? firstBoxartUrl) {
    if (firstBoxartUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          CachedNetworkImageProvider(firstBoxartUrl).resolve(const ImageConfiguration()).addListener(
                ImageStreamListener(
                  (ImageInfo info, bool _) {
                    final aspectRatio = info.image.width / info.image.height;
                    if (mounted && aspectRatio != _aspectRatio) {
                      setState(() {
                        _aspectRatio = aspectRatio.clamp(0.5, 1.5);
                      });
                    }
                  },
                  onError: (exception, stackTrace) {
                    debugPrint('Error loading boxart for aspect ratio calculation: $exception');
                  },
                ),
              );
        } catch (e) {
          debugPrint('Error fetching image to calculate ratio: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final selectedConsoleId = ref.watch(appStateProvider).selectedConsole?.id ?? 'all';

    final games = catalogState.paginatedFilteredGames;
    final loadingMore = catalogState.loadingMore;

    if (games.isNotEmpty) {
      final currentConsoleId = games.first.consoleId;
      if (_lastConsoleId != currentConsoleId) {
        _aspectRatio = 0.75;
        _lastConsoleId = currentConsoleId;
      }
      _updateAspectRatio(games.first.boxart);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth, screenHeight, _aspectRatio);

    const loadMoreThresholdPx = 500.0;

    return Padding(
      padding: EdgeInsets.only(left: 6, right: 6, top: 6, bottom: 3),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final isScroll = notification is ScrollUpdateNotification;
          final isNearBottom = notification.metrics.pixels >= notification.metrics.maxScrollExtent - loadMoreThresholdPx;
          final isVerticalScroll = notification.metrics.axis == Axis.vertical;
          final shouldLoadMore = isScroll && isVerticalScroll && isNearBottom && !catalogState.loadingMore && catalogState.hasMoreItems;
          if (shouldLoadMore) ref.read(catalogProvider.notifier).loadMoreItems();
          return false;
        },
        child: GridView.builder(
          key: PageStorageKey('game-grid-$selectedConsoleId'),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: _aspectRatio,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: games.length + (loadingMore ? crossAxisCount : 0),
          itemBuilder: (context, index) {
            if (index >= games.length) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final game = games[index];
            return GameGridItem(
              key: ValueKey(game.gameId),
              game: game,
              aspectRatio: _aspectRatio,
            );
          },
        ),
      ),
    );
  }
}
