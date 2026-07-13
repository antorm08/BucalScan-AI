import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';

class StartupView extends StatefulWidget {
  final ApiService apiService;
  final Future<void> Function() onReady;

  const StartupView({
    super.key,
    required this.apiService,
    required this.onReady,
  });

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  static const Duration _retryDelay = Duration(seconds: 2);
  static const int _automaticAttempts = 2;

  bool _isLoading = true;
  String? _error;
  String _statusMessage = 'Conectando con el servidor...';
  int _currentAttempt = 0;
  bool _hasContinued = false;
  bool _isServiceReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_wakeBackend());
  }

  Future<void> _wakeBackend() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentAttempt = 0;
      _statusMessage = 'Conectando con el servidor...';
      _hasContinued = false;
      _isServiceReady = false;
    });

    while (mounted) {
      if (_hasContinued) {
        return;
      }

      final attempt = _currentAttempt + 1;

      if (!mounted) {
        return;
      }

      setState(() {
        _currentAttempt = attempt;
        _statusMessage = attempt == 1
            ? 'Conectando con el servidor...'
            : 'Preparando el servicio de analisis...';
      });

      try {
        await widget.apiService.pingReadiness();
        if (!mounted) {
          return;
        }

        setState(() {
          _isServiceReady = true;
          _error = null;
          _statusMessage = 'Servicio listo';
        });

        await Future<void>.delayed(const Duration(milliseconds: 1200));
        if (!mounted) {
          return;
        }

        _hasContinued = true;
        await widget.onReady();
        return;
      } catch (e) {
        if (!mounted) {
          return;
        }

        setState(() {
          _error = 'No se pudo conectar con el servicio.';
          _statusMessage = attempt >= _automaticAttempts
              ? 'Servicio no disponible'
              : 'Preparando el servicio...';
        });

        if (attempt >= _automaticAttempts) {
          setState(() => _isLoading = false);
          return;
        }

        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  void _continueToLogin() {
    _hasContinued = true;
    unawaited(widget.onReady());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.surfaceVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'BucalScan AI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preparando el servicio de analisis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoading) ...[
                        if (_isServiceReady)
                          const Icon(
                            Icons.check_circle,
                            size: 42,
                            color: AppColors.benignText,
                          )
                        else
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        const SizedBox(height: 18),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (!_isServiceReady) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Puedes continuar mientras Render termina de iniciar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (_currentAttempt > 1) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Reintento $_currentAttempt de $_automaticAttempts',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _continueToLogin,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continuar sin esperar'),
                          ),
                        ],
                      ] else ...[
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error ??
                              'No se pudo establecer conexion con el servidor.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _wakeBackend,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _continueToLogin,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continuar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
