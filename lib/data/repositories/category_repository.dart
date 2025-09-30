import 'dart:async';

import 'package:rezept/domain/models/category.dart';
import 'package:rezept/data/services/category_storage_service.dart';
import 'package:rezept/utils/logger.dart';

class CategoryRepository {
  final CategoryStorageService _storage;
  final Map<String, Category> _cache = {};
  bool _initialized = false;
  final List<void Function()> _listeners = [];

  CategoryRepository(this._storage);

  Future<void> init() async {
    if (_initialized) return;
    final all = await _storage.loadAll();
    for (final c in all) {
      _cache[c.id] = c;
    }
    _initialized = true;
  }

  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void _notify() {
    for (final l in List<void Function()>.from(_listeners)) {
      try { l(); } catch (e, st) { Logger.e('Category listener error', e, st); }
    }
  }

  Future<List<Category>> getAll() async {
    await init();
    final list = _cache.values.toList()
      ..sort((a,b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<Category?> getById(String id) async {
    await init();
    return _cache[id];
  }

  Future<void> upsert(Category category) async {
    await init();
    _cache[category.id] = category;
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

late final CategoryRepository categoryRepository = CategoryRepository(CategoryStorageService());
