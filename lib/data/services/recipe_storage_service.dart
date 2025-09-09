import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/recipe.dart';
import '../../utils/logger.dart';

/// Low-level persistence service storing recipes as JSON in a single file.
/// Keeps no in-memory cache; higher layers (repository) may cache.
class RecipeStorageService {
  static const _fileName = 'recipes.json';
  File? _file;
  final Future<Directory> Function()? _dirProvider;

  RecipeStorageService({Future<Directory> Function()? directoryProvider}) : _dirProvider = directoryProvider;

  Future<File> _getFile() async {
    if (_file != null) return _file!;
    Directory dir;
    try {
      final provider = _dirProvider;
      if (provider != null) {
        dir = await provider();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
    } catch (e, st) {
      Logger.e('Falling back to temp directory for storage', e, st);
      dir = Directory.systemTemp.createTempSync('recipes');
    }
    final f = File('${dir.path}/$_fileName');
    if (!(await f.exists())) {
      await f.writeAsString(jsonEncode([]));
    }
    _file = f;
    return f;
  }

  Future<List<Recipe>> loadAll() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
      }
      Logger.e('RecipeStorageService: Expected list root, got ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      Logger.e('Failed to load recipes', e, st);
      return [];
    }
  }

  Future<void> saveAll(List<Recipe> recipes) async {
    try {
      final file = await _getFile();
      final serialized = recipes.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(serialized));
    } catch (e, st) {
      Logger.e('Failed to save recipes', e, st);
    }
  }
}
