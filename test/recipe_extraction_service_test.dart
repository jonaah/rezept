import 'package:flutter_test/flutter_test.dart';
import 'package:rezept/data/services/recipe_extraction_service.dart';

void main() {
  group('RecipeExtractionService.parseHtml', () {
    const service = RecipeExtractionService();

    test('parses simple JSON-LD recipe incl servings', () {
      const jsonLd = '''<html><head>
      <script type="application/ld+json">{
        "@context": "https://schema.org/",
        "@type": "Recipe",
        "name": "Pancakes",
        "recipeIngredient": ["200g Flour", "2 Eggs"],
        "recipeInstructions": [
          {"@type": "HowToStep", "text": "Mix ingredients"},
          {"@type": "HowToStep", "text": "Bake"}
        ],
        "prepTime": "PT10M",
        "cookTime": "PT5M",
        "recipeYield": "Serves 4",
        "image": "https://example.com/pancake.jpg"
      }</script></head><body></body></html>''';

      final recipe = service.parseHtml(jsonLd, sourceUrl: 'https://example.com');
      expect(recipe.title, 'Pancakes');
      expect(recipe.ingredients.length, 2);
      expect(recipe.steps.length, 2);
      expect(recipe.prepTime, const Duration(minutes: 10));
      expect(recipe.cookTime, const Duration(minutes: 5));
      expect(recipe.totalTime, const Duration(minutes: 15));
      expect(recipe.sourceUrl, 'https://example.com');
      expect(recipe.imageUrl, 'https://example.com/pancake.jpg');
      expect(recipe.servings, contains('Serves'));
    });

    test('parses microdata recipe', () {
      const html = '''<html><body><div itemscope itemtype="http://schema.org/Recipe">
      <h1 itemprop="name">Microdata Soup</h1>
      <div itemprop="recipeIngredient">2 cups water</div>
      <div itemprop="recipeIngredient">1 tsp salt</div>
      <div itemprop="recipeInstructions">Boil water.</div>
      <div itemprop="recipeInstructions">Add salt.</div>
      <span itemprop="recipeYield">Serves 2</span>
      <img itemprop="image" src="img.jpg" />
      </div></body></html>''';
      final recipe = service.parseHtml(html);
      expect(recipe.title, 'Microdata Soup');
      expect(recipe.ingredients.length, 2);
      expect(recipe.steps.length, 2);
      expect(recipe.servings, 'Serves 2');
    });

    test('heuristic extraction when no structured data exists', () {
      const html = '''<html><head><title>My Heuristic Stew</title></head><body>
      <div class='content'>
        <div>Some intro text not needed.</div>
        <ul>
          <li>500 g beef</li>
          <li>1 onion</li>
          <li>2 carrots</li>
          <li>3 potatoes</li>
          <li>Salt</li>
        </ul>
        <p>Cut the vegetables.</p>
        <p>Cook everything for 40 minutes.</p>
      </div>
      </body></html>''';
      final recipe = service.parseHtml(html);
      expect(recipe.title, contains('Heuristic Stew'));
      expect(recipe.ingredients.length >= 4, isTrue);
      expect(recipe.steps.length >= 2, isTrue);
    });

    test('fallback extraction returns heuristic recipe (legacy naive)', () {
      const html = '<html><body><h1>Test Cake</h1><ul><li>100g Zucker</li><li>50ml Milch</li></ul><p>Erster Schritt mixen.</p><p>Zweiter Schritt backen.</p></body></html>';
      final recipe = service.parseHtml(html);
      expect(recipe.title, anyOf(['Test Cake', contains('Test Cake')]));
      expect(recipe.ingredients, isNotEmpty);
      expect(recipe.steps, isNotEmpty);
    });
  });
}
