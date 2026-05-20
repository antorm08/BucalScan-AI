import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/repositories/auth_repository.dart';
import 'package:bucalscan_ai/data/repositories/history_repository.dart';
import 'package:bucalscan_ai/data/repositories/prediction_repository.dart';
import 'package:bucalscan_ai/data/repositories/summary_repository.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/presentation/views/auth/login_view.dart';

void main() {
  final apiService = ApiService();
  final authRepository = AuthRepository(apiService);
  final predictionRepository = PredictionRepository(apiService);
  final historyRepository = HistoryRepository(apiService);
  final summaryRepository = SummaryRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => PredictionViewModel(predictionRepository)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(historyRepository)),
        ChangeNotifierProvider(create: (_) => SummaryViewModel(summaryRepository)),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const BucalScanAiApp(),
    ),
  );
}

class BucalScanAiApp extends StatelessWidget {
  const BucalScanAiApp({super.key});

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
      home: const LoginView(),
    );
  }
}
