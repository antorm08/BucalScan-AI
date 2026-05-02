import 'package:flutter_test/flutter_test.dart';
import 'package:oral_lesion_detector/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const OralLesionDetectorApp());
    expect(find.text('Oral Lesion Detector'), findsOneWidget);
  });
}
