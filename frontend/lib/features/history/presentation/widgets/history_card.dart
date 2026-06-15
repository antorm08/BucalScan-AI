import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/history/domain/entities/analysis.dart';

class HistoryCard extends StatelessWidget {
  final Analysis analysis;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.analysis, this.onTap});

  @override
  Widget build(BuildContext context) {
    final prediction = analysis.prediction.toLowerCase();
    final hasImage =
        analysis.imageUrl != null && analysis.imageUrl!.trim().isNotEmpty;
    Color accentColor, badgeBg, badgeText, badgeIconColor;
    IconData badgeIcon;

    switch (prediction) {
      case 'malignant':
        accentColor = AppColors.error;
        badgeBg = AppColors.errorContainer;
        badgeText = AppColors.onErrorContainer;
        badgeIconColor = AppColors.onErrorContainer;
        badgeIcon = Icons.warning;
        break;
      default:
        accentColor = const Color(0xFF4CAF50);
        badgeBg = AppColors.benignBg;
        badgeText = AppColors.benignText;
        badgeIconColor = AppColors.benignText;
        badgeIcon = Icons.check_circle;
    }

    final displayLabel = prediction == 'malignant' ? 'Maligno' : 'Benigno';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.network(
                            analysis.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image,
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                                size: 28,
                              );
                            },
                          )
                        : Icon(
                            Icons.image,
                            color: AppColors.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _formatDate(analysis.timestamp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    badgeIcon,
                                    size: 14,
                                    color: badgeIconColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    displayLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: badgeText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.patientName ??
                              (analysis.patientId != null
                                  ? 'ID: ${analysis.patientId}'
                                  : 'Paciente #ID-${analysis.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Confianza: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]}, ${date.year} · $hour:$minute';
  }
}
