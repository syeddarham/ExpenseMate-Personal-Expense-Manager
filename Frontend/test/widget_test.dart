import 'package:flutter_test/flutter_test.dart';
import 'package:expense_mate/app.dart';

void main() {
  testWidgets('ExpenseMateApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseMateApp());
    expect(find.text('ExpenseMate'), findsOneWidget);
    expect(find.text('Track smarter. Spend better.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
