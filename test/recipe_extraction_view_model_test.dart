import 'package:flutter_test/flutter_test.dart';
import 'package:rezept/domain/models/recipe.dart';
import 'package:rezept/ui/recipe_extraction/view_model/recipe_extraction_view_model.dart';
import 'package:rezept/data/repositories/recipe_extraction_repository.dart';
import 'package:rezept/data/services/recipe_extraction_service.dart';

void main() {
  test('ViewModel success flow', () async {
    final repo = RecipeExtractionRepository(
      const RecipeExtractionService(),
      overrideExtractor: (url) async => Recipe(id: '1', title: 'Test $url'),
    );
    final vm = RecipeExtractionViewModel(repository: repo);
    vm.setUrl('https://example.com');
    expect(vm.canExtract, isTrue);
    await vm.extract();
    expect(vm.status, RecipeExtractionStatus.success);
    expect(vm.recipe, isNotNull);
    expect(vm.recipe!.title, contains('Test'));
  });

  test('ViewModel error flow', () async {
    final repo = RecipeExtractionRepository(
      const RecipeExtractionService(),
      overrideExtractor: (url) async => throw Exception('Boom'),
    );
    final vm = RecipeExtractionViewModel(repository: repo);
    vm.setUrl('https://example.com');
    await vm.extract();
    expect(vm.status, RecipeExtractionStatus.error);
    expect(vm.errorMessage, contains('Boom'));
  });

  test('reset returns to idle', () async {
    final repo = RecipeExtractionRepository(
      const RecipeExtractionService(),
      overrideExtractor: (url) async => Recipe(id: '1', title: 'X'),
    );
    final vm = RecipeExtractionViewModel(repository: repo);
    vm.setUrl('u');
    await vm.extract();
    vm.reset();
    expect(vm.status, RecipeExtractionStatus.idle);
    expect(vm.recipe, isNull);
    expect(vm.url, isEmpty);
  });
}
