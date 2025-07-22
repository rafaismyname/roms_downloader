import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roms_downloader/models/favorites_model.dart';
import 'package:roms_downloader/services/favorites_service.dart';

class FavoritesNotifier extends StateNotifier<Favorites> {
  final FavoritesService _service = FavoritesService();

  FavoritesNotifier() : super(Favorites(lastUpdated: DateTime.now())) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = await _service.loadFavorites();
  }

  Future<void> toggleFavorite(String gameId) async {
    final newGameIds = Set<String>.from(state.gameIds);
    if (newGameIds.contains(gameId)) {
      newGameIds.remove(gameId);
    } else {
      newGameIds.add(gameId);
    }
    
    state = state.copyWith(gameIds: newGameIds);
    await _service.saveFavorites(state);
  }

  Future<void> addFavorite(String gameId) async {
    if (!state.gameIds.contains(gameId)) {
      final newGameIds = Set<String>.from(state.gameIds)..add(gameId);
      state = state.copyWith(gameIds: newGameIds);
      await _service.saveFavorites(state);
    }
  }

  Future<void> removeFavorite(String gameId) async {
    if (state.gameIds.contains(gameId)) {
      final newGameIds = Set<String>.from(state.gameIds)..remove(gameId);
      state = state.copyWith(gameIds: newGameIds);
      await _service.saveFavorites(state);
    }
  }

  Future<String> exportFavorites() async {
    final slug = await _service.exportFavorites(state);
    state = state.copyWith(
      exportSlug: slug,
      lastExported: DateTime.now(),
    );
    await _service.saveFavorites(state);
    return slug;
  }

  Future<void> importFavorites(String slug, {bool merge = true}) async {
    final importedGameIds = await _service.importFavorites(slug);
    
    final newGameIds = merge 
        ? (Set<String>.from(state.gameIds)..addAll(importedGameIds))
        : importedGameIds;
    
    state = state.copyWith(gameIds: newGameIds);
    await _service.saveFavorites(state);
  }

  Future<void> deleteExport() async {
    await _service.deleteExport();
    state = state.copyWith(
      clearExportSlug: true,
      clearLastExported: true,
    );
    await _service.saveFavorites(state);
  }

  Future<void> clearFavorites() async {
    state = Favorites(lastUpdated: DateTime.now());
    await _service.clearFavorites();
  }

  bool isFavorite(String gameId) => state.isFavorite(gameId);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Favorites>((ref) {
  return FavoritesNotifier();
});
