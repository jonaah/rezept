import 'package:flutter_test/flutter_test.dart';
import 'package:rezept/data/services/recipe_extraction_service.dart';

void main() {
  test('flattens HowToSection/HowToStep into plain text steps', () {
    const html = '''<html><head>
      <script type="application/ld+json">{
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Test Fajitas",
        "recipeIngredient": ["1 onion", "2 peppers", "300 g mushrooms"],
        "recipeInstructions": [{
          "@type": "HowToSection",
          "name": "Hinweis: Foo",
          "itemListElement": [
            {"@type": "HowToStep", "name": "Preheat oven.", "text": "Preheat the oven to 200 C."},
            {"@type": "HowToStep", "text": "Slice the peppers and onions."},
            {"@type": "HowToStep", "text": "Bake for 30 minutes."}
          ]
        }]
      }</script>
    </head><body></body></html>''';

    final recipe = const RecipeExtractionService().parseHtml(html);
    expect(recipe.title, contains('Fajitas'));
    expect(recipe.steps.isNotEmpty, isTrue);
    expect(recipe.steps.first.toLowerCase(), contains('preheat'));
    expect(recipe.steps.any((s) => s.toLowerCase().contains('slice the peppers')), isTrue);
  });
}

