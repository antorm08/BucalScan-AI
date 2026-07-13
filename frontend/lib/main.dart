import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/constants/app_constants.dart';
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
  bool _isReadyToEnter = false;

  @override
  void initState() {
    super.initState();
    if (widget.skipStartupWakeup) {
      _isReadyToEnter = true;
    }
  }

  Future<void> _enterApp() async {
    if (_isReadyToEnter) {
      return;
    }

    final authViewModel = ref.read(authViewModelProvider.notifier);
    await authViewModel.tryAutoLogin();

    if (!mounted) {
      return;
    }

    setState(() {
      _isReadyToEnter = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    return MaterialApp(
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

      home: KeyedSubtree(
        key: ValueKey(auth.generation),
        child: !_isReadyToEnter
            ? StartupView(
                apiService: ref.read(authApiServiceProvider),
                onReady: _enterApp,
              )
            : auth.currentUser == null
            ? const LoginView()
            : auth.currentUser!.isAdmin
            ? const AdminUsersView()
            : const WorkspaceGateView(child: HomeView()),
      ),
    );
  }
}
