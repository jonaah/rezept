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

  // Filter query for main page search.
  String _filterQuery = '';
  String get filterQuery => _filterQuery;
  set filterQuery(String value) {
    final v = value.trim();
    if (v == _filterQuery) return;
    _filterQuery = v;
    notifyListeners();
  }

  // Computed filtered list
  List<Recipe> get filteredRecipes {
    if (_filterQuery.isEmpty) return _recipes;
    final q = _filterQuery.toLowerCase();
    return _recipes.where((r) {
      final inTitle = r.title.toLowerCase().contains(q);
      final inDesc = (r.description ?? '').toLowerCase().contains(q);
      final inIngs = r.ingredients.any((i) => i.toLowerCase().contains(q));
      return inTitle || inDesc || inIngs;
    }).toList(growable: false);
  }

  // Expose a deterministic daily recommendation.
  Recipe? get dailyRecommendation {
    if (_recipes.isEmpty) return null;
    // Use days since epoch to rotate recommendation daily.
    final daysSinceEpoch = DateTime.now().toUtc().difference(DateTime.utc(1970, 1, 1)).inDays;
    final idx = daysSinceEpoch % _recipes.length;
    return _recipes[idx];
  }

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