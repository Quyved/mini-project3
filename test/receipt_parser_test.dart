import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_lens/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();
  test(
    'Vietnamese total overrides cash, change, discount, subtotal and phone',
    () {
      final receipt = parser.parse('''WINMART
Hotline 19001234
Ngày 09/10/2026
Tạm tính 160.000 đ
Giảm giá 10.000 đ
TỔNG CỘNG 150.000 đ
Tiền khách đưa 200.000 đ
Tiền thối 50.000 đ''');
      expect(receipt.amount, 150000);
      expect(receipt.merchant, 'WINMART');
      expect(receipt.date, DateTime(2026, 10, 9));
    },
  );
  test('English total and comma grouping', () {
    expect(
      parser
          .parse(
            'STORE\nSubtotal 140,000 VND\nTax 10,000 VND\nGrand Total 150,000 VND\nCash 200,000 VND',
          )
          .amount,
      150000,
    );
  });
  test('Split total label is supported', () {
    expect(parser.parse('SHOP\nThanh toán\n150 000 VND').amount, 150000);
  });
  test('Invalid date must not silently overflow to next month', () {
    final receipt = parser.parse('SHOP\n31/02/2026\nTOTAL 45000');
    expect(receipt.date, isNull);
    expect(receipt.warnings, isNotEmpty);
  });
  test('Phone and invoice ID alone cannot become the total', () {
    expect(
      parser.parse('SHOP\nTel 0901234567\nInvoice 12345678').amount,
      isNull,
    );
  });
  test('Ambiguous item amount is flagged', () {
    expect(
      parser.parse('SHOP\nMilk 45000').warnings.join(),
      contains('dòng tổng tiền'),
    );
  });
  test('Missing text yields editable empty fields', () {
    final r = parser.parse('');
    expect(r.amount, isNull);
    expect(r.date, isNull);
    expect(r.merchant, isEmpty);
  });
  test(
    'VND validation rejects zero, decimals, negatives and absurd totals',
    () {
      for (final s in ['0', '-100', '15.50', '10,25', '1000000001', 'abc']) {
        expect(ReceiptParser.parseVnd(s), isNull, reason: s);
      }
      for (final s in ['150000', '150,000 VND', '150.000 đ', '150 000']) {
        expect(ReceiptParser.parseVnd(s), 150000);
      }
    },
  );
}
