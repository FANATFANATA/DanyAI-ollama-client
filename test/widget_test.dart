import "package:flutter_test/flutter_test.dart";
import "package:danyai/main.dart";
import "package:danyai/services/services.dart";

void main() {
  testWidgets("App load test", (WidgetTester tester) async {
    final settings = Settings();
    await tester.pumpWidget(DanyAIApp(settings: settings));
    expect(find.byType(DanyAIApp), findsOneWidget);
  });
}
