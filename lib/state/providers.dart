import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../services/expense_repository.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Preferences not initialized'),
);
final repositoryProvider = Provider<ExpenseRepository>((ref) {
  final repo = ExpenseRepository();
  ref.onDispose(repo.close);
  return repo;
});
final expensesProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() => ref.watch(repositoryProvider).list();
  Future<void> refresh() async {
    state = AsyncData(await ref.read(repositoryProvider).list());
  }

  Future<void> save(Expense e) async {
    await ref.read(repositoryProvider).save(e);
    await refresh();
  }

  Future<void> delete(Expense e) async {
    await ref.read(repositoryProvider).delete(e);
    await refresh();
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      switch (ref.read(preferencesProvider).getString('theme')) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
  Future<void> toggle(bool isDark) async {
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    await ref.read(preferencesProvider).setString('theme', state.name);
  }
}
