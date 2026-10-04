import 'package:flutter_test/flutter_test.dart';
import 'package:dream_logs/app.dart';

void main() {
  testWidgets('Dream Logs shell renders', (tester) async {
    await tester.pumpWidget(const DreamLogsApp());
    expect(find.text('Dream Logs'), findsOneWidget);
  });
}
