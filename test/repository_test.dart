import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:receipt_lens/models/expense.dart';
import 'package:receipt_lens/services/expense_repository.dart';

void main() {
  sqfliteFfiInit();
  test(
    'CRUD persists after database close/reopen and cleans cached images',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt-lens-test');
      final path = p.join(dir.path, 'test.db');
      final image = File(p.join(dir.path, 'receipt.jpg'));
      await image.writeAsBytes([1]);
      var repo = ExpenseRepository(
        databasePath: path,
        factory: databaseFactoryFfi,
      );
      try {
        await repo.save(
          Expense(
            merchant: 'Test shop',
            amount: 150000,
            date: DateTime(2026, 10, 9),
            category: ExpenseCategory.food,
            imagePath: image.path,
          ),
        );
        final id = (await repo.list()).single.id;
        await repo.close();
        repo = ExpenseRepository(
          databasePath: path,
          factory: databaseFactoryFfi,
        );
        expect((await repo.list()).single.amount, 150000);
        await repo.save(
          Expense(
            id: id,
            merchant: 'Corrected shop',
            amount: 125000,
            date: DateTime(2026, 10, 8),
            category: ExpenseCategory.gear,
            imagePath: image.path,
          ),
        );
        final saved = (await repo.list()).single;
        expect(saved.category, ExpenseCategory.gear);
        expect(saved.amount, 125000);
        await repo.delete(saved);
        expect(await repo.list(), isEmpty);
        expect(await image.exists(), isFalse);
      } finally {
        await repo.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test('DB constraint prevents nonpositive expenses', () async {
    final repo = ExpenseRepository(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    try {
      await expectLater(
        repo.save(
          Expense(
            merchant: 'Shop',
            amount: 0,
            date: DateTime(2026),
            category: ExpenseCategory.food,
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    } finally {
      await repo.close();
    }
  });
}
