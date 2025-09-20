import 'dart:async';
import 'dart:io';

import '../../domain/models/recipe.dart';
import '../services/recipe_storage_service.dart';
import '../../utils/logger.dart';
import '../services/image_cache_service.dart';

/// Repository for CRUD operations on persisted recipes.
/// Keeps an in-memory cache and persists to disk on each mutation.
class RecipeRepository {
  final RecipeStorageService _storage;
  final Map<String, Recipe> _cache = {};
  bool _initialized = false;
  final List<void Function()> _listeners = [];

  RecipeRepository(this._storage);

  Future<void> init() async {
    if (_initialized) return;
    final all = await _storage.loadAll();
    for (final r in all) {
      _cache[r.id] = r;
    }
    _initialized = true;
    // Prune any orphaned images on startup
    try {
      await imageCacheService.pruneUnusedImages(_cache.keys.toSet());
    } catch (e, st) {
      Logger.e('Image prune on init failed', e, st);
    }
  }

  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void _notify() {
    for (final l in List<void Function()>.from(_listeners)) {
      try { l(); } catch (e, st) { Logger.e('Listener error', e, st); }
    }
  }

  Future<List<Recipe>> getAll() async {
    await init();
    final list = _cache.values.toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Recipe?> getById(String id) async {
    await init();
    return _cache[id];
  }

  Future<void> upsert(Recipe recipe) async {
    await init();
    final existing = _cache[recipe.id];
    // If image URL changed, drop old cached image.
    if (existing != null && existing.imagePath != null && existing.imagePath!.isNotEmpty) {
      if (existing.imageUrl != recipe.imageUrl) {
        await imageCacheService.deleteImageAtPath(existing.imagePath);
        recipe.imagePath = null;
      }
    }
    // If a path is set but file is gone, try to re-cache from URL.
    if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty) {
      final f = File(recipe.imagePath!);
      if (!f.existsSync() && (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)) {
        await imageCacheService.ensureCachedForRecipe(recipe);
      }
    }
    // Ensure local cache if we have an imageUrl but no local path yet.
    if ((recipe.imagePath == null || recipe.imagePath!.isEmpty) && (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)) {
      await imageCacheService.ensureCachedForRecipe(recipe);
    }

    _cache[recipe.id] = recipe;
    await _persist();
    _notify();
  }

  Future<void> delete(String id) async {
    await init();
    final existing = _cache.remove(id);
    if (existing != null) {
      await imageCacheService.deleteImageAtPath(existing.imagePath);
    }
    await _persist();
    _notify();
  }

  Future<void> _persist() async {
    await _storage.saveAll(_cache.values.toList());
    // Keep images folder clean from orphans
    final ids = _cache.keys.toSet();
    await imageCacheService.pruneUnusedImages(ids);
  }
}

late final RecipeRepository recipeRepository = RecipeRepository(RecipeStorageService());
