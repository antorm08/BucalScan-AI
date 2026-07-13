import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/core/startup/startup_view.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/workspace_gate_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';

void main() {
  runApp(const ProviderScope(child: BucalScanAiApp()));
}

class BucalScanAiApp extends ConsumerStatefulWidget {
  final bool skipStartupWakeup;

  const BucalScanAiApp({super.key, this.skipStartupWakeup = false});

  @override
  ConsumerState<BucalScanAiApp> createState() => _BucalScanAiAppState();
}

class _BucalScanAiAppState extends ConsumerState<BucalScanAiApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
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

    final authViewModel = ref.read(authViewModelProvider.notifier);
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
      ref.read(clinicalControllerProvider.notifier).clearSession();
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginView(onAuthenticated: _markAuthenticated),
          ),
          (route) => false,
        );
      }
    });
  }

  void _markAuthenticated() {
    if (!mounted) {
      return;
    }

    ref.read(clinicalControllerProvider.notifier).clearSession();
    setState(() {
      _isReadyToEnter = true;
      _isAuthenticated = true;
      _wasAuthenticated = true;
    });
    _subscribeToSessionExpiry();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      home: !_isReadyToEnter
          ? StartupView(
              apiService: ref.read(authApiServiceProvider),
              onReady: _enterApp,
            )
          : _isAuthenticated
          ? const WorkspaceGateView(child: HomeView())
          : LoginView(onAuthenticated: _markAuthenticated),
    );
  }
}
