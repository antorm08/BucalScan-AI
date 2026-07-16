import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/presentation/priority_copy.dart';
import 'package:flutter/material.dart';

class ClinicalPriorityResultCard extends StatelessWidget {
  final ClinicalPriorityResult priority;

  const ClinicalPriorityResultCard({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final status = localizedPriorityStatus(priority.priorityCode);
    final colors = _colors(status.tone);
    final emergency = priority.priorityCode == 'emergency';
    final academic = priority.rulesetVersion.endsWith('-draft');
    final reasons = localizedPriorityReasons(priority);

    return Semantics(
      container: true,
      label: 'Semáforo orientativo de atención: ${status.label}',
      child: Card(
        key: const Key('priorityResultCard'),
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.foreground.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semáforo orientativo de atención',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                key: Key('prioritySignal-${priority.priorityCode}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.foreground.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(status.icon, color: colors.foreground, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final reason in reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $reason'),
                ),
              if (emergency)
                const Text(
                  'Busque atención de emergencia según el contexto. Esta herramienta no reemplaza los servicios de emergencia ni el juicio profesional.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                )
              else
                const Text(
                  'Orienta el tiempo de atención usando el checklist. No usa el porcentaje del modelo y no establece diagnóstico.',
                ),
              if (academic) ...[
                const SizedBox(height: 8),
                const Text(
                  'Modo académico: reglas no validadas para triaje clínico.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Ruleset ${priority.rulesetVersion} · motor ${priority.engineVersion}${priority.evaluatedAt == null ? '' : ' · resultado guardado'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({Color background, Color foreground}) _colors(StatusTone tone) =>
    switch (tone) {
      StatusTone.success => (
        background: AppColors.benignBg,
        foreground: AppColors.benignText,
      ),
      StatusTone.info => (
        background: const Color(0xFFFFF4CC),
        foreground: const Color(0xFF755500),
      ),
      StatusTone.warning => (
        background: const Color(0xFFFFE2C2),
        foreground: const Color(0xFF8A3F00),
      ),
      StatusTone.danger => (
        background: AppColors.errorContainer,
        foreground: AppColors.error,
      ),
      StatusTone.neutral => (
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.onSurfaceVariant,
      ),
    };
