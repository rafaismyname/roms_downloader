import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';
import 'package:roms_downloader/models/catalog_filter_model.dart';

class FilteringService {
  static FilterResult filterAndPaginate(FilterInput input) {
    final games = input.games;
    final filter = input.filter;
    final skip = input.skip;
    final limit = input.limit;

    var allMatched = <Game>[];

    for (final game in games) {
      if (_matchesFilter(game, input)) {
        allMatched.add(game);
      }
    }

    allMatched.sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));

    // Filtering by latest revision is after regular filtering because it's also a grouping operation
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

  static bool _matchesFilter(Game game, FilterInput input) {
    final filterText = input.filterText.toLowerCase();
    final filter = input.filter;
    final favoriteGameIds = input.favoriteGameIds;
    final inLibraryStatus = input.inLibraryStatus;

    if (filter.showFavoritesOnly && favoriteGameIds != null) {
      if (!favoriteGameIds.contains(game.gameId)) return false;
    }

    if (filter.showInLibraryOnly && inLibraryStatus != null) {
      if (inLibraryStatus[game.gameId] != GameStatus.downloaded && inLibraryStatus[game.gameId] != GameStatus.extracted) {
        return false;
      }
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

    final Map<String, Game> latestByGameIdentity = {};

    for (final game in games) {
      final metadata = game.metadata;
      final baseTitle = metadata?.displayTitle ?? game.title;
      final regions = (metadata?.regions ?? []).join(',');
      final languages = (metadata?.languages ?? []).join(',');
      final diskNumber = metadata?.diskNumber ?? '';

      final gameIdentity = '$baseTitle|$regions|$languages|$diskNumber';
      final currentRevision = metadata?.revision ?? '';

      final existing = latestByGameIdentity[gameIdentity];
      if (existing == null || _isNewerRevision(currentRevision, existing.metadata?.revision ?? '')) {
        latestByGameIdentity[gameIdentity] = game;
      }
    }

    return games.where((game) {
      final metadata = game.metadata;
      final baseTitle = metadata?.displayTitle ?? game.title;
      final regions = (metadata?.regions ?? []).join(',');
      final languages = (metadata?.languages ?? []).join(',');
      final diskNumber = metadata?.diskNumber ?? '';
      final gameIdentity = '$baseTitle|$regions|$languages|$diskNumber';

      return latestByGameIdentity[gameIdentity] == game;
    }).toList();
  }

  // Possible bug: if revisions are non-numeric and not lexically comparable like 1.0, 1.0a, 1.0b or 1.2, 1.10,
  // this function may not work as intended.
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
  final Map<String, GameStatus>? inLibraryStatus;

  const FilterInput({
    required this.games,
    required this.filterText,
    required this.filter,
    this.skip = 0,
    required this.limit,
    this.favoriteGameIds,
    this.inLibraryStatus,
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
