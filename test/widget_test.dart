
import 'package:flutter_test/flutter_test.dart';

import 'package:steps_tracker/main.dart';

void main() {
  testWidgets('Steps Tracker app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StepsTrackerApp());

    expect(find.text('Steps Tracker'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
