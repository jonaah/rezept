// filepath: /Users/Jonah/FlutterApps/lib/ui/recipe_edit/view_model/create_edit_recipe_view_model.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../domain/models/recipe.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../data/services/image_cache_service.dart';
import '../../../utils/logger.dart';

enum CreateEditStatus { loading, ready, error }

class CreateEditRecipeViewModel extends ChangeNotifier {
  final String? recipeId; // null => create new
  CreateEditStatus status = CreateEditStatus.loading;
  Recipe? recipe;
  String? errorMessage;
  bool _saving = false;
  bool get isSaving => _saving;

  CreateEditRecipeViewModel({this.recipeId});

  Future<void> init() async {
    status = CreateEditStatus.loading;
    notifyListeners();
    try {
      if (recipeId == null) {
        // Create a fresh recipe with generated id
        recipe = Recipe(
          id: _newId(),
          title: 'Unbenanntes Rezept',
          description: '',
          ingredients: <String>[],
          steps: <String>[],
          imageUrl: null,
          imagePath: null,
          servings: null,
        );
        status = CreateEditStatus.ready;
      } else {
        final r = await recipeRepository.getById(recipeId!);
        if (r == null) {
          errorMessage = 'Rezept nicht gefunden';
          status = CreateEditStatus.error;
        } else {
          recipe = r;
          status = CreateEditStatus.ready;
        }
      }
    } catch (e, st) {
      Logger.e('Init add/edit failed', e, st);
      errorMessage = e.toString();
      status = CreateEditStatus.error;
    }
    notifyListeners();
  }

  bool get canSave {
    final r = recipe;
    if (r == null) return false;
    if (_saving) return false;
    return r.title.trim().isNotEmpty;
  }

  Future<bool> save() async {
    if (!canSave) return false;
    _saving = true; notifyListeners();
    try {
      await recipeRepository.upsert(recipe!);
      return true;
    } catch (e, st) {
      Logger.e('Save add/edit failed', e, st);
      return false;
    } finally {
      _saving = false; notifyListeners();
    }
  }

  // ---------- Editing API ----------
  void updateTitle(String value) { final r = recipe; if (r == null) return; r.title = value; notifyListeners(); }
  void updateDescription(String value) { final r = recipe; if (r == null) return; r.description = value; notifyListeners(); }
  void updateServings(String value) { final r = recipe; if (r == null) return; r.servings = value; notifyListeners(); }
  void updateImageUrl(String value) {
    final r = recipe; if (r == null) return;
    r.imageUrl = value.isEmpty ? null : value;
    // Clear local image if a URL is set instead; cached file may be replaced on save
    r.imagePath = null;
    notifyListeners();
  }
  void addIngredient([String value = '']) { final r = recipe; if (r == null) return; r.ingredients.add(value); notifyListeners(); }
  void updateIngredient(int index, String value) { final r = recipe; if (r == null) return; if (index < 0 || index >= r.ingredients.length) return; r.ingredients[index] = value; notifyListeners(); }
  void removeIngredient(int index) { final r = recipe; if (r == null) return; if (index < 0 || index >= r.ingredients.length) return; r.ingredients.removeAt(index); notifyListeners(); }
  void addStep([String value = '']) { final r = recipe; if (r == null) return; r.steps.add(value); notifyListeners(); }
  void updateStep(int index, String value) { final r = recipe; if (r == null) return; if (index < 0 || index >= r.steps.length) return; r.steps[index] = value; notifyListeners(); }
  void removeStep(int index) { final r = recipe; if (r == null) return; if (index < 0 || index >= r.steps.length) return; r.steps.removeAt(index); notifyListeners(); }

  Future<void> setLocalImage(File file) async {
    final r = recipe; if (r == null) return;
    try {
      final path = await imageCacheService.cacheImageFromFile(file, r.id);
      if (path != null) {
        r.imagePath = path;
        r.imageUrl = null; // prefer local image
      }
    } catch (e, st) {
      Logger.e('Set local image failed', e, st);
    }
    notifyListeners();
  }

  Future<void> removeImage() async {
    final r = recipe; if (r == null) return;
    try {
      await imageCacheService.deleteImageAtPath(r.imagePath);
    } catch (_) {}
    r.imagePath = null; r.imageUrl = null; notifyListeners();
  }

  static String _newId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32).toRadixString(16);
    return '$ts-$rnd';
  }
}

