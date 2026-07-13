import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:flutter/material.dart';

class HistoryCard extends StatelessWidget {
  final Analysis analysis;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.analysis, this.onTap});

  @override
  Widget build(BuildContext context) {
    final prediction = analysis.prediction.toLowerCase();
    final style = switch (prediction) {
      'malignant' => (
        AppColors.errorContainer,
        AppColors.onErrorContainer,
        Icons.warning_amber_rounded,
      ),
      'benign' => (
        AppColors.benignBg,
        AppColors.benignText,
        Icons.check_circle_outline,
      ),
      _ => (
        AppColors.surfaceContainerHighest,
        AppColors.onSurfaceVariant,
        Icons.help_outline,
      ),
    };
    return Semantics(
      button: true,
      label:
          'Abrir evaluación de ${analysis.patientName ?? 'paciente no disponible'}, ${_predictionLabel(prediction)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          key: Key('historyCard-${analysis.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _date(analysis.evaluatedAt ?? analysis.timestamp),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: style.$1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.$3, size: 15, color: style.$2),
                          const SizedBox(width: 4),
                          Text(
                            _predictionLabel(prediction),
                            style: TextStyle(
                              color: style.$2,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  analysis.patientName ?? 'Paciente no disponible',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                        if (analysis.patientId?.trim().isNotEmpty == true)
                          analysis.patientId!,
                        if (analysis.lesionSite?.trim().isNotEmpty == true)
                          analysis.lesionSite!,
                      ].isEmpty
                      ? 'Código y sitio no disponibles'
                      : [
                          if (analysis.patientId?.trim().isNotEmpty == true)
                            analysis.patientId!,
                          if (analysis.lesionSite?.trim().isNotEmpty == true)
                            analysis.lesionSite!,
                        ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Confianza del clasificador ${(analysis.confidence.clamp(0, 1) * 100).toStringAsFixed(0)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (analysis.priority case final priority?)
                      Text(
                        localizedPriorityStatus(priority.priorityCode).label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Profesional: ${analysis.professionalName ?? analysis.createdByName ?? 'No disponible'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _predictionLabel(String value) => localizedModelOutput(value).label;

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
