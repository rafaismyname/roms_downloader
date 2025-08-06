import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:roms_downloader/models/game_model.dart';
import 'package:roms_downloader/models/game_state_model.dart';

class LibraryService {
  static Future<Map<String, GameStatus>> fetchLibraryStatus(
    List<Game> games,
    String downloadDir,
  ) async {
    return await compute(_computeLibraryStatus, (
      games: games,
      downloadDir: downloadDir,
    ));
  }

  static Future<Map<String, GameStatus>> _computeLibraryStatus(({List<Game> games, String downloadDir}) data) async {
    final games = data.games;
    final downloadDir = data.downloadDir;
    final result = <String, GameStatus>{};

    final dir = Directory(downloadDir);
    if (!dir.existsSync()) {
      // If download dir doesn't exist, no games are in library
      for (final game in games) {
        result[game.gameId] = GameStatus.ready;
      }
      return result;
    }

    // Get all files and directories in download dir once
    final Set<String> files = {};
    final Set<String> dirs = {};

    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        final basename = path.basename(entity.path);
        final basenameWithoutExt = path.basenameWithoutExtension(basename);

        if (entity is File) {
          files.add(basename);
          files.add(basenameWithoutExt); // Also index by name without extension
        } else if (entity is Directory) {
          dirs.add(basename);
          dirs.add(basenameWithoutExt);
        }
      }
    } catch (e) {
      debugPrint('Error reading download directory: $e');
      // If we can't read the directory, assume no games are in library
      for (final game in games) {
        result[game.gameId] = GameStatus.ready;
      }
      return result;
    }

    // Check each game
    for (final game in games) {
      final filename = game.filename;
      final filenameWithoutExt = path.basenameWithoutExtension(filename);

      // Check if file exists (exact match) or extracted directory exists
      final hasFile = files.contains(filename);
      if (hasFile) {
        result[game.gameId] = GameStatus.downloaded;
        continue;
      }

      // Check if extracted directory exists or a file with the same base name exists
      final hasExtracted = dirs.contains(filenameWithoutExt);
      final hasFileVariant = !hasFile && !hasExtracted && files.contains(filenameWithoutExt);
      if (hasExtracted || hasFileVariant) {
        result[game.gameId] = GameStatus.extracted;
        continue;
      }

      result[game.gameId] = GameStatus.ready;
    }

    return result;
  }
}
