import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';
import 'package:bucalscan_ai/core/widgets/heatmap_overlay_image.dart';
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 108,
                child: _HistoryThumbnail(
                  key: Key('historyImage-${analysis.id}'),
                  imageUrl: analysis.imageUrl,
                  heatmapUrl: analysis.heatmapUrl,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _date(analysis.evaluatedAt ?? analysis.timestamp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: style.$1,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _predictionLabel(prediction),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: style.$2,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        analysis.patientName ?? 'Paciente no disponible',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                              if (analysis.patientId?.trim().isNotEmpty == true)
                                analysis.patientId!,
                              if (analysis.lesionSite?.trim().isNotEmpty ==
                                  true)
                                analysis.lesionSite!,
                            ].isEmpty
                            ? 'Código y sitio no disponibles'
                            : [
                                if (analysis.patientId?.trim().isNotEmpty ==
                                    true)
                                  analysis.patientId!,
                                if (analysis.lesionSite?.trim().isNotEmpty ==
                                    true)
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
                              localizedPriorityStatus(
                                priority.priorityCode,
                              ).label,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? heatmapUrl;

  const _HistoryThumbnail({super.key, this.imageUrl, this.heatmapUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl?.trim().isNotEmpty != true) return _fallback();
    return HeatmapOverlayImage(
      baseImage: NetworkImage(imageUrl!),
      heatmapUrl: heatmapUrl,
      errorFallback: _fallback(),
    );
  }

  Widget _fallback() => Container(
    color: AppColors.surfaceContainerHigh,
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_outlined,
      color: AppColors.onSurfaceVariant,
      size: 32,
    ),
  );
}

String _predictionLabel(String value) => localizedModelOutput(value).label;

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}
