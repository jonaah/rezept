import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/category.dart';
import '../../utils/logger.dart';

/// Low-level persistence service storing categories as JSON in a single file.
class CategoryStorageService {
  static const _fileName = 'categories.json';
  File? _file;
  final Future<Directory> Function()? _dirProvider;

  CategoryStorageService({Future<Directory> Function()? directoryProvider}) : _dirProvider = directoryProvider;

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
      Logger.e('Falling back to temp directory for category storage', e, st);
      dir = Directory.systemTemp.createTempSync('categories');
    }
    final f = File('${dir.path}/$_fileName');
    if (!(await f.exists())) {
      await f.writeAsString(jsonEncode([]));
    }
    _file = f;
    return f;
  }

  Future<List<Category>> loadAll() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = await compute(_parseCategoriesFromJsonString, content);
      return list;
    } catch (e, st) {
      Logger.e('Failed to load categories', e, st);
      return [];
    }
  }

  Future<void> saveAll(List<Category> categories) async {
    try {
      final file = await _getFile();
      final serialized = categories.map((e) => e.toJson()).toList();
      final jsonStr = await compute(_encodeCategoriesToJsonString, serialized);
      await file.writeAsString(jsonStr);
    } catch (e, st) {
      Logger.e('Failed to save categories', e, st);
    }
  }
}

// Top-level helpers for compute()
List<Category> _parseCategoriesFromJsonString(String content) {
  final decoded = jsonDecode(content);
  if (decoded is List) {
    return decoded.map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
  return <Category>[];
}

String _encodeCategoriesToJsonString(List<dynamic> serialized) {
  return jsonEncode(serialized);
}
