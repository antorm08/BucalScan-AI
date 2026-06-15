import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/data/services/auth_interceptor.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
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
import 'package:bucalscan_ai/core/startup/startup_view.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';

void main() {
  final authStorage = AuthStorageService();
  final authInterceptor = AuthInterceptor(authStorage);
  final apiService = ApiService(interceptors: [authInterceptor]);
  final authRemoteDataSource = AuthRemoteDataSource(apiService);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource, authStorage);
  final hasSessionTokenUseCase = HasSessionTokenUseCase(authRepository);
  final getCachedUserUseCase = GetCachedUserUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);
  final predictionRemoteDataSource = PredictionRemoteDataSource(apiService);
  final predictionRepository = PredictionRepositoryImpl(predictionRemoteDataSource);
  final predictImageUseCase = PredictImageUseCase(predictionRepository);
  final historyRemoteDataSource = HistoryRemoteDataSource(apiService);
  final historyRepository = HistoryRepositoryImpl(historyRemoteDataSource);
  final getHistoryUseCase = GetHistoryUseCase(historyRepository);
  final dashboardRemoteDataSource = DashboardRemoteDataSource(apiService);
  final dashboardRepository = DashboardRepositoryImpl(dashboardRemoteDataSource);
  final getTodaySummaryUseCase = GetTodaySummaryUseCase(dashboardRepository);
  final profileRemoteDataSource = ProfileRemoteDataSource(apiService);
  final profileRepository = ProfileRepositoryImpl(profileRemoteDataSource);
  final updateProfileUseCase = UpdateProfileUseCase(profileRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepository,
            updateProfileUseCase,
            hasSessionTokenUseCase,
            getCachedUserUseCase,
            logoutUseCase,
          ),
        ),
        ChangeNotifierProvider(create: (_) => PredictionViewModel(predictImageUseCase)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(getHistoryUseCase)),
        ChangeNotifierProvider(create: (_) => SummaryViewModel(getTodaySummaryUseCase)),
      ],
      child: BucalScanAiApp(apiService: apiService),
    ),
  );
}

class BucalScanAiApp extends StatefulWidget {
  final ApiService apiService;
  final bool skipStartupWakeup;

  const BucalScanAiApp({
    super.key,
    required this.apiService,
    this.skipStartupWakeup = false,
  });

  @override
  State<BucalScanAiApp> createState() => _BucalScanAiAppState();
}

class _BucalScanAiAppState extends State<BucalScanAiApp> {
  bool _isReadyToEnter = false;
  bool _isAuthenticated = false;
  bool _wasAuthenticated = false;
  StreamSubscription<void>? _sessionSub;

  @override
  void initState() {
    super.initState();
    if (widget.skipStartupWakeup) {
      _isReadyToEnter = true;
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _enterApp() async {
    if (_isReadyToEnter) {
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final isLoggedIn = await authViewModel.tryAutoLogin();

    if (!mounted) {
      return;
    }

    setState(() {
      _isReadyToEnter = true;
      _isAuthenticated = isLoggedIn;
      _wasAuthenticated = isLoggedIn;
    });

    if (isLoggedIn) {
      _subscribeToSessionExpiry();
    }
  }

  void _subscribeToSessionExpiry() {
    _sessionSub?.cancel();
    _sessionSub = SessionEvents().onSessionExpired.listen((_) {
      if (!_wasAuthenticated) {
        return;
      }
      _wasAuthenticated = false;
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return riverpod.ProviderScope(
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),

        home: !_isReadyToEnter
            ? StartupView(apiService: widget.apiService, onReady: _enterApp)
            : _isAuthenticated
                ? const HomeView()
                : const LoginView(),
      ),
    );
  }
}
