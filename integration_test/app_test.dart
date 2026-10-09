import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:receipt_lens/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Manual review saves one expense and updates the history', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhập thủ công'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('merchant')),
      'Integration Shop',
    );
    await tester.enterText(find.byKey(const Key('amount')), '150000');
    await tester.tap(find.byKey(const Key('date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('confirm')));
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save')));
    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();
    expect(find.text('Integration Shop'), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
