import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';

class FilteringService {
  static FilterResult filterAndPaginate(FilterInput input) {
    final games = input.games;
    final filterText = input.filterText.toLowerCase();
    final filter = input.filter;
    final skip = input.skip;
    final limit = input.limit;
    final favoriteGameIds = input.favoriteGameIds;

    var allMatched = <Game>[];

    for (final game in games) {
      if (_matchesFilter(game, filterText, filter, favoriteGameIds)) {
        allMatched.add(game);
      }
    }

    allMatched.sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));

    if (filter.showLatestRevisionOnly) {
      allMatched = _filterLatestRevisions(allMatched);
    }

    final paginatedGames = allMatched.skip(skip).take(limit).toList();

    return FilterResult(
      games: paginatedGames,
      totalCount: allMatched.length,
      hasMore: skip + limit < allMatched.length,
    );
  }

  static bool _matchesFilter(Game game, String filterText, CatalogFilter filter, Set<String>? favoriteGameIds) {
    if (filter.showFavoritesOnly && favoriteGameIds != null) {
      if (!favoriteGameIds.contains(game.taskId)) return false;
    }

    if (filterText.isNotEmpty) {
      final titleMatch = game.displayTitle.toLowerCase().contains(filterText);
      final originalMatch = game.title.toLowerCase().contains(filterText);
      if (!titleMatch && !originalMatch) return false;
    }

    final metadata = game.metadata;
    if (metadata == null) return true;

    if (filter.regions.isNotEmpty && !filter.regions.any((region) => metadata.regions.contains(region) || metadata.regions.isEmpty)) {
      return false;
    }

    if (filter.languages.isNotEmpty && !filter.languages.any((language) => metadata.languages.contains(language) || metadata.languages.isEmpty)) {
      return false;
    }

    if (filter.categories.isNotEmpty && !filter.categories.any((category) => metadata.categories.contains(category))) {
      return false;
    }

    if (filter.dumpQualities.isNotEmpty) {
      if (metadata.dumpQualities.isEmpty) {
        if (!filter.dumpQualities.contains('goodDump')) return false;
      } else {
        final hasAllowedDumpQuality = metadata.dumpQualities.any((quality) => filter.dumpQualities.contains(quality.name));
        if (!hasAllowedDumpQuality) return false;
      }
    }

    if (filter.romTypes.isNotEmpty) {
      if (metadata.romTypes.isEmpty) {
        if (!filter.romTypes.contains('normal')) return false;
      } else {
        final hasAllowedRomType = metadata.romTypes.any((type) => filter.romTypes.contains(type.name));
        if (!hasAllowedRomType) return false;
      }
    }

    if (filter.modifications.isNotEmpty) {
      if (metadata.modifications.isEmpty) {
        if (!filter.modifications.contains('none')) return false;
      } else {
        final hasAllowedModification = metadata.modifications.any((mod) => filter.modifications.contains(mod.name));
        if (!hasAllowedModification) return false;
      }
    }

    if (filter.distributionTypes.isNotEmpty) {
      if (metadata.distributionTypes.isEmpty) {
        if (!filter.distributionTypes.contains('standard')) return false;
      } else {
        final hasAllowedDistribution = metadata.distributionTypes.any((dist) => filter.distributionTypes.contains(dist.name));
        if (!hasAllowedDistribution) return false;
      }
    }

    return true;
  }

  static List<Game> _filterLatestRevisions(List<Game> games) {
    if (games.isEmpty) return games;

    final result = <Game>[];
    final Map<String, Game> latestByTitle = {};

    for (final game in games) {
      final baseTitle = game.displayTitle;
      final currentRevision = game.metadata?.revision ?? '';

      final existing = latestByTitle[baseTitle];
      if (existing == null) {
        latestByTitle[baseTitle] = game;
      } else {
        final existingRevision = existing.metadata?.revision ?? '';
        if (_isNewerRevision(currentRevision, existingRevision)) {
          latestByTitle[baseTitle] = game;
        }
      }
    }

    for (final game in games) {
      if (latestByTitle[game.displayTitle] == game) {
        result.add(game);
      }
    }

    return result;
  }

  static bool _isNewerRevision(String current, String existing) {
    if (current.isEmpty && existing.isEmpty) return false;
    if (existing.isEmpty) return true;
    if (current.isEmpty) return false;

    return current.compareTo(existing) > 0;
  }
}

class FilterInput {
  final List<Game> games;
  final String filterText;
  final CatalogFilter filter;
  final int skip;
  final int limit;
  final Set<String>? favoriteGameIds;

  const FilterInput({
    required this.games,
    required this.filterText,
    required this.filter,
    this.skip = 0,
    required this.limit,
    this.favoriteGameIds,
  });
}

class FilterResult {
  final List<Game> games;
  final int totalCount;
  final bool hasMore;

  const FilterResult({
    required this.games,
    required this.totalCount,
    required this.hasMore,
  });
}
