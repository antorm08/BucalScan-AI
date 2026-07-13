import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/session/session_events.dart';
import 'package:bucalscan_ai/core/session/user_sensitive_state.dart';
import 'package:bucalscan_ai/core/startup/startup_view.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_users_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/workspace_gate_view.dart';

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
      ref.resetUserSensitiveState();
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

    ref.resetUserSensitiveState();
    setState(() {
      _isReadyToEnter = true;
      _isAuthenticated = true;
      _wasAuthenticated = true;
    });
    _subscribeToSessionExpiry();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => _authenticatedHome()),
      (route) => false,
    );
  }

  Widget _authenticatedHome() {
    final user = ref.read(authViewModelProvider).currentUser;
    if (user?.isAdmin == true) {
      return AdminUsersView(onLoggedOut: _markLoggedOut);
    }
    return WorkspaceGateView(
      onLoggedOut: _markLoggedOut,
      child: const HomeView(),
    );
  }

  void _markLoggedOut() {
    if (!mounted) return;
    ref.resetUserSensitiveState();
    _wasAuthenticated = false;
    setState(() => _isAuthenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authViewModelProvider).currentUser;

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
          ? currentUser?.isAdmin == true
                ? AdminUsersView(onLoggedOut: _markLoggedOut)
                : WorkspaceGateView(
                    onLoggedOut: _markLoggedOut,
                    child: const HomeView(),
                  )
          : LoginView(onAuthenticated: _markAuthenticated),
    );
  }
}
