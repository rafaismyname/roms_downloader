import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roms_downloader/models/favorites_model.dart';
import 'package:roms_downloader/services/zerox0_service.dart';

class FavoritesService {
  static const String _exportSlugKey = 'favorites_export_slug';
  static const String _lastExportedKey = 'favorites_last_exported';
  static const String _fileName = 'favorites.json';

  Future<File> _getFavoritesFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(path.join(directory.path, _fileName));
  }

  Future<Favorites> loadFavorites() async {
    try {
      final file = await _getFavoritesFile();

      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        final exportSlug = prefs.getString(_exportSlugKey);
        final lastExportedStr = prefs.getString(_lastExportedKey);
        final lastExported = lastExportedStr != null ? DateTime.tryParse(lastExportedStr) : null;

        return Favorites.fromJson({
          ...json,
          'exportSlug': exportSlug,
          'lastExported': lastExported?.toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }

    return Favorites(lastUpdated: DateTime.now());
  }

  Future<void> saveFavorites(Favorites favorites) async {
    try {
      final file = await _getFavoritesFile();
      await file.writeAsString(jsonEncode(favorites.toJson()));

      final prefs = await SharedPreferences.getInstance();

      if (favorites.exportSlug != null) {
        await prefs.setString(_exportSlugKey, favorites.exportSlug!);
      } else {
        await prefs.remove(_exportSlugKey);
      }

      if (favorites.lastExported != null) {
        await prefs.setString(_lastExportedKey, favorites.lastExported!.toIso8601String());
      } else {
        await prefs.remove(_lastExportedKey);
      }
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<String> exportFavorites(Favorites favorites) async {
    try {
      final exportData = {
        'gameIds': favorites.gameIds.toList(),
        'version': '1.0',
      };

      final response = await ZeroX0.upload(exportData, previousRecord: favorites.exportSlug, filename: 'roms.fav');

      final parts = response.split(':');
      if (parts.length != 2) throw Exception('Invalid response format');

      return response;
    } catch (e) {
      debugPrint('Error exporting favorites: $e');
      rethrow;
    }
  }

  Future<Set<String>> importFavorites(String slug) async {
    try {
      final data = await ZeroX0.download<Map<String, dynamic>>(slug);

      if (data['version'] != '1.0') {
        throw Exception('Unsupported favorites format version');
      }

      return Set<String>.from(data['gameIds'] ?? []);
    } catch (e) {
      debugPrint('Error importing favorites: $e');
      rethrow;
    }
  }

  Future<void> deleteExport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullRecord = prefs.getString(_exportSlugKey);

      if (fullRecord != null) {
        await ZeroX0.delete(fullRecord);
        await prefs.remove(_exportSlugKey);
        await prefs.remove(_lastExportedKey);
      }
    } catch (e) {
      debugPrint('Error deleting export: $e');
      rethrow;
    }
  }

  Future<void> clearFavorites() async {
    try {
      final file = await _getFavoritesFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }
}
