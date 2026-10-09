import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_lens/core/app_theme.dart';
import 'package:receipt_lens/models/expense.dart';
import 'package:receipt_lens/screens/review_screen.dart';
import 'package:receipt_lens/services/expense_repository.dart';
import 'package:receipt_lens/state/providers.dart';

class MemoryRepository extends ExpenseRepository {
  final records = <Expense>[];
  @override
  Future<List<Expense>> list() async => records;
  @override
  Future<void> save(Expense e) async {
    records.add(e);
  }

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('Review cannot save without date and explicit verification', (
    tester,
  ) async {
    final repository = MemoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: appTheme(Brightness.light),
          home: const ReviewScreen(),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('merchant')), 'Test Shop');
    await tester.enterText(find.byKey(const Key('amount')), '150000');
    await tester.ensureVisible(find.byKey(const Key('save')));
    await tester.tap(find.byKey(const Key('save')));
    await tester.pump();
    expect(repository.records, isEmpty);
    expect(
      find.text('Chọn ngày và xác nhận đã kiểm tra thông tin.'),
      findsOneWidget,
    );
  });
  testWidgets('Malformed or negative totals are rejected before persistence', (
    tester,
  ) async {
    final repository = MemoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: ReviewScreen(
            existing: Expense(
              id: 1,
              merchant: 'Shop',
              amount: 10000,
              date: DateTime(2026, 10, 9),
              category: ExpenseCategory.food,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('amount')), '-100');
    await tester.ensureVisible(find.byKey(const Key('confirm')));
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.ensureVisible(find.byKey(const Key('save')));
    await tester.tap(find.byKey(const Key('save')));
    await tester.pump();
    expect(repository.records, isEmpty);
    expect(find.text('Nhập số tiền từ 1 đến 1.000.000.000 đ'), findsOneWidget);
  });
}
