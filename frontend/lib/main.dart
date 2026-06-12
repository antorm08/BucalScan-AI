import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/repositories/auth_repository.dart';
import 'package:bucalscan_ai/data/repositories/history_repository.dart';
import 'package:bucalscan_ai/data/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/data/repositories/summary_repository.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/data/services/auth_interceptor.dart';
import 'package:bucalscan_ai/data/services/auth_storage_service.dart';
import 'package:bucalscan_ai/data/services/session_events.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/presentation/views/startup/startup_view.dart';
import 'package:bucalscan_ai/presentation/views/auth/login_view.dart';
import 'package:bucalscan_ai/presentation/views/home/home_view.dart';

void main() {
  final authStorage = AuthStorageService();
  final authInterceptor = AuthInterceptor(authStorage);
  final apiService = ApiService(interceptors: [authInterceptor]);
  final authRepository = AuthRepository(apiService);
  final predictionRepository = PredictionRepository(apiService);
  final historyRepository = HistoryRepository(apiService);
  final summaryRepository = SummaryRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository, authStorage),
        ),
        ChangeNotifierProvider(create: (_) => PredictionViewModel(predictionRepository)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(historyRepository)),
        ChangeNotifierProvider(create: (_) => SummaryViewModel(summaryRepository)),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
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
    return MaterialApp(
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
    );
  }
}
