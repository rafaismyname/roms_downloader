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

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
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
              SizedBox(
                width: 100,
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
                width: 100,
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
                width: 100,
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
              return GameRow(game: game);
            },
          ),
        ),
      ],
    );
  }
}
