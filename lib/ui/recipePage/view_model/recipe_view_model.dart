import 'package:flutter/foundation.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../domain/models/recipe.dart';

enum RecipeViewStatus { loading, ready, notFound }

class RecipeViewModel extends ChangeNotifier {
  final RecipeRepository _repo;
  final String recipeId;
  Recipe? recipe;
  RecipeViewStatus status = RecipeViewStatus.loading;

  RecipeViewModel({required this.recipeId, RecipeRepository? repository}) : _repo = repository ?? recipeRepository;

  Future<void> load() async {
    status = RecipeViewStatus.loading;
    notifyListeners();
    final r = await _repo.getById(recipeId);
    if (r == null) {
      status = RecipeViewStatus.notFound;
    } else {
      recipe = r;
      status = RecipeViewStatus.ready;
    }
    notifyListeners();
  }

  Future<void> delete() async {
    await _repo.delete(recipeId);
    // After deletion mark as notFound so UI can react (pop, etc.)
    recipe = null;
    status = RecipeViewStatus.notFound;
    notifyListeners();
  }
}

