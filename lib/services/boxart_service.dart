import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_details_model.dart';
import 'package:roms_downloader/utils/name_matcher.dart';

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
      final normalizedName = NameMatcher.normalizeName(nameWithoutExt);
      final fullUrl = baseUrl.endsWith('/') ? '$baseUrl$filename' : '$baseUrl/$filename';
      boxartMap[normalizedName] = fullUrl;
    }

    return boxartMap;
  }
}

List<Game> _process(List<dynamic> data) {
  final games = data[0] as List<Game>;
  final boxarts = data[1] as Map<String, String>;

  final tokenIndex = NameMatcher.buildTokenIndex(boxarts.keys);

  return games.map((game) {
    final gameNameWithoutExt = path.basenameWithoutExtension(game.filename);

    final boxartUrl = NameMatcher.match(nameToMatch: gameNameWithoutExt, candidates: boxarts, tokenIndex: tokenIndex);

    if (boxartUrl != null) {
      return game.copyWith(details: GameDetails(boxart: boxartUrl));
    }

    return game;
  }).toList();
}
