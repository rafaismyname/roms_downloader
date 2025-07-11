import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_details_model.dart';

class BoxartService {
  static final Map<String, Map<String, String>> _boxartCache = {};

  Future<List<Game>> mutateGamesWithBoxarts(List<Game> games, Console console) async {
    if (console.boxarts == null) return games;

    try {
      final boxarts = await _fetchBoxartUrls(console.boxarts!);
      if (boxarts.isEmpty) return games;

      return await compute(_process, [games, boxarts]);
    } catch (e) {
      debugPrint('mutateGamesWithBoxarts error: $e');
      return games;
    }
  }

  Future<Map<String, String>> _fetchBoxartUrls(String boxartBaseUrl) async {
    if (_boxartCache.containsKey(boxartBaseUrl)) {
      return _boxartCache[boxartBaseUrl]!;
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.userAgent = 'Mozilla/5.0 (compatible; Flutter app)';

    try {
      final request = await client.getUrl(Uri.parse(boxartBaseUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch boxarts: ${response.statusCode}');
        return {};
      }

      final html = await response.transform(utf8.decoder).join();
      final boxartMap = _parseBoxartHtml(html, boxartBaseUrl);
      _boxartCache[boxartBaseUrl] = boxartMap;
      return boxartMap;
    } catch (e) {
      debugPrint('Error fetching boxarts: $e');
      return {};
    } finally {
      client.close();
    }
  }

  Map<String, String> _parseBoxartHtml(String html, String baseUrl) {
    final regExp = RegExp(r'<a href="([^"]+\.(png|jpg|jpeg|gif|webp))"[^>]*>', caseSensitive: false);
    final matches = regExp.allMatches(html);
    final boxartMap = <String, String>{};

    for (final match in matches) {
      final filename = match.group(1)!;
      final decodedFilename = Uri.decodeComponent(filename);
      final nameWithoutExt = path.basenameWithoutExtension(decodedFilename);
      final normalizedName = _normalizeName(nameWithoutExt);
      final fullUrl = baseUrl.endsWith('/') ? '$baseUrl$filename' : '$baseUrl/$filename';
      boxartMap[normalizedName] = fullUrl;
    }

    return boxartMap;
  }
}

List<Game> _process(List<dynamic> data) {
  final games = data[0] as List<Game>;
  final boxarts = data[1] as Map<String, String>;

  // Build an index of tokens -> list of boxart keys to narrow down the search space
  final Map<String, List<String>> tokenIndex = _buildNameTokenIndex(boxarts.keys);

  return games.map((game) {
    final gameNameWithoutExt = path.basenameWithoutExtension(game.filename);
    final normalizedGameName = _normalizeName(gameNameWithoutExt);

    // 1. Fast exact match by full normalized name
    String? boxartUrl = boxarts[normalizedGameName];

    // 2. If no exact match, attempt a token-based fuzzy lookup using the index
    if (boxartUrl == null) {
      final gameTokens = normalizedGameName.split(' ').where((t) => t.length > 2).toList();
      final candidateNames = <String>{};

      for (final token in gameTokens) {
        final names = tokenIndex[token];
        if (names != null) candidateNames.addAll(names);
      }

      final Iterable<String> searchSpace = candidateNames.isNotEmpty ? candidateNames : boxarts.keys;
      final mainTitle = gameTokens.isNotEmpty ? gameTokens.first : '';

      String? bestMatchName;
      int highestScore = 0;
      for (final candidate in searchSpace) {
        final score = _calculateMatchScore(normalizedGameName, candidate, mainTitle);
        if (score > highestScore && score > 2) {
          highestScore = score;
          bestMatchName = candidate;
        }
      }
      if (bestMatchName != null) {
        boxartUrl = boxarts[bestMatchName];
      }
    }

    if (boxartUrl != null) {
      return game.copyWith(details: GameDetails(boxart: boxartUrl));
    }

    return game; // No changes
  }).toList();
}

// Build a reverse index of token -> list of boxart names that contain that token.
// This allows us to restrict fuzzy search to a much smaller candidate set.
Map<String, List<String>> _buildNameTokenIndex(Iterable<String> boxartNames) {
  final Map<String, List<String>> index = {};
  for (final name in boxartNames) {
    for (final token in name.split(' ')) {
      if (token.length <= 2) continue; // Skip very short tokens – they are noisy
      index.putIfAbsent(token, () => []).add(name);
    }
  }
  return index;
}

String _normalizeName(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

int _calculateMatchScore(String gameName, String boxartName, String mainTitle) {
  final gameTokens = gameName.split(' ');
  final boxartTokens = boxartName.split(' ');

  int score = 0;

  if (boxartName.contains(mainTitle)) {
    score += 3;
  }

  for (final gameToken in gameTokens) {
    if (gameToken.length > 2) {
      if (boxartTokens.any((token) => token.contains(gameToken))) {
        score += 2;
      } else if (boxartName.contains(gameToken)) {
        score += 1;
      }
    }
  }

  if (gameTokens.length == boxartTokens.length) {
    score += 1;
  }

  return score;
}
