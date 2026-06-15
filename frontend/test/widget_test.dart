import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BucalScanAiApp(skipStartupWakeup: true)),
    );

    expect(find.text('BucalScan AI'), findsOneWidget);
  });
}
