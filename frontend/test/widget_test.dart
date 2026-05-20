import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/main.dart';
import 'package:bucalscan_ai/data/repositories/auth_repository.dart';
import 'package:bucalscan_ai/data/repositories/history_repository.dart';
import 'package:bucalscan_ai/data/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/profile_viewmodel.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final apiService = ApiService();
    final authStorage = AuthStorageService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(AuthRepository(apiService), authStorage),
          ),
          ChangeNotifierProvider(
            create: (_) => PredictionViewModel(PredictionRepository(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => HistoryViewModel(HistoryRepository(apiService)),
          ),
          ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ],
        child: const BucalScanAiApp(),
      ),
    );

    expect(find.text('BucalScan AI'), findsOneWidget);
  });
}
