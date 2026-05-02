import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oral_lesion_detector/providers/prediction_provider.dart';
import 'package:oral_lesion_detector/screens/login_screen.dart';
import 'package:oral_lesion_detector/utils/constants.dart';

void main() {
  runApp(const OralLesionDetectorApp());
}

class OralLesionDetectorApp extends StatelessWidget {
  const OralLesionDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
