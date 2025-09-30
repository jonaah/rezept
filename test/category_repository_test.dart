import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rezept/data/repositories/category_repository.dart';
import 'package:rezept/data/services/category_storage_service.dart';
import 'package:rezept/domain/models/category.dart';

void main() {
  group('CategoryRepository', () {
    late Directory tmpDir;
    late CategoryRepository repo;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('cats_test');
      final storage = CategoryStorageService(directoryProvider: () async => tmpDir);
      repo = CategoryRepository(storage);
      await repo.init();
    });

    tearDown(() async {
      try { await tmpDir.delete(recursive: true); } catch (_) {}
    });

    test('initially empty', () async {
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    test('upsert and retrieve', () async {
      final c = Category(id: 'c1', name: 'Dessert');
      await repo.upsert(c);
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Dessert');
    });

    test('rename persists', () async {
      final c = Category(id: 'c2', name: 'Vegan');
      await repo.upsert(c);
      await repo.upsert(c.copyWith(name: 'Vegan & Glutenfrei'));
      final all = await repo.getAll();
      expect(all.firstWhere((e) => e.id == 'c2').name, contains('Glutenfrei'));
    });

    test('delete removes category', () async {
      final c = Category(id: 'c3', name: 'Pasta');
      await repo.upsert(c);
      await repo.delete('c3');
      final all = await repo.getAll();
      expect(all.where((e) => e.id == 'c3'), isEmpty);
    });

    test('persists to disk across instances', () async {
      final c = Category(id: 'c4', name: 'Suppe');
      await repo.upsert(c);

      // New repo with the same storage location
      final storage2 = CategoryStorageService(directoryProvider: () async => tmpDir);
      final repo2 = CategoryRepository(storage2);
      await repo2.init();
      final all2 = await repo2.getAll();
      expect(all2.any((e) => e.id == 'c4' && e.name == 'Suppe'), isTrue);
    });
  });
}

