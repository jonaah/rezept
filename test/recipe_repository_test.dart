import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rezept/data/repositories/recipe_repository.dart';
import 'package:rezept/data/services/recipe_storage_service.dart';
import 'package:rezept/domain/models/recipe.dart';

void main() {
  group('RecipeRepository persistence', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('recipe_repo_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('upsert and retrieval in same instance', () async {
      final storage = RecipeStorageService(directoryProvider: () async => tempDir);
      final repo = RecipeRepository(storage);
      await repo.init();
      expect((await repo.getAll()).length, 0);

      final r = Recipe(id: 'r1', title: 'Test Rezept', ingredients: ['A', 'B'], steps: ['Do this']);
      await repo.upsert(r);
      final fetched = await repo.getById('r1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Test Rezept');
      expect((await repo.getAll()).length, 1);
    });

    test('persistence across repository instances', () async {
      final storage1 = RecipeStorageService(directoryProvider: () async => tempDir);
      final repo1 = RecipeRepository(storage1);
      await repo1.init();
      final r = Recipe(id: 'persist', title: 'Persist');
      await repo1.upsert(r);

      // New repository reading same directory
      final storage2 = RecipeStorageService(directoryProvider: () async => tempDir);
      final repo2 = RecipeRepository(storage2);
      await repo2.init();
      final fetched = await repo2.getById('persist');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Persist');
    });
  });
}

