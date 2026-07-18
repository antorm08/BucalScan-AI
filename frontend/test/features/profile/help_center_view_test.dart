import 'package:bucalscan_ai/features/profile/presentation/views/help_center_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'help search navigates to actual retry guidance and app identity',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: HelpCenterView(),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('helpSearchField')),
        200,
      );
      await tester.enterText(
        find.byKey(const Key('helpSearchField')),
        'reintento',
      );
      await tester.pump();
      expect(find.text('Nueva imagen y reintento'), findsOneWidget);
      expect(find.text('Acceso y centros'), findsNothing);
      await tester.ensureVisible(find.text('Nueva imagen y reintento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva imagen y reintento'));
      await tester.pumpAndSettle();
      expect(find.textContaining('copia inmutable'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('helpSearchField')),
        'soporte',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Soporte'));
      await tester.tap(find.text('Soporte'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1.2.4 (8)'), findsOneWidget);
      expect(find.textContaining('soporte@bucalscan.local'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('help center includes current clinical workflows', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterView()));

    await tester.enterText(
      find.byKey(const Key('helpSearchField')),
      'comparar',
    );
    await tester.pump();
    expect(find.text('Seguimiento, comparación e informes'), findsOneWidget);
    await tester.tap(find.text('Seguimiento, comparación e informes'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('imagen y resultado del modelo'),
      findsOneWidget,
    );
  });
}
