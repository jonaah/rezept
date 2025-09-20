import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
      // Offload JSON parsing to a background isolate for large files.
      final list = await compute(_parseRecipesFromJsonString, content);
      return list;
    } catch (e, st) {
      Logger.e('Failed to load recipes', e, st);
      return [];
    }
  }

  Future<void> saveAll(List<Recipe> recipes) async {
    try {
      final file = await _getFile();
      final serialized = recipes.map((e) => e.toJson()).toList();
      // Offload JSON encoding to a background isolate for large payloads.
      final jsonStr = await compute(_encodeRecipesToJsonString, serialized);
      await file.writeAsString(jsonStr);
    } catch (e, st) {
      Logger.e('Failed to save recipes', e, st);
    }
  }
}

// Top-level helpers for compute()
List<Recipe> _parseRecipesFromJsonString(String content) {
  final decoded = jsonDecode(content);
  if (decoded is List) {
    return decoded.map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  return <Recipe>[];
}

String _encodeRecipesToJsonString(List<dynamic> serialized) {
  // Expecting a List<Map<String, dynamic>>; ensure JSON-encodable structures
  return jsonEncode(serialized);
}
