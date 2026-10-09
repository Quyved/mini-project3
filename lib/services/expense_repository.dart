import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({this.databasePath, this.factory});
  final String? databasePath;
  final DatabaseFactory? factory;
  Future<Database>? _opening;
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final f = factory ?? databaseFactory;
    final path =
        databasePath ?? p.join(await f.getDatabasesPath(), 'receipt_lens.db');
    return f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          merchant TEXT NOT NULL CHECK(length(trim(merchant)) > 0),
          amount INTEGER NOT NULL CHECK(amount > 0 AND amount <= 1000000000),
          date TEXT NOT NULL, category TEXT NOT NULL,
          image_path TEXT, thumbnail_path TEXT, raw_text TEXT NOT NULL,
          note TEXT NOT NULL
        )''');
          await db.execute('CREATE INDEX expenses_date ON expenses(date)');
        },
      ),
    );
  }

  Future<List<Expense>> list() async => (await (await database).query(
    'expenses',
    orderBy: 'date DESC, id DESC',
  )).map(Expense.fromMap).toList();
  Future<void> save(Expense expense) async {
    final db = await database;
    if (expense.id == null) {
      await db.insert('expenses', expense.toMap());
    } else {
      final changed = await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      if (changed != 1) {
        throw StateError('Giao dịch không còn tồn tại.');
      }
    }
  }

  Future<void> delete(Expense expense) async {
    await (await database).delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    // Database deletion succeeds first; missing files never block CRUD.
    for (final path in [expense.imagePath, expense.thumbnailPath]) {
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } on FileSystemException {
          /* Best-effort cache cleanup. */
        }
      }
    }
  }

  Future<void> close() async {
    if (_opening != null) {
      await (await _opening!).close();
      _opening = null;
    }
  }
}
