class AmountCandidate {
  const AmountCandidate(this.amount, this.line, this.score);
  final int amount;
  final String line;
  final int score;
}

class ParsedReceipt {
  const ParsedReceipt({
    required this.merchant,
    this.amount,
    this.date,
    required this.candidates,
    required this.warnings,
  });
  final String merchant;
  final int? amount;
  final DateTime? date;
  final List<AmountCandidate> candidates;
  final List<String> warnings;
}

class ReceiptParser {
  static String normalize(String value) {
    var result = value.toLowerCase();
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    for (final entry in groups.entries) {
      for (final char in entry.value.split('')) {
        result = result.replaceAll(char, entry.key);
      }
    }
    return result;
  }

  // VND only: grouping separators accepted; decimal currencies rejected.
  static int? parseVnd(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'vnd|vnđ|đ|₫', caseSensitive: false), '')
        .trim();
    if (!RegExp(r'^(?:\d{1,3}(?:[., ]\d{3})+|\d+)$').hasMatch(cleaned)) {
      return null;
    }
    final n = int.tryParse(cleaned.replaceAll(RegExp(r'[., ]'), ''));
    return n != null && n > 0 && n <= 1000000000 ? n : null;
  }

  ParsedReceipt parse(String raw) {
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final candidates = <AmountCandidate>[];
    final amounts = RegExp(
      r'(?<![\d/:-])(?:\d{1,3}(?:[., ]\d{3})+|\d{4,})(?![\d/:-])(?:\s*(?:VND|VNĐ|đ|₫))?',
      caseSensitive: false,
    );
    final total = RegExp(
      r'\b(?:grand total|total due|amount due|thanh toan|tong cong|tong tien|total)\b',
    );
    final excluded = RegExp(
      r'\b(?:subtotal|sub total|tam tinh|tien khach|khach dua|tien thoi|change|cash|tender|vat|tax|giam gia|discount)\b',
    );
    final metadata = RegExp(
      r'\b(?:tel|phone|hotline|mst|tax id|ma so thue|invoice|hoa don|so hd|account|tai khoan)\b',
    );
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final norm = normalize(line);
      if (excluded.hasMatch(norm) ||
          metadata.hasMatch(norm) ||
          RegExp(r'\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}').hasMatch(line)) {
        continue;
      }
      final matches = amounts.allMatches(line).toList();
      if (matches.isEmpty) {
        continue;
      }
      final amount = parseVnd(matches.last.group(0)!);
      if (amount == null) {
        continue;
      }
      var score = total.hasMatch(norm) ? 100 : 10;
      if (i > 0 &&
          total.hasMatch(normalize(lines[i - 1])) &&
          !excluded.hasMatch(normalize(lines[i - 1]))) {
        score = 90;
      }
      if (RegExp(r'vnd|vnđ|đ|₫', caseSensitive: false).hasMatch(line)) {
        score += 15;
      }
      candidates.add(AmountCandidate(amount, line, score));
    }
    candidates.sort((a, b) {
      final s = b.score.compareTo(a.score);
      return s != 0 ? s : b.amount.compareTo(a.amount);
    });
    DateTime? date;
    for (final m in RegExp(
      r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b',
    ).allMatches(raw)) {
      final d = int.parse(m[1]!),
          month = int.parse(m[2]!),
          y = int.parse(m[3]!);
      final v = DateTime(y, month, d);
      if (y >= 2000 && y <= 2100 && v.day == d && v.month == month) {
        date = v;
        break;
      }
    }
    final names = lines.take(8).where((s) {
      final n = normalize(s);
      return RegExp(r'[a-z]').hasMatch(n) &&
          !metadata.hasMatch(n) &&
          !RegExp(
            r'\b(?:receipt|hoa don|ngay|date|dia chi|address|thank|cam on|cashier)\b',
          ).hasMatch(n) &&
          !RegExp(r'\d{3,}').hasMatch(n) &&
          !total.hasMatch(n);
    }).toList();
    return ParsedReceipt(
      merchant: names.isEmpty ? '' : names.first,
      amount: candidates.isEmpty ? null : candidates.first.amount,
      date: date,
      candidates: candidates,
      warnings: [
        if (candidates.isEmpty)
          'Không tìm thấy số tiền. Vui lòng nhập thủ công.',
        if (candidates.isNotEmpty && candidates.first.score < 90)
          'Chưa tìm được dòng tổng tiền rõ ràng; hãy đối chiếu ảnh.',
        if (date == null)
          'Không tìm được ngày hợp lệ. Hãy chọn ngày trên hóa đơn.',
        if (names.isEmpty) 'Chưa nhận diện được tên cửa hàng.',
      ],
    );
  }
}
