import 'package:flutter/material.dart';

import 'package:rezept/data/repositories/category_repository.dart';
import 'package:rezept/data/repositories/recipe_repository.dart';
import 'package:rezept/domain/models/category.dart';
import 'package:rezept/domain/models/recipe.dart';

class CategoriesViewModel extends ChangeNotifier {
  final CategoryRepository _catsRepo;
  final RecipeRepository _recipesRepo;

  CategoriesViewModel({CategoryRepository? categories, RecipeRepository? recipes})
      : _catsRepo = categories ?? categoryRepository,
        _recipesRepo = recipes ?? recipeRepository;

  bool _loading = false;
  bool get loading => _loading;

  List<Category> _categories = const [];
  List<Category> get categories => _categories;

  List<Recipe> _recipes = const [];
  List<Recipe> get recipes => _recipes;

  Future<void> init() async {
    _catsRepo.addListener(_onRepoChange);
    _recipesRepo.addListener(_onRepoChange);
    await load();
  }

  void _onRepoChange() {
    // Reload on any repo change
    load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    await _recipesRepo.init();
    await _catsRepo.init();
    final cats = await _catsRepo.getAll();
    final recs = await _recipesRepo.getAll();
    _categories = cats;
    _recipes = recs;
    _loading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final c = Category(id: UniqueKey().toString(), name: n);
    await _catsRepo.upsert(c);
  }

  Future<void> renameCategory(Category c, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await _catsRepo.upsert(c.copyWith(name: n));
  }

  Future<void> deleteCategory(Category c) async {
    await _catsRepo.delete(c.id);
  }

  bool isAssigned(Category c, Recipe r) => c.recipeIds.contains(r.id);

  Future<void> toggleAssignment(Category c, Recipe r) async {
    final ids = List<String>.from(c.recipeIds);
    final i = ids.indexOf(r.id);
    if (i >= 0) {
      ids.removeAt(i);
    } else {
      ids.add(r.id);
    }
    await _catsRepo.upsert(c.copyWith(recipeIds: ids));
  }

  @override
  void dispose() {
    _catsRepo.removeListener(_onRepoChange);
    _recipesRepo.removeListener(_onRepoChange);
    super.dispose();
  }
}
