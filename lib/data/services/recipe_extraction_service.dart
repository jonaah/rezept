import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../domain/models/recipe.dart';
import '../../utils/logger.dart';

/// Service responsible for fetching and parsing recipe data from a webpage.
class RecipeExtractionService {
  const RecipeExtractionService();

  Future<Recipe> extractFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final String decodedHtml = utf8.decode(response.bodyBytes, allowMalformed: true);
    return parseHtml(decodedHtml, sourceUrl: url);
  }

  /// Parse HTML via multi-stage strategy: JSON-LD -> Microdata -> Heuristic -> Naive.
  Recipe parseHtml(String html, {String? sourceUrl}) {
    final doc = html_parser.parse(html);

    final jsonLd = _parseJsonLd(doc, sourceUrl: sourceUrl);
    if (jsonLd != null) return _finalizeRecipe(jsonLd, sourceUrl: sourceUrl);

    final microdata = _parseMicrodata(doc, sourceUrl: sourceUrl);
    if (microdata != null) return _finalizeRecipe(microdata, sourceUrl: sourceUrl);

    final advanced = _advancedHeuristicExtraction(doc, sourceUrl: sourceUrl);
    if (advanced != null) return _finalizeRecipe(advanced, sourceUrl: sourceUrl);

    return _finalizeRecipe(_naiveFallback(doc, sourceUrl: sourceUrl), sourceUrl: sourceUrl);
  }

  Recipe _finalizeRecipe(Recipe recipe, {String? sourceUrl}) {
    recipe.imageUrl = _resolveUrl(recipe.imageUrl, sourceUrl);
    return recipe;
  }

  String? _resolveUrl(String? maybeUrl, String? base) {
    if (maybeUrl == null || maybeUrl.isEmpty) return maybeUrl;
    final u = Uri.tryParse(maybeUrl);
    if (u == null) return null;
    if (u.hasScheme) return maybeUrl;
    final b = Uri.tryParse(base ?? '');
    if (b == null) return maybeUrl;
    try {
      return b.resolveUri(u).toString();
    } catch (_) {
      return maybeUrl;
    }
  }

  // ---------------- JSON-LD ----------------
  Recipe? _parseJsonLd(dom.Document doc, {String? sourceUrl}) {
    final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
    for (final s in scripts) {
      final content = s.text.trim();
      if (content.isEmpty) continue;
      try {
        final decoded = jsonDecode(content);
        final maybe = _extractRecipeNode(decoded);
        if (maybe != null) {
          Logger.d('Recipe JSON-LD found');
          return Recipe.fromJsonLd(maybe, sourceUrl: sourceUrl);
        }
      } catch (e, st) {
        Logger.e('Failed to parse JSON-LD block', e, st);
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractRecipeNode(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['@graph'] is List) {
        for (final n in decoded['@graph']) {
          final r = _extractRecipeNode(n);
          if (r != null) return r;
        }
      }
      final type = decoded['@type'];
      if (type is String && type.toLowerCase() == 'recipe') return decoded;
      if (type is List && type.map((e) => e.toString().toLowerCase()).contains('recipe')) return decoded;
    } else if (decoded is List) {
      for (final item in decoded) {
        final r = _extractRecipeNode(item);
        if (r != null) return r;
      }
    }
    return null;
  }

  // ---------------- Microdata ----------------
  Recipe? _parseMicrodata(dom.Document doc, {String? sourceUrl}) {
    // Find any element with itemscope + itemtype containing 'Recipe'.
    final scopes = doc.querySelectorAll('[itemscope][itemtype]');
    for (final scope in scopes) {
      final type = scope.attributes['itemtype']?.toLowerCase() ?? '';
      if (!type.contains('recipe')) continue;

      String? name = _firstText(scope.querySelectorAll('[itemprop="name"]'));
      final description = _firstText(scope.querySelectorAll('[itemprop="description"]'));

      final ingNodes = scope.querySelectorAll('[itemprop="recipeIngredient"], [itemprop="ingredients"]');
      final ingredients = ingNodes.map((e) => e.text.trim()).where((t) => t.isNotEmpty).toList();

      final instructionNodes = scope.querySelectorAll('[itemprop="recipeInstructions"], [itemprop="instructions"]');
      final steps = <String>[];
      for (final n in instructionNodes) {
        // Might contain nested instruction steps.
        if (n.children.isEmpty) {
          final tx = n.text.trim();
          if (tx.isNotEmpty) steps.add(tx);
        } else {
          for (final c in n.querySelectorAll('[itemprop="recipeInstructions"], li, p, div')) {
            final tx = c.text.trim();
            if (tx.isNotEmpty && tx.split(' ').length > 2) steps.add(tx);
          }
        }
      }

      final yieldNode = scope.querySelector('[itemprop="recipeYield"],[itemprop="yield"]');
      final servings = yieldNode?.text.trim();

      final imageNode = scope.querySelector('[itemprop="image"]');
      final imageUrl = imageNode?.attributes['src'] ?? imageNode?.attributes['content'] ?? imageNode?.text.trim();

      if ((ingredients.isNotEmpty || steps.isNotEmpty) && (name != null && name.isNotEmpty)) {
        Logger.d('Recipe Microdata found');
        return Recipe(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: name,
          description: description,
            ingredients: ingredients,
            steps: steps,
            imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
            sourceUrl: sourceUrl,
            servings: servings?.isNotEmpty == true ? servings : null,
        );
      }
    }
    return null;
  }

  String? _firstText(List<dom.Element> nodes) {
    for (final n in nodes) {
      final t = n.text.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  // ---------------- Advanced Heuristic ----------------
  Recipe? _advancedHeuristicExtraction(dom.Document doc, {String? sourceUrl}) {
    final body = doc.body;
    if (body == null) return null;

    final title = _extractTitle(doc);
    final image = _extractImage(doc);
    final servings = _extractServings(doc);

    // Collect candidate block elements.
    final blockTags = {'p','li','div','span'};
    final candidates = <dom.Element>[];
    void collect(dom.Element e) {
      if (blockTags.contains(e.localName)) candidates.add(e);
      for (final c in e.children) { collect(c); }
    }
    collect(body);

    final ingredientScores = <dom.Element,double>{};
    final instructionScores = <dom.Element,double>{};

    for (final el in candidates) {
      final text = el.text.trim();
      if (text.isEmpty) continue;
      final ingScore = _scoreIngredient(text);
      final instrScore = _scoreInstruction(text);
      if (ingScore > 0) ingredientScores[el] = ingScore;
      if (instrScore > 0) instructionScores[el] = instrScore;
    }

    if (ingredientScores.isEmpty || instructionScores.isEmpty) return null;

    dom.Element topIngredient = ingredientScores.entries.reduce((a,b)=> a.value >= b.value ? a : b).key;
    dom.Element topInstruction = instructionScores.entries.reduce((a,b)=> a.value >= b.value ? a : b).key;
    if (topIngredient == topInstruction) {
      // Try second best instruction if same.
      final sortedInstr = instructionScores.entries.toList()..sort((a,b)=> b.value.compareTo(a.value));
      if (sortedInstr.length > 1) {
        topInstruction = sortedInstr[1].key;
      }
    }

    final lca = _lowestCommonAncestor(topIngredient, topInstruction) ?? body;

    // Traverse LCA direct and deep children linearly to classify.
    final nodesInOrder = <dom.Element>[];
    void gather(dom.Element e) {
      if (blockTags.contains(e.localName)) nodesInOrder.add(e);
      for (final c in e.children) { gather(c); }
    }
    gather(lca);

    // Determine ingredient and instruction block boundaries.
    final ingredientLike = <dom.Element>[];
    final instructionLike = <dom.Element>[];
    for (final el in nodesInOrder) {
      final txt = el.text.trim();
      if (txt.isEmpty) continue;
      if (_scoreIngredient(txt) >= 0.6) {
        ingredientLike.add(el);
      } else if (_scoreInstruction(txt) >= 0.5) { // lowered threshold
        instructionLike.add(el);
      }
    }
    if (ingredientLike.isEmpty || instructionLike.isEmpty) return null;

    // Ignore everything before first ingredient.
    final firstIngIndex = nodesInOrder.indexOf(ingredientLike.first);
    final pruned = nodesInOrder.sublist(firstIngIndex);

    // Build contiguous blocks.
    final ingredientsText = <String>[];
    final stepsText = <String>[];
    bool inIngredientBlock = true;
    for (final el in pruned) {
      final txt = el.text.trim();
      if (txt.isEmpty) continue;
      final isIng = _scoreIngredient(txt) >= 0.55;
      final isInstr = _scoreInstruction(txt) >= 0.5; // lowered threshold
      if (inIngredientBlock) {
        if (isIng) {
          ingredientsText.add(_cleanLine(txt));
          continue;
        } else if (isInstr && ingredientsText.isNotEmpty) {
          inIngredientBlock = false; // switch to instructions
        } else {
          // ignore noise inside ingredient block until first instruction appears
          continue;
        }
      }
      // instruction phase
      if (!inIngredientBlock && (isInstr || (txt.length > 25 && txt.split(' ').length >= 3))) {
        stepsText.add(_cleanLine(txt));
      }
    }

    final uniqIngredients = _dedupe(ingredientsText);
    final uniqSteps = _dedupe(stepsText);

    if ((uniqIngredients.isEmpty && uniqSteps.isEmpty) || uniqIngredients.length < 4 || uniqSteps.isEmpty) return null;

    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? 'Unbekanntes Rezept',
      ingredients: uniqIngredients.take(40).toList(),
      steps: uniqSteps.take(60).toList(),
      imageUrl: image,
      sourceUrl: sourceUrl,
      servings: servings,
    );
  }

  String? _extractTitle(dom.Document doc) {
    final og = doc.querySelector('meta[property="og:title"],meta[name="og:title"],meta[name="twitter:title"]')?.attributes['content'];
    if (og != null && og.trim().isNotEmpty) return og.trim();
    return doc.querySelector('h1')?.text.trim() ?? doc.querySelector('h2')?.text.trim() ?? doc.querySelector('title')?.text.trim();
  }

  String? _extractImage(dom.Document doc) {
    // Prefer og:image
    final og = doc.querySelector('meta[property="og:image"],meta[name="og:image"]')?.attributes['content'];
    if (og != null && og.trim().isNotEmpty) return og.trim();
    final imgs = doc.querySelectorAll('body img');
    for (final i in imgs) {
      final src = i.attributes['src'] ?? i.attributes['data-src'];
      if (src == null || src.trim().isEmpty) continue;
      final w = int.tryParse(i.attributes['width'] ?? '0');
      final h = int.tryParse(i.attributes['height'] ?? '0');
      if ((w != null && w >= 120) || (h != null && h >= 120) || (w == 0 && h == 0)) {
        return src;
      }
    }
    return null;
  }

  String? _extractServings(dom.Document doc) {
    final regex = RegExp(r'(servings?|serves|makes|yield)\s*[:\-]?\s*(\d+[^<]*)', caseSensitive: false);
    for (final el in doc.querySelectorAll('body *')) {
      final t = el.text.trim();
      if (t.length > 140) continue;
      final m = regex.firstMatch(t);
      if (m != null) {
        return m.group(0)!.trim();
      }
    }
    return null;
  }

  double _scoreIngredient(String text) {
    final lower = text.toLowerCase();
    if (lower.length > 140) return 0;
    int score = 0;
    if (RegExp(r'^\d').hasMatch(lower)) score += 3;
    if (RegExp(r'^\d+\s+[a-zäöü]').hasMatch(lower)) score += 2; // digit + word pattern (e.g., '2 carrots')
    if (RegExp(r'\b(ml|g|kg|l|el|tl|cup|cups|tbsp|tsp|oz|pound|lb|gram|teaspoon|tablespoon)\b').hasMatch(lower)) score += 4;
    if (RegExp(r'\b(salz|salt|butter|öl|oil|olive|sugar|zucker|flour|mehl|garlic|knoblauch|pepper|pfeffer|onion|carrot|potato|potatoes|beef|milk|egg|eggs)\b').hasMatch(lower)) score += 3;
    if (lower.split('.').length > 3) score -= 2;
    if (lower.length < 8) score += 1; // short entries often ingredients
    return score / 12.0; // adjust normalization for added features
  }

  double _scoreInstruction(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 15) return 0;
    int score = 0;
    if (RegExp(r'^[A-ZÄÖÜ]').hasMatch(trimmed)) score += 2;
    if (RegExp(r'[.!?]$').hasMatch(trimmed)) score += 1;
    if (trimmed.length > 100) score += 1;
    if (RegExp(r'\b(Mix|Rühre|Stir|Cook|Heat|Bake|Brate|Add|Gib|Combine|Whisk|Fold|Sprinkle|Serve|Bring|Cut|Chop|Slice|Peel|Boil|Simmer|Fry|Saute|Season|Pour)\b', caseSensitive: false).hasMatch(trimmed)) score += 4;
    if (RegExp(r'\d+').hasMatch(trimmed)) score += 1; // numbers like times/temperatures
    return score / 10.0;
  }

  String _cleanLine(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _dedupe(List<String> lines) {
    final seen = <String>{};
    final out = <String>[];
    for (final l in lines) {
      final k = l.toLowerCase();
      if (seen.add(k)) out.add(l);
    }
    return out;
  }

  dom.Element? _lowestCommonAncestor(dom.Element a, dom.Element b) {
    final ancestorsA = <dom.Element>{};
    dom.Element? cur = a;
    while (cur != null) { ancestorsA.add(cur); cur = cur.parent; }
    dom.Element? curB = b;
    while (curB != null) { if (ancestorsA.contains(curB)) return curB; curB = curB.parent; }
    return null;
  }

  // ---------------- Naive fallback (legacy) ----------------
  Recipe _naiveFallback(dom.Document doc, {String? sourceUrl}) {
    String title = doc.querySelector('h1,h2,title')?.text.trim() ?? 'Unbekanntes Rezept';
    final ingredientCandidates = doc
        .querySelectorAll('li')
        .map((e) => e.text.trim())
        .where((t) => t.length < 120 && _looksLikeIngredient(t))
        .toList();
    final stepCandidates = doc
        .querySelectorAll('p')
        .map((e) => e.text.trim())
        .where((t) => t.split(' ').length >= 3)
        .take(15)
        .toList();
    return Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredientCandidates.take(25).toList(),
      steps: stepCandidates.take(25).toList(),
      sourceUrl: sourceUrl,
    );
  }

  bool _looksLikeIngredient(String text) {
    final lower = text.toLowerCase();
    return lower.contains(RegExp(r'\d')) || lower.contains('g ') || lower.contains('ml ') || lower.contains('el ') || lower.contains('tl ');
  }
}
