import '../../domain/models/recipe.dart';
import '../services/recipe_extraction_service.dart';

/// Repository facade for recipe extraction (could later combine caching, persistence, etc.).
class RecipeExtractionRepository {
  final RecipeExtractionService _service;
  final Future<Recipe> Function(String url)? _overrideExtractor;
  const RecipeExtractionRepository(this._service, {Future<Recipe> Function(String url)? overrideExtractor})
      : _overrideExtractor = overrideExtractor;

  Future<Recipe> extract(String url) => _overrideExtractor != null
      ? _overrideExtractor(url)
      : _service.extractFromUrl(url);
  Recipe parseHtml(String html, {String? sourceUrl}) => _service.parseHtml(html, sourceUrl: sourceUrl);
}
