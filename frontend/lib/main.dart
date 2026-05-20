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
  const BucalScanAiApp({super.key});

  @override
  State<BucalScanAiApp> createState() => _BucalScanAiAppState();
}

class _BucalScanAiAppState extends State<BucalScanAiApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authViewModel = context.read<AuthViewModel>();
    final isLoggedIn = await authViewModel.tryAutoLogin();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isAuthenticated = isLoggedIn;
      });
    }
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

      home: _isLoading
          ? const _SplashScreen()
          : _isAuthenticated
              ? const HomeView()
              : const LoginView(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services,
                color: AppColors.onPrimaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
