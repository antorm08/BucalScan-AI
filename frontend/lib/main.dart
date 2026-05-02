import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oral_lesion_detector/core/constants/app_constants.dart';
import 'package:oral_lesion_detector/core/theme/app_colors.dart';
import 'package:oral_lesion_detector/data/repositories/auth_repository.dart';
import 'package:oral_lesion_detector/data/repositories/history_repository.dart';
import 'package:oral_lesion_detector/data/repositories/prediction_repository.dart';
import 'package:oral_lesion_detector/data/services/api_service.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/auth_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/history_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/viewmodels/profile_viewmodel.dart';
import 'package:oral_lesion_detector/presentation/views/auth/login_view.dart';

void main() {
  final apiService = ApiService();
  final authRepository = AuthRepository(apiService);
  final predictionRepository = PredictionRepository(apiService);
  final historyRepository = HistoryRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => PredictionViewModel(predictionRepository)),
        ChangeNotifierProvider(create: (_) => HistoryViewModel(historyRepository)),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const OralScanApp(),
    ),
  );
}

class OralScanApp extends StatelessWidget {
  const OralScanApp({super.key});

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
