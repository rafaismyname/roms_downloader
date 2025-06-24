import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roms_downloader/data/consoles.dart';
import 'package:roms_downloader/models/app_models.dart';

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
    // TODO1: Implement named groups for better extensibility (:href, :title, :size)
    // TODO2: Implement console-specific regex using named groups
    // Format: <tr><td class="link"><a href="URL" title="TITLE">TEXT</a></td><td class="size">SIZE</td>...
    final regExp = RegExp(
      r'<tr><td class="link"><a href="([^"]+)" title="([^"]+)">([^<]+)</a></td><td class="size">([^<]+)</td><td class="date">[^<]*</td></tr>',
      multiLine: true,
    );

    final matches = regExp.allMatches(html);
    final games = <Game>[];

    for (final match in matches) {
      final href = match.group(1)!;
      final title = match.group(2)!;
      final sizeStr = match.group(4)!;

      if (!_shouldAcceptGame(title, console)) {
        continue;
      }

      if (!href.endsWith('.7z') && !href.endsWith('.zip') && !href.endsWith('.bin') && !href.endsWith('.img') && !href.endsWith('.iso')) {
        continue;
      }

      final sizeBytes = _parseSizeBytes(sizeStr);
      final cleanTitle = _cleanTitle(title, console);
      final fullUrl = href.startsWith('http') ? href : '${console.url}$href';

      games.add(Game(
        title: cleanTitle,
        url: fullUrl,
        size: sizeBytes,
      ));
    }

    return games;
  }

  bool _shouldAcceptGame(String title, Console console) {
    final isUsa = title.contains("(USA");
    final isDemo = title.toLowerCase().contains("demo");

    final usaFilterPasses = !console.filterUsaOnly || isUsa;
    final demoFilterPasses = !console.excludeDemos || !isDemo;

    return usaFilterPasses && demoFilterPasses;
  }

  String _cleanTitle(String title, Console console) {
    var cleaned = title;
    if (console.filterUsaOnly) {
      cleaned = cleaned.replaceAll("(USA)", "");
    }
    return cleaned.trim();
  }

  int _parseSizeBytes(String sizeStr) {
    final parts = sizeStr.trim().split(' ');
    if (parts.length != 2) return 0;

    final num = double.tryParse(parts[0]) ?? 0.0;
    final unit = parts[1];

    switch (unit) {
      case "KiB":
        return (num * 1024).round();
      case "MiB":
        return (num * 1024 * 1024).round();
      case "GiB":
        return (num * 1024 * 1024 * 1024).round();
      default:
        return 0;
    }
  }

  Future<File> _getCacheFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    debugPrint('Catalog Cache directory: ${dir.path}');
    return File('${dir.path}/$filename');
  }
}
