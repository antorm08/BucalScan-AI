import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';

class HomeTabView extends ConsumerStatefulWidget {
  final VoidCallback onStartCapture;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenPatients;

  const HomeTabView({
    super.key,
    required this.onStartCapture,
    required this.onOpenHistory,
    required this.onOpenPatients,
  });

  @override
  ConsumerState<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends ConsumerState<HomeTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(summaryViewModelProvider.notifier).fetchTodaySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividad del centro',
                        style: TextStyle(
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.01,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Continúe el seguimiento de pacientes o registre una nueva evaluación.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompact) ...[
                  _PrimaryActionCard(
                    icon: Icons.add_a_photo,
                    title: 'Nuevo análisis',
                    subtitle:
                        'Paciente, lesión, imagen y evaluación actual en un flujo guiado',
                    onTap: widget.onStartCapture,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionCard(
                    icon: Icons.history_edu_outlined,
                    title: 'Últimos análisis',
                    subtitle:
                        'Consulte análisis previos, pacientes registrados y resultados recientes',
                    onTap: widget.onOpenHistory,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionCard(
                    icon: Icons.people_outline,
                    title: 'Seguimiento de pacientes',
                    subtitle:
                        'Consulte lesiones y evaluaciones longitudinales del centro',
                    onTap: widget.onOpenPatients,
                  ),
                  const SizedBox(height: 12),
                  const _SummaryCard(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _PrimaryActionCard(
                              icon: Icons.add_a_photo,
                              title: 'Nuevo análisis',
                              subtitle:
                                  'Paciente, lesión, imagen y evaluación actual en un flujo guiado',
                              onTap: widget.onStartCapture,
                            ),
                            const SizedBox(height: 12),
                            _SecondaryActionCard(
                              icon: Icons.history_edu_outlined,
                              title: 'Últimos análisis',
                              subtitle:
                                  'Consulte análisis previos, pacientes registrados y resultados recientes',
                              onTap: widget.onOpenHistory,
                            ),
                            const SizedBox(height: 12),
                            _SecondaryActionCard(
                              icon: Icons.people_outline,
                              title: 'Seguimiento de pacientes',
                              subtitle:
                                  'Consulte lesiones y evaluaciones longitudinales',
                              onTap: widget.onOpenPatients,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(flex: 1, child: _SummaryCard()),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.primaryFixed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryFixed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryContainer,
                      size: 32,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.outline),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  String _formatLatestAnalysis(DateTime? date) {
    if (date == null) {
      return 'Sin análisis registrados hoy';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Último análisis: $day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(summaryViewModelProvider);
    if (viewModel.isLoading) {
      return Card(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Cargando actividad del centro...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (viewModel.error != null) {
      return Card(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SummaryHeader(),
              const SizedBox(height: 16),
              const Icon(
                Icons.error_outline,
                color: AppColors.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.error!.replaceFirst('Exception: ', ''),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(summaryViewModelProvider.notifier)
                      .fetchTodaySummary();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = viewModel.summary;
    final total = summary?.total ?? 0;
    final latestAnalysisLabel = _formatLatestAnalysis(
      summary?.latestAnalysisAt,
    );

    if (summary == null || viewModel.isEmpty) {
      return Card(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryHeader(),
                SizedBox(height: 32),
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 28,
                ),
                SizedBox(height: 12),
                Text(
                  'Aún no hay análisis registrados hoy.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceContainerHighest),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryHeader(
              onRefresh: () {
                ref.read(summaryViewModelProvider.notifier).fetchTodaySummary();
              },
            ),
            const SizedBox(height: 16),
            Text(
              '$total',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const Text(
              'análisis procesados hoy',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              latestAnalysisLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Consulte Historial para revisar cada salida del modelo con su contexto clínico.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final VoidCallback? onRefresh;

  const _SummaryHeader({this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMEN DE HOY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Actividad guardada en el centro activo',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton.filledTonal(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Actualizar resumen',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
