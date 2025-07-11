import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_details_model.dart';

class BoxartService {
  static final Map<String, Map<String, String>> _boxartCache = {};

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
      final normalizedName = _normalizeGameName(nameWithoutExt);
      final fullUrl = baseUrl.endsWith('/') ? '$baseUrl$filename' : '$baseUrl/$filename';
      boxartMap[normalizedName] = fullUrl;
    }

    return boxartMap;
  }

  Future<List<Game>> enrichGamesWithBoxarts(List<Game> games, Console console) async {
    if (console.boxarts == null) return games;

    final boxarts = await _fetchBoxartUrls(console.boxarts!);
    if (boxarts.isEmpty) return games;

    return await compute(_enrichGamesInIsolate, [games, boxarts]);
  }
}

List<Game> _enrichGamesInIsolate(List<dynamic> data) {
  final games = data[0] as List<Game>;
  final boxarts = data[1] as Map<String, String>;
  
  return games.map((game) {
    final gameNameWithoutExt = path.basenameWithoutExtension(game.filename);
    final normalizedGameName = _normalizeGameName(gameNameWithoutExt);
    
    String? boxartUrl = boxarts[normalizedGameName];
    
    boxartUrl ??= _findBestMatch(normalizedGameName, boxarts);
    
    if (boxartUrl != null) {
      final details = GameDetails(
        gameId: game.taskId,
        boxart: boxartUrl,
      );
      return Game(
        title: game.title,
        url: game.url,
        size: game.size,
        consoleId: game.consoleId,
        metadata: game.metadata,
        details: details,
      );
    }
    
    return game;
  }).toList();
}

String _normalizeGameName(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _findBestMatch(String normalizedGameName, Map<String, String> boxarts) {
  final gameTokens = normalizedGameName.split(' ');
  final mainTitle = gameTokens.isNotEmpty ? gameTokens.first : '';
  
  String? bestMatch;
  int highestScore = 0;
  
  for (final boxartName in boxarts.keys) {
    final score = _calculateSimilarity(normalizedGameName, boxartName, mainTitle);
    if (score > highestScore && score > 2) {
      highestScore = score;
      bestMatch = boxarts[boxartName];
    }
  }
  
  return bestMatch;
}

int _calculateSimilarity(String gameName, String boxartName, String mainTitle) {
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
