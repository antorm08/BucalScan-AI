import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/dashboard/di/dashboard_providers.dart';
import 'package:bucalscan_ai/features/history/di/history_providers.dart';
import 'package:bucalscan_ai/features/prediction/di/prediction_providers.dart';
import 'package:bucalscan_ai/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/test_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts at login without backend access', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          dashboardRepositoryProvider.overrideWithValue(FakeDashboardRepository()),
          historyRepositoryProvider.overrideWithValue(FakeHistoryRepository()),
          predictionRepositoryProvider.overrideWithValue(FakePredictionRepository()),
        ],
        child: const BucalScanAiApp(skipStartupWakeup: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BucalScan AI'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
