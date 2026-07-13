import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/validators/auth_validators.dart';
import 'package:bucalscan_ai/core/widgets/app_text_field.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/register_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/workspace_gate_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_view.dart';

class LoginView extends ConsumerStatefulWidget {
  final VoidCallback? onAuthenticated;

  const LoginView({super.key, this.onAuthenticated});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  String _formatLoginError(String error) {
    final cleaned = error.replaceFirst('Exception: ', '').trim();
    final normalized = cleaned.toLowerCase();

    if (normalized.contains('invalid credentials')) {
      return 'Usuario y clave incorrectos';
    }

    if (normalized.contains('invalid or expired token') ||
        normalized.contains('not authenticated') ||
        normalized.contains('tu sesión expiró')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }

    if (normalized.contains('no se pudo conectar') ||
        normalized.contains('no respondio a tiempo')) {
      return 'No se pudo conectar con el servidor. Intente nuevamente en unos segundos.';
    }

    if (cleaned.isEmpty) {
      return 'No se pudo iniciar sesión. Intente nuevamente.';
    }

    return cleaned;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authViewModelProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Inicio de sesión exitoso.')),
              ],
            ),
            backgroundColor: AppColors.benignText,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 650),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } else {
          ref.read(clinicalControllerProvider.notifier).clearSession();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkspaceGateView(child: HomeView()),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 0,
                color: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.surfaceVariant,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.surfaceVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: AppColors.onPrimaryContainer,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'BucalScan AI',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Acceso seguro para profesionales médicos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              label: 'Correo electrónico',
                              hint: 'dr.smith@hospital.org',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: AuthValidators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: !_showPassword,
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: AuthValidators.validateLoginPassword,
                            ),
                            const SizedBox(height: 16),
                            if (authViewModel.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _formatLoginError(
                                            authViewModel.error!,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.onErrorContainer,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ElevatedButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: authViewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.login, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.surfaceVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          const Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterView(
                                    onAuthenticated: widget.onAuthenticated,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Registrar centro médico',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
