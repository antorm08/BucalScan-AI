import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/main.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bucalscan_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/has_session_token_usecase.dart';
import 'package:bucalscan_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:bucalscan_ai/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bucalscan_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:bucalscan_ai/features/dashboard/domain/usecases/get_today_summary_usecase.dart';
import 'package:bucalscan_ai/features/history/data/datasources/history_remote_datasource.dart';
import 'package:bucalscan_ai/features/history/data/repositories/history_repository_impl.dart';
import 'package:bucalscan_ai/features/history/domain/usecases/get_history_usecase.dart';
import 'package:bucalscan_ai/features/prediction/data/datasources/prediction_remote_datasource.dart';
import 'package:bucalscan_ai/features/prediction/data/repositories/prediction_repository_impl.dart';
import 'package:bucalscan_ai/features/prediction/domain/usecases/predict_image_usecase.dart';
import 'package:bucalscan_ai/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:bucalscan_ai/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bucalscan_ai/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    final apiService = ApiService();
    final authStorage = AuthStorageService();
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDataSource(apiService),
      authStorage,
    );
    final dashboardRepository = DashboardRepositoryImpl(
      DashboardRemoteDataSource(apiService),
    );
    final historyRepository = HistoryRepositoryImpl(
      HistoryRemoteDataSource(apiService),
    );
    final predictionRepository = PredictionRepositoryImpl(
      PredictionRemoteDataSource(apiService),
    );
    final profileRepository = ProfileRepositoryImpl(
      ProfileRemoteDataSource(apiService),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(
              authRepository,
              UpdateProfileUseCase(profileRepository),
              HasSessionTokenUseCase(authRepository),
              GetCachedUserUseCase(authRepository),
              LogoutUseCase(authRepository),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PredictionViewModel(
              PredictImageUseCase(predictionRepository),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => HistoryViewModel(GetHistoryUseCase(historyRepository)),
          ),
          ChangeNotifierProvider(
            create: (_) => SummaryViewModel(
              GetTodaySummaryUseCase(dashboardRepository),
            ),
          ),
        ],
        child: BucalScanAiApp(apiService: apiService, skipStartupWakeup: true),
      ),
    );

    expect(find.text('BucalScan AI'), findsOneWidget);
  });
}
