import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:roms_downloader/models/app_models.dart';
import 'package:roms_downloader/services/directory_service.dart';
import 'package:roms_downloader/data/consoles.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final directoryService = ref.watch(directoryServiceProvider);
  return CatalogService(directoryService);
});

class CatalogService {
  final DirectoryService directoryService;
  String? _loadingStatus;
  List<Game> _catalog = [];

  CatalogService(this.directoryService);

  Future<List<Console>> getConsoles() async {
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
        _catalog = jsonList.map((json) => Game.fromJson(json)).toList();
        _loadingStatus = null;
        return _catalog;
      } catch (e) {
        print('Error reading cache: $e');
      }
    }

    _loadingStatus = "Preparing to load ${console.name}...";

    _fetchCatalog(console);

    throw Exception("Loading catalog...");
  }

  Future<void> _fetchCatalog(Console console) async {
    try {
      final client = http.Client();
      final response = await client.get(
        Uri.parse(console.url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter app)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final html = response.body;
        final games = _parseHtml(html, console);

        final cacheFile = await _getCacheFile(console.cacheFile);
        await cacheFile.writeAsString(jsonEncode(games.map((g) => g.toJson()).toList()));

        _catalog = games;
        _loadingStatus = null;
      } else {
        throw Exception('Failed to load catalog: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      _loadingStatus = "Error: $e";
      print('Error fetching catalog: $e');
    }
  }

  List<Game> _parseHtml(String html, Console console) {
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
    print('Cache directory: ${dir.path}');
    return File('${dir.path}/$filename');
  }

  Future<List<Game>> getCatalog() async {
    return _catalog;
  }

  Future<String?> getLoadingStatus() async {
    return _loadingStatus;
  }
}
