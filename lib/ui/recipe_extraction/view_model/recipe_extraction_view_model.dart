import 'package:flutter/foundation.dart';
import '../../../data/repositories/recipe_extraction_repository.dart';
import '../../../data/services/recipe_extraction_service.dart';
import '../../../domain/models/recipe.dart';
import '../../../utils/logger.dart';
import '../../../data/repositories/recipe_repository.dart';

enum RecipeExtractionStatus { idle, loading, success, error }

class RecipeExtractionViewModel extends ChangeNotifier {
  final RecipeExtractionRepository _repo;
  RecipeExtractionViewModel({RecipeExtractionRepository? repository})
      : _repo = repository ?? RecipeExtractionRepository(const RecipeExtractionService());

  String url = '';
  RecipeExtractionStatus status = RecipeExtractionStatus.idle;
  Recipe? recipe;
  String? errorMessage;
  bool _saving = false;
  bool get isSaving => _saving;

  bool get canExtract => url.trim().isNotEmpty && status != RecipeExtractionStatus.loading;
  bool get canSave => status == RecipeExtractionStatus.success && recipe != null && !_saving;

  Future<void> extract() async {
    final target = url.trim();
    if (target.isEmpty) return;
    status = RecipeExtractionStatus.loading;
    errorMessage = null;
    recipe = null;
    notifyListeners();
    try {
      final r = await _repo.extract(target);
      recipe = r;
      status = RecipeExtractionStatus.success;
    } catch (e, st) {
      Logger.e('Extraction failed', e, st);
      errorMessage = e.toString();
      status = RecipeExtractionStatus.error;
    }
    notifyListeners();
  }

  Future<bool> saveCurrent() async {
    if (!canSave) return false;
    _saving = true;
    notifyListeners();
    try {
      await recipeRepository.upsert(recipe!);
      return true;
    } catch (e, st) {
      Logger.e('Save recipe failed', e, st);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void setUrl(String value) {
    url = value;
    notifyListeners();
  }

  void reset() {
    url = '';
    recipe = null;
    errorMessage = null;
    status = RecipeExtractionStatus.idle;
    notifyListeners();
  }

  // ---------- Editing API ----------
  void updateTitle(String value) {
    final r = recipe; if (r == null) return; r.title = value; notifyListeners();
  }

  void updateDescription(String value) {
    final r = recipe; if (r == null) return; r.description = value; notifyListeners();
  }

  void updateServings(String value) {
    final r = recipe; if (r == null) return; r.servings = value; notifyListeners();
  }

  void updateImageUrl(String value) {
    final r = recipe; if (r == null) return; r.imageUrl = value.isEmpty ? null : value; notifyListeners();
  }

  void addIngredient([String value = '']) {
    final r = recipe; if (r == null) return; r.ingredients.add(value); notifyListeners();
  }

  void updateIngredient(int index, String value) {
    final r = recipe; if (r == null) return; if (index < 0 || index >= r.ingredients.length) return; r.ingredients[index] = value; notifyListeners();
  }

  void removeIngredient(int index) {
    final r = recipe; if (r == null) return; if (index < 0 || index >= r.ingredients.length) return; r.ingredients.removeAt(index); notifyListeners();
  }

  void addStep([String value = '']) {
    final r = recipe; if (r == null) return; r.steps.add(value); notifyListeners();
  }

  void updateStep(int index, String value) {
    final r = recipe; if (r == null) return; if (index < 0 || index >= r.steps.length) return; r.steps[index] = value; notifyListeners();
  }

  void removeStep(int index) {
    final r = recipe; if (r == null) return; if (index < 0 || index >= r.steps.length) return; r.steps.removeAt(index); notifyListeners();
  }
}
