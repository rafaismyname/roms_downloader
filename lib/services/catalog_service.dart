import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roms_downloader/data/consoles.dart';
import 'package:roms_downloader/models/console_model.dart';
import 'package:roms_downloader/models/game_model.dart';

class CatalogService {
  Future<List<Console>> getConsoles() async {
    // TODO1: fetch from json instead of hardcoded list
    return getConsolesList();
  }

  Future<List<Game>> loadCatalog(String consoleId) async {
    final consoles = await getConsoles();
    final console = consoles.firstWhere(
      (c) => c.id == consoleId,
      orElse: () => throw Exception("Console with id '$consoleId' not found"),
    );

    final cacheFile = await _getCacheFile(console.cacheFile);
    if (await cacheFile.exists()) {
      try {
        final jsonStr = await cacheFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList.map((json) => Game.fromJson(json)).toList();
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
    client.userAgent = 'Mozilla/5.0 (compatible; Flutter app)';

    List<Game> catalog = [];

    try {
      final request = await client.getUrl(Uri.parse(console.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch catalog from ${console.url}');
      }

      final html = await response.transform(utf8.decoder).join();
      catalog = _parseHtml(html, console);

      final cacheFile = await _getCacheFile(console.cacheFile);
      await cacheFile.writeAsString(jsonEncode(catalog.map((g) => g.toJson()).toList()));
    } catch (e) {
      debugPrint('Error fetching catalog: $e');
    } finally {
      client.close();
    }

    return catalog;
  }

  List<Game> _parseHtml(String html, Console console) {
    // TODO1: Implement console-specific regex using named groups (href, title, text, size)
    // Format: <tr><td class="link"><a href="URL" title="TITLE">TEXT</a></td><td class="size">SIZE</td>...
    final regExp = RegExp(
      r'<tr><td class="link"><a href="(?<href>[^"]+)" title="(?<title>[^"]+)">(?<text>[^<]+)</a></td><td class="size">(?<size>[^<]+)</td><td class="date">[^<]*</td></tr>',
      multiLine: true,
    );

    final matches = regExp.allMatches(html);
    final games = <Game>[];

    for (final match in matches) {
      final href = match.namedGroup('href')!;
      final title = match.namedGroup('title') ?? match.namedGroup('text')!;
      final sizeStr = match.namedGroup('size')!;

      final sizeBytes = _parseSizeBytes(sizeStr);
      final fullUrl = href.startsWith('http') ? href : '${console.url}$href';

      games.add(Game(
        title: title,
        url: fullUrl,
        size: sizeBytes,
        consoleId: console.id,
      ));
    }

    return games;
  }

  int _parseSizeBytes(String sizeStr) {
    try {
      final trimmed = sizeStr.trim();
      if (trimmed.isEmpty) return 0;

      final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]*)$').firstMatch(trimmed);
      if (match == null) return 0;

      final num = double.tryParse(match.group(1)!) ?? 0.0;
      final unit = match.group(2)!;

      switch (unit.toLowerCase()) {
        case "k":
        case "kb":
        case "kib":
          return (num * 1024).round();
        case "m":
        case "mb":
        case "mib":
          return (num * 1024 * 1024).round();
        case "g":
        case "gb":
        case "gib":
          return (num * 1024 * 1024 * 1024).round();
        default:
          return num.round();
      }
    } catch (e) {
      debugPrint('Error parsing size "$sizeStr": $e');
      return 0;
    }
  }

  Future<File> _getCacheFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    debugPrint('Catalog Cache directory: ${dir.path}');
    return File('${dir.path}/$filename');
  }
}
