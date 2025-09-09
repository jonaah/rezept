import 'package:flutter/material.dart';

import '../../../data/repositories/recipe_repository.dart';
import '../../../domain/models/recipe.dart';

class MainPageViewModel extends ChangeNotifier {
  final RecipeRepository _repo;

  MainPageViewModel({RecipeRepository? repository})
      : _repo = repository ?? recipeRepository;

  bool _loading = false;
  bool get loading => _loading;

  List<Recipe> _recipes = const [];
  List<Recipe> get recipes => _recipes;

  void _notifyRepoChange() {
    // Reload list when repository changes (upsert/delete)
    load();
  }

  Future<void> init() async {
    _repo.addListener(_notifyRepoChange);
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final list = await _repo.getAll();
    _recipes = list;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _repo.removeListener(_notifyRepoChange);
    super.dispose();
  }
}