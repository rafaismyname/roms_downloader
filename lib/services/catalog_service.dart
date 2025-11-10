import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/utils/network.dart';
import 'package:roms_downloader/utils/title_metadata_parser.dart';
import 'package:roms_downloader/services/boxart_service.dart';

class CatalogService {
  static final Map<String, Map<String, Console>> _consolesCache = {};
  static final Map<String, List<Game>> _catalogCache = {};
  final BoxartService _boxartService = BoxartService();

  Future<Map<String, Console>> getConsoles([String consolesFilePath = 'consoles.json']) async {
    if (_consolesCache.containsKey(consolesFilePath) && _consolesCache[consolesFilePath]!.isNotEmpty) {
      return _consolesCache[consolesFilePath]!;
    }

    String jsonStr = '';
    try {
      final supportDir = await getApplicationSupportDirectory();
      final consolesFile = File(path.join(supportDir.path, 'config', consolesFilePath));
      if (await consolesFile.exists()) {
        jsonStr = await consolesFile.readAsString();
      } else {
        jsonStr = await rootBundle.loadString('assets/$consolesFilePath');
      }
    } catch (e) {
      debugPrint('Error reading consoles file: $e');
      return {};
    }

    final Map<String, dynamic> jsonList = jsonDecode(jsonStr);
    Map<String, Console> consoles = jsonList.map((key, value) {
      final consoleData = {'id': key, ...Map<String, dynamic>.from(value)};
      return MapEntry(key, Console.fromJson(consoleData));
    });

    if (consoles.isNotEmpty) {
      _consolesCache[consolesFilePath] = consoles;
    }

    return consoles;
  }

  Future<List<Game>> loadCatalog(String consoleId) async {
    if (_catalogCache.containsKey(consoleId) && _catalogCache[consoleId]!.isNotEmpty) {
      return _catalogCache[consoleId]!;
    }
    final consoles = await getConsoles();

    if (!consoles.containsKey(consoleId)) {
      debugPrint("Console with id '$consoleId' not found");
      return [];
    }

    Console console = consoles[consoleId]!;

    final cacheFile = await _getCacheFile(console.cacheFile);
    if (await cacheFile.exists()) {
      try {
        final jsonStr = await cacheFile.readAsString();
        final List<Map<String, dynamic>> jsonList = await compute(_decodeGamesIsolate, jsonStr);
        final cachedResult = jsonList.map((json) => Game.fromJson(json)).toList();
        if (cachedResult.isNotEmpty && cachedResult.first.metadata != null) {
          final hasBoxarts = cachedResult.any((game) => game.details?.boxart != null);
          if (!hasBoxarts && console.boxarts != null) {
            final enrichedResult = await _boxartService.mutateGamesWithBoxarts(cachedResult, console);
            await cacheFile.writeAsString(jsonEncode(enrichedResult.map((g) => g.toJson()).toList()));
            _catalogCache[consoleId] = enrichedResult;
            return enrichedResult;
          }
          _catalogCache[consoleId] = cachedResult;
          return cachedResult;
        }
      } catch (e) {
        debugPrint('Error reading cache: $e');
        await cacheFile.delete();
      }
    }

    return _fetchCatalog(console);
  }

  Future<List<Game>> _fetchCatalog(Console console) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    List<Game> catalog = [];

    try {
      final request = await client.getUrl(Uri.parse(console.url));
      final headers = buildDownloadHeaders(console.url);
      headers.forEach(request.headers.set);

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch catalog from ${console.url}');
      }

      final html = await response.transform(utf8.decoder).join();
      final parsed = await compute(_parseHtmlIsolate, [html, console.toJson()]);
      catalog = parsed.map((entry) => Game.fromJson(entry)).toList();
      catalog = await _boxartService.mutateGamesWithBoxarts(catalog, console);
      final cacheFile = await _getCacheFile(console.cacheFile);
      await cacheFile.writeAsString(jsonEncode(catalog.map((g) => g.toJson()).toList()));
      _catalogCache[console.id] = catalog;
    } catch (e) {
      debugPrint('Error fetching catalog: $e');
    } finally {
      client.close();
    }

    return catalog;
  }

  

  Future<File> _getCacheFile(String cacheFile) async {
    final dir = await getApplicationCacheDirectory();
    final cachedFilePath = '${dir.path}/$cacheFile';
    return File(cachedFilePath);
  }

  Future<void> clearCatalogCache([String? consoleId]) async {
    try {
      final consoles = await getConsoles();
      if (consoleId != null) {
        if (consoles.containsKey(consoleId)) {
          final console = consoles[consoleId]!;
          final cacheFile = await _getCacheFile(console.cacheFile);
          if (await cacheFile.exists()) {
            await cacheFile.delete();
          }
          _catalogCache.remove(consoleId);
        }
      } else {
        final consoles = await getConsoles();
        for (final consoleId in consoles.keys) {
          await clearCatalogCache(consoleId);
        }
      }
    } catch (e) {
      debugPrint('Error clearing catalog cache: $e');
    }
  }
}

List<Map<String, dynamic>> _parseHtmlIsolate(List<dynamic> args) {
  final html = args[0] as String;
  final console = args[1] as Map<String, dynamic>;
  final regExp = RegExp((console['regex'] as String?) ?? Console.fromJson(console).defaultRegex, multiLine: true);
  final matches = regExp.allMatches(html);
  final out = <Map<String, dynamic>>[];
  for (final match in matches) {
    final href = match.namedGroup('href');
    final titleRaw = match.namedGroup('title');
    final text = match.namedGroup('text');
    final sizeStr = match.namedGroup('size');
    if (href == null || sizeStr == null) continue;
    final title = titleRaw ?? text ?? href;
    if (title == '.' || title == '..') continue;
    final size = _parseSizeBytesIsolate(sizeStr);
    final baseUrl = console['url'] as String;
    final fullUrl = href.startsWith('http') ? href : '$baseUrl$href';
    final metadata = TitleMetadataParser.parseRomTitle(title).toJson();
    out.add({'title': title, 'url': fullUrl, 'size': size, 'consoleId': console['id'], 'metadata': metadata});
  }
  return out;
}

int _parseSizeBytesIsolate(String sizeStr) {
  try {
    final trimmed = sizeStr.trim();
    if (trimmed.isEmpty) return 0;
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]*)$').firstMatch(trimmed);
    if (match == null) return 0;
    final numVal = double.tryParse(match.group(1)! ) ?? 0.0;
    final unit = match.group(2)!;
    switch (unit.toLowerCase()) {
      case 'k':
      case 'kb':
      case 'kib':
        return (numVal * 1024).round();
      case 'm':
      case 'mb':
      case 'mib':
        return (numVal * 1024 * 1024).round();
      case 'g':
      case 'gb':
      case 'gib':
        return (numVal * 1024 * 1024 * 1024).round();
      default:
        return numVal.round();
    }
  } catch (_) {
    return 0;
  }
}

List<Map<String, dynamic>> _decodeGamesIsolate(String jsonStr) {
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list.whereType<Map<String, dynamic>>().toList();
}
