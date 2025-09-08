import 'dart:async';

import '../../domain/models/recipe.dart';
import '../services/recipe_storage_service.dart';
import '../../utils/logger.dart';

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
    _cache[recipe.id] = recipe;
    await _persist();
    _notify();
  }

  Future<void> delete(String id) async {
    await init();
    _cache.remove(id);
    await _persist();
    _notify();
  }

  Future<void> _persist() async {
    await _storage.saveAll(_cache.values.toList());
  }
}

late final RecipeRepository recipeRepository = RecipeRepository(RecipeStorageService());
