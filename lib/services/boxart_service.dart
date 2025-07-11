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
      // Tokenisation: keep long words (>2 chars) and numeric tokens with at least two digits
      final numericRegExp = RegExp(r'^\d{2,}$');
      final mixedTokenRegExp = RegExp(r'^[a-z]+\d+$');
      final gameTokens = normalizedGameName.split(' ').where((token) {
        if (token.isEmpty) return false;
        return numericRegExp.hasMatch(token) || token.length > 2 || mixedTokenRegExp.hasMatch(token);
      }).toList();

      // Separate numeric tokens to use as a strong filter
      final numericTokens = gameTokens.where((t) => numericRegExp.hasMatch(t)).toList();

      Set<String> candidateNames = {};

      if (numericTokens.isNotEmpty) {
        // Start with intersection of all names containing every numeric token
        Set<String>? intersection;
        for (final nt in numericTokens) {
          final names = tokenIndex[nt];
          if (names == null) {
            intersection = <String>{};
            break;
          }
          final nameSet = names.toSet();
          intersection = intersection == null ? nameSet : intersection.intersection(nameSet);
          if (intersection.isEmpty) break;
        }
        candidateNames = intersection ?? <String>{};
      }

      // If numeric filtering produced no candidates *and there were no numeric tokens*,
      // fall back to a broader union of word-based matches. Otherwise we give up to
      // avoid mismatching (e.g. "16 Tales" should not match "Tales of Destiny").
      if (candidateNames.isEmpty && numericTokens.isEmpty) {
        for (final token in gameTokens.where((t) => !numericRegExp.hasMatch(t))) {
          final names = tokenIndex[token];
          if (names != null) candidateNames.addAll(names);
        }
      }

      // If we still have nothing, abandon matching for this game.
      if (candidateNames.isEmpty) {
        return game; // No boxart found respecting numeric constraint
      }

      // Tighten with mixed alpha-numeric tokens (e.g. "d3", "vol4").
      // These identify magazine/volume issues and must be present exactly.
      final mixedTokens = gameTokens.where((t) => mixedTokenRegExp.hasMatch(t)).toList();
      if (mixedTokens.isNotEmpty) {
        candidateNames = candidateNames.where((name) {
          final tokens = name.split(' ');
          // Require each mixed token to appear as a full token in candidate.
          for (final mt in mixedTokens) {
            if (!tokens.contains(mt)) return false;
          }
          return true;
        }).toSet();

        if (candidateNames.isEmpty) {
          return game; // No candidates satisfy mixed-token requirement
        }
      }

      // After we have candidateNames but before we build searchSpace
      final hasMixedTokensInGame = mixedTokens.isNotEmpty;

      candidateNames = candidateNames.where((name) {
        // If the game has no mixed tokens, reject any candidate that contains one.
        if (!hasMixedTokensInGame && RegExp(r'\b[a-z]+\d+\b').hasMatch(name)) {
          return false;
        }
        return true;
      }).toSet();

      if (candidateNames.isEmpty) return game; // nothing left ⇒ no match

      final Iterable<String> searchSpace = candidateNames;

      // Build a set of non-numeric tokens from the game title for fast lookup.
      final Set<String> nonNumericTokens = {
        for (final t in gameTokens)
          if (!numericRegExp.hasMatch(t)) t
      };
      // Prefer the first non-numeric token as the main title keyword.
      final mainTitle = gameTokens.firstWhere(
        (t) => !numericRegExp.hasMatch(t),
        orElse: () => gameTokens.isNotEmpty ? gameTokens.first : '',
      );

      String? bestMatchName;
      int highestScore = 0;
      for (final candidate in searchSpace) {
        // If we have non-numeric tokens, ensure the candidate shares at least
        // one of them (e.g. avoid matching solely on the number "16").
        if (nonNumericTokens.isNotEmpty && !nonNumericTokens.any((t) => candidate.contains(t))) {
          continue;
        }

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
      // Keep token if it is digits-only OR length > 2 OR alpha-numeric (like d2)
      if (!(RegExp(r'^\d+$').hasMatch(token) || token.length > 2 || RegExp(r'^[a-z]+\d+$').hasMatch(token))) {
        continue;
      }
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

  final numericExp = RegExp(r'^\d{2,}$');

  for (final gameToken in gameTokens) {
    final isNumeric = numericExp.hasMatch(gameToken);

    if (isNumeric) {
      // Numeric tokens are strong indicators (e.g., version numbers)
      if (boxartTokens.contains(gameToken)) {
        score += 4; // Strong positive signal
      } else {
        score -= 3; // Missing expected numeric token – heavy penalty
      }
      continue;
    }

    if (gameToken.length > 2) {
      if (boxartTokens.any((token) => token.contains(gameToken))) {
        score += 2;
      } else if (boxartName.contains(gameToken)) {
        score += 1;
      }
    }
  }

  // Penalize large token set differences to avoid loose matches like "tales" vs "dragon tales"
  final tokenDifference = (boxartTokens.length - gameTokens.length).abs();
  if (tokenDifference > 2) {
    score -= 1;
  }

  if (gameTokens.length == boxartTokens.length) {
    score += 1;
  }

  return score;
}
