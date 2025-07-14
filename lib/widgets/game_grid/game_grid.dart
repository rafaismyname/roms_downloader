import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/game_grid/game_grid_item.dart';

class GameGrid extends ConsumerStatefulWidget {
  const GameGrid({super.key});

  @override
  ConsumerState<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends ConsumerState<GameGrid> {
  final ScrollController _scrollController = ScrollController();
  CatalogNotifier? _catalogNotifier;
  double _aspectRatio = 0.75;
  String? _lastConsoleId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      _catalogNotifier ??= ref.read(catalogProvider.notifier);
      _catalogNotifier?.loadMoreItems();
    }
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth > 1400) return 8;
    if (screenWidth > 1200) return 7;
    if (screenWidth > 900) return 6;
    if (screenWidth > 600) return 5;
    if (screenWidth > 400) return 4;
    return 2;
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
    final games = catalogState.paginatedFilteredGames;
    final loadingMore = catalogState.loadingMore;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    if (games.isNotEmpty) {
      final currentConsoleId = games.first.consoleId;
      if (_lastConsoleId != currentConsoleId) {
        _aspectRatio = 0.75;
        _lastConsoleId = currentConsoleId;
      }
      _updateAspectRatio(games.first.boxart);
    }

    return Padding(
      padding: EdgeInsets.all(6),
      child: GridView.builder(
        controller: _scrollController,
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
            key: ValueKey(game.taskId),
            game: game,
            aspectRatio: _aspectRatio,
          );
        },
      ),
    );
  }
}
