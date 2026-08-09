import 'package:flutter_test/flutter_test.dart';

import 'package:transia_mobile/app/app.dart';

void main() {
  testWidgets('Transia démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const TransiaApp());

    expect(find.text('Transia'), findsOneWidget);
  });
}
