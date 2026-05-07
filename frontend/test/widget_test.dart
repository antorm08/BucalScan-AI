import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:oral_lesion_detector/main.dart';
import 'package:oral_lesion_detector/data/repositories/auth_repository.dart';
import 'package:oral_lesion_detector/data/repositories/history_repository.dart';
import 'package:oral_lesion_detector/data/repositories/prediction_repository.dart';
import 'package:oral_lesion_detector/data/services/api_service.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/auth_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/history_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/profile_viewmodel.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepository(apiService))),
          ChangeNotifierProvider(
            create: (_) => PredictionViewModel(PredictionRepository(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => HistoryViewModel(HistoryRepository(apiService)),
          ),
          ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ],
        child: const DeepOralDxApp(),
      ),
    );

    expect(find.text('DeepOral-DX'), findsOneWidget);
  });
}
