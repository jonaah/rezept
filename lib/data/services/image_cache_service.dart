// Utility service to download, compress, and cache recipe images locally.
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/recipe.dart';
import '../../utils/logger.dart';

class ImageCacheService {
  final Future<Directory> Function()? _dirProvider;
  ImageCacheService({Future<Directory> Function()? directoryProvider}) : _dirProvider = directoryProvider;

  Future<Directory> _getImagesDir() async {
    Directory base;
    try {
      final prov = _dirProvider;
      if (prov != null) {
        base = await prov();
      } else {
        base = await getApplicationDocumentsDirectory();
      }
    } catch (e, st) {
      Logger.e('Falling back to temp directory for images', e, st);
      base = await Directory.systemTemp.createTemp('recipes_images');
    }
    final dir = Directory(p.join(base.path, 'images'));
    if (!(await dir.exists())) await dir.create(recursive: true);
    return dir;
  }

  // Download from URL, resize and compress to JPEG, and save under images/<recipeId>.jpg
  Future<String?> cacheImageFromUrl(String url, String recipeId) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        Logger.d('Invalid image URL: $url');
        return null;
      }
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        Logger.d('Image download failed: HTTP ${resp.statusCode} for $url');
        return null;
      }
      final data = resp.bodyBytes;
      return await _compressAndStore(data, recipeId);
    } catch (e, st) {
      Logger.e('Failed to cache image from $url', e, st);
      return null;
    }
  }

  Future<String?> _compressAndStore(Uint8List bytes, String recipeId) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        Logger.d('Could not decode image for recipe $recipeId');
        return null;
      }
      final maxDim = 1600; // balance of quality and size
      img.Image image = decoded;
      if (image.width > maxDim || image.height > maxDim) {
        image = img.copyResize(image, width: image.width >= image.height ? maxDim : null, height: image.height > image.width ? maxDim : null);
      }
      // If image has alpha, composite onto white background before JPEG encode
      if (image.hasAlpha) {
        final bg = img.Image(width: image.width, height: image.height);
        img.fill(bg, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(bg, image);
        image = bg;
      }
      final jpg = img.encodeJpg(image, quality: 80);
      final dir = await _getImagesDir();
      final file = File(p.join(dir.path, '$recipeId.jpg'));
      await file.writeAsBytes(jpg, flush: true);
      return file.path;
    } catch (e, st) {
      Logger.e('Failed to compress/store image for $recipeId', e, st);
      return null;
    }
  }

  // Store a local image file (e.g., from gallery) into the cache, compressed.
  Future<String?> cacheImageFromFile(File file, String recipeId) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return await _compressAndStore(bytes, recipeId);
    } catch (e, st) {
      Logger.e('Failed to cache image from local file ${file.path}', e, st);
      return null;
    }
  }

  Future<void> deleteImageAtPath(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (e, st) {
      Logger.e('Failed to delete image at $path', e, st);
    }
  }

  // Convenience for recipes
  Future<void> ensureCachedForRecipe(Recipe recipe) async {
    if (recipe.imageUrl == null || recipe.imageUrl!.isEmpty) return;
    final newPath = await cacheImageFromUrl(recipe.imageUrl!, recipe.id);
    if (newPath != null) {
      recipe.imagePath = newPath;
    }
  }

  // Remove cached images that don't belong to current recipes
  Future<void> pruneUnusedImages(Set<String> usedRecipeIds) async {
    try {
      final dir = await _getImagesDir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        final id = name.split('.').first;
        if (!usedRecipeIds.contains(id)) {
          try {
            await entity.delete();
          } catch (e, st) {
            Logger.e('Failed to delete orphan image ${entity.path}', e, st);
          }
        }
      }
    } catch (e, st) {
      Logger.e('Failed to prune unused images', e, st);
    }
  }
}

final ImageCacheService imageCacheService = ImageCacheService();
