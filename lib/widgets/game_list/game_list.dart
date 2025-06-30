import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class GameList extends ConsumerStatefulWidget {
  const GameList({super.key});

  @override
  ConsumerState<GameList> createState() => _GameListState();
}

class _GameListState extends ConsumerState<GameList> {
  final ScrollController _scrollController = ScrollController();
  CatalogNotifier? _catalogNotifier;

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _catalogNotifier ??= ref.read(catalogProvider.notifier);
      _catalogNotifier?.loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final games = catalogState.paginatedFilteredGames;

    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = isPortrait || screenWidth < 600;

    final sizeColumnWidth = isNarrow ? 60.0 : 100.0;
    final statusColumnWidth = isNarrow ? 80.0 : 100.0;
    final actionsColumnWidth = isNarrow ? 100.0 : 100.0;

    return Column(
      children: [
        Container(
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
              const SizedBox(width: 40),
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
                width: actionsColumnWidth,
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
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return GameRow(
                game: game,
                isNarrow: isNarrow,
                sizeColumnWidth: sizeColumnWidth,
                statusColumnWidth: statusColumnWidth,
                actionsColumnWidth: actionsColumnWidth,
              );
            },
          ),
        ),
      ],
    );
  }
}
