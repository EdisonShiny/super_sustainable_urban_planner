import 'package:flutter_test/flutter_test.dart';

import 'package:super_sustainable_urban_planner/app.dart';

void main() {
  testWidgets('Login screen renders welcome headline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
