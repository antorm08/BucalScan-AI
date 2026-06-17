import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';

class ModelInfoView extends StatelessWidget {
  const ModelInfoView({super.key});

  static const _metrics = [
    _MetricItem('Accuracy', '0.8980'),
    _MetricItem('Precision', '0.8519'),
    _MetricItem('Recall', '0.9583'),
    _MetricItem('F1-Score', '0.9020'),
    _MetricItem('AUC-ROC', '0.9367'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Acerca del modelo'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.primaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      color: AppColors.onPrimary,
                      size: 36,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'ResNet50 para clasificación binaria',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'El sistema distingue únicamente entre lesión benigna y lesión maligna. No reemplaza el diagnóstico clínico profesional.',
                      style: TextStyle(
                        color: AppColors.primaryFixed,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Entrada y salida',
              icon: Icons.input_outlined,
              children: [
                _InfoRow(label: 'Arquitectura', value: 'ResNet50'),
                _InfoRow(label: 'Formato', value: 'ONNX'),
                _InfoRow(label: 'Entrada', value: 'Imagen RGB 224x224'),
                _InfoRow(label: 'Clases', value: 'Benigna y Maligna'),
                _InfoRow(
                  label: 'Salida',
                  value: 'Clase predicha, confianza y recomendación',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Métricas de validación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._metrics.map(
                      (metric) => _MetricTile(
                        label: metric.label,
                        value: metric.value,
                        highlight: metric.label == 'Recall',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.benignBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ResNet50 fue seleccionado por ClinicalScore = 0.50 * Recall + 0.30 * F1 + 0.20 * AUC. Este criterio prioriza sensibilidad clínica; su recall de 0.9583 reduce el riesgo de omitir lesiones malignas en el conjunto evaluado.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.benignText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Privacidad y retención',
              icon: Icons.privacy_tip_outlined,
              children: [
                Text(
                  'La imagen clínica y el resultado solo se guardan cuando el usuario acepta el consentimiento antes del análisis. Los registros quedan asociados a la cuenta autenticada y se usan para consulta de historial y seguimiento académico/clínico.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Para solicitar eliminación o corrección de registros, el usuario debe contactar al administrador del sistema. No se recomienda ingresar datos personales del paciente si el caso no requiere identificación nominal.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Interpretación clínica',
              icon: Icons.health_and_safety_outlined,
              children: [
                Text(
                  'El resultado funciona como apoyo para detección temprana y priorización de derivación médica. Una clasificación maligna debe considerarse sospechosa y requiere evaluación por especialista.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;

  const _MetricItem(this.label, this.value);
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: highlight ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.onPrimary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
