enum ExpenseCategory { food, study, travel, gear, entertainment }

extension CategoryLabel on ExpenseCategory {
  String get label =>
      ['Ăn uống', 'Học tập', 'Di chuyển', 'Đồ dùng', 'Giải trí'][index];
}

class Expense {
  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.thumbnailPath,
    this.rawText = '',
    this.note = '',
  });
  final int? id;
  final String merchant;
  final int amount; // Integer VND avoids floating point money errors.
  final DateTime date;
  final ExpenseCategory category;
  final String? imagePath, thumbnailPath;
  final String rawText, note;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'merchant': merchant,
    'amount': amount,
    'date': DateTime(date.year, date.month, date.day).toIso8601String(),
    'category': category.name,
    'image_path': imagePath,
    'thumbnail_path': thumbnailPath,
    'raw_text': rawText,
    'note': note,
  };
  factory Expense.fromMap(Map<String, Object?> m) => Expense(
    id: m['id'] as int,
    merchant: m['merchant'] as String,
    amount: m['amount'] as int,
    date: DateTime.parse(m['date'] as String),
    category: ExpenseCategory.values.byName(m['category'] as String),
    imagePath: m['image_path'] as String?,
    thumbnailPath: m['thumbnail_path'] as String?,
    rawText: m['raw_text'] as String,
    note: m['note'] as String,
  );
}
