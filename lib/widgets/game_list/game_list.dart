import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/providers/catalog_provider.dart';
import 'package:roms_downloader/widgets/game_list/game_row.dart';

class GameList extends ConsumerWidget {
  const GameList({ super.key });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final games = catalogState.filteredGames;

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
