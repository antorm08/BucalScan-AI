import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/presentation/views/admin/admin_users_view.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

class HomeTabView extends StatefulWidget {
  final VoidCallback onStartCapture;
  final VoidCallback onOpenHistory;

  const HomeTabView({
    super.key,
    required this.onStartCapture,
    required this.onOpenHistory,
  });

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<SummaryViewModel>().fetchTodaySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(),
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
                        'Panel de análisis clínico',
                        style: TextStyle(
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.01,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Revise el resumen del día e inicie una captura guiada antes de enviar la imagen al modelo.',
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
                    title: 'Iniciar análisis guiado',
                    subtitle:
                        'Seleccione cámara o galería, revise la vista previa y confirme antes de analizar',
                    onTap: widget.onStartCapture,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionCard(
                    icon: Icons.history_edu_outlined,
                    title: 'Revisar historial clínico',
                    subtitle:
                        'Consulte análisis previos, pacientes registrados y resultados recientes',
                    onTap: widget.onOpenHistory,
                  ),
                  const SizedBox(height: 12),
                  const _SummaryCard(),
                  if (currentUser?.isAdmin ?? false) ...[
                    const SizedBox(height: 12),
                    const _AdminEntryCard(),
                  ],
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
                              title: 'Iniciar análisis guiado',
                              subtitle:
                                  'Seleccione cámara o galería, revise la vista previa y confirme antes de analizar',
                              onTap: widget.onStartCapture,
                            ),
                            const SizedBox(height: 12),
                            _SecondaryActionCard(
                              icon: Icons.history_edu_outlined,
                              title: 'Revisar historial clínico',
                              subtitle:
                                  'Consulte análisis previos, pacientes registrados y resultados recientes',
                              onTap: widget.onOpenHistory,
                            ),
                            if (currentUser?.isAdmin ?? false) ...[
                              const SizedBox(height: 12),
                              const _AdminEntryCard(),
                            ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

class _SummaryCard extends StatelessWidget {
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

  double _ratio(int value, int total) {
    if (total <= 0) {
      return 0;
    }

    return (value / total).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SummaryViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return Card(
            color: AppColors.surfaceContainerLowest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.surfaceContainerHighest),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Cargando resumen real del día...',
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
                      context.read<SummaryViewModel>().fetchTodaySummary();
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
        final benign = summary?.benign ?? 0;
        final malignant = summary?.malignant ?? 0;
        final benignRatio = _ratio(benign, total);
        final malignantRatio = _ratio(malignant, total);
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
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                height: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryHeader(),
                    Spacer(),
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
                    Spacer(),
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
                    context.read<SummaryViewModel>().fetchTodaySummary();
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
                _SummaryDistributionBar(
                  benignRatio: benignRatio,
                  malignantRatio: malignantRatio,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryMetricCard(
                        label: 'Benignos',
                        value: benign,
                        ratio: benignRatio,
                        color: AppColors.benignText,
                        backgroundColor: AppColors.benignBg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryMetricCard(
                        label: 'Malignos',
                        value: malignant,
                        ratio: malignantRatio,
                        color: AppColors.error,
                        backgroundColor: AppColors.errorContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                'Datos desde /summary/today',
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

class _SummaryDistributionBar extends StatelessWidget {
  final double benignRatio;
  final double malignantRatio;

  const _SummaryDistributionBar({
    required this.benignRatio,
    required this.malignantRatio,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (benignRatio > 0)
              Expanded(
                flex: (benignRatio * 1000).round().clamp(1, 1000),
                child: Container(color: AppColors.benignText),
              ),
            if (malignantRatio > 0)
              Expanded(
                flex: (malignantRatio * 1000).round().clamp(1, 1000),
                child: Container(color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String label;
  final int value;
  final double ratio;
  final Color color;
  final Color backgroundColor;

  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(ratio * 100).toStringAsFixed(0)}% del día',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminEntryCard extends StatelessWidget {
  const _AdminEntryCard();

  void _openAdminUsers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUsersView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAdminUsers(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        ),
        child: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión administrativa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Revise usuarios registrados y suspenda o reactive accesos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
