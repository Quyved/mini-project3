// ignore_for_file: avoid_print
import 'package:receipt_lens/services/receipt_parser.dart';

void main() {
  var passed = 0;
  void check(String name, bool condition) {
    if (!condition) { throw StateError('FAIL: $name'); }
    passed++; print('PASS: $name');
  }
  final p = ReceiptParser();
  final vn = p.parse('WINMART\nHotline 19001234\nNgày 09/10/2026\nTạm tính 160.000 đ\nGiảm giá 10.000 đ\nTỔNG CỘNG 150.000 đ\nTiền khách đưa 200.000 đ\nTiền thối 50.000 đ');
  check('Vietnamese total versus subtotal/cash/change', vn.amount == 150000);
  check('Merchant and valid date', vn.merchant == 'WINMART' && vn.date == DateTime(2026, 10, 9));
  check('English total and comma groups', p.parse('STORE\nSubtotal 140,000 VND\nTax 10,000 VND\nGrand Total 150,000 VND\nCash 200,000 VND').amount == 150000);
  check('Split total label', p.parse('SHOP\nThanh toán\n150 000 VND').amount == 150000);
  check('Reject impossible calendar date', p.parse('SHOP\n31/02/2026\nTOTAL 45000').date == null);
  check('Exclude phone and invoice', p.parse('SHOP\nTel 0901234567\nInvoice 12345678').amount == null);
  check('Ambiguous total warns', p.parse('SHOP\nMilk 45000').warnings.join().contains('dòng tổng tiền'));
  final empty = p.parse('');
  check('Empty receipt', empty.amount == null && empty.date == null && empty.merchant.isEmpty);
  check('Reject invalid money', ['0','-100','15.50','10,25','1000000001','abc'].every((s) => ReceiptParser.parseVnd(s) == null));
  check('Accept VND formats', ['150000','150,000 VND','150.000 đ','150 000'].every((s) => ReceiptParser.parseVnd(s) == 150000));
  print('RESULT: $passed/10 checks passed');
}
