import 'package:bucalscan_ai/core/constants/app_constants.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/widgets/responsive_content.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  String _query = '';

  static const _sections = <({String title, String body, IconData icon})>[
    (
      title: 'Acceso y centros',
      body:
          'El centro activo define qué pacientes y registros puede consultar. Cambiar de centro limpia las selecciones y borradores locales, pero conserva los registros guardados. Los centros institucionales requieren ciudad y dirección antes de su aprobación por un administrador de plataforma.',
      icon: Icons.domain_outlined,
    ),
    (
      title: 'Pacientes y lesiones',
      body:
          'Los pacientes se comparten entre profesionales autorizados del centro. Cada lesión mantiene sitio anatómico, estado, fecha de primera observación, duración estimada y notas longitudinales. La fecha y la duración son datos distintos; conserve al menos uno de los dos.',
      icon: Icons.people_outline,
    ),
    (
      title: 'Flujo de análisis',
      body:
          'El análisis avanza en tres pasos: contexto clínico, imagen y evaluación. Seleccione un paciente y una lesión existentes, capture una imagen clara y complete los hallazgos actuales. Cada imagen y sus hallazgos pertenecen a una sola evaluación de esa lesión.',
      icon: Icons.add_a_photo_outlined,
    ),
    (
      title: 'Calidad de imagen y mapa CAM',
      body:
          'Antes de inferir, la aplicación revisa resolución, nitidez e iluminación. El mapa CAM resalta regiones que influyeron en la salida del modelo; no delimita una lesión, no explica causalidad y no constituye diagnóstico.',
      icon: Icons.visibility_outlined,
    ),
    (
      title: 'Evaluación clínica y prioridad',
      body:
          'El cuestionario clínico contiene 18 respuestas estructuradas. La prioridad orientativa se calcula por separado del modelo de imagen y puede quedar incompleta si faltan datos. No reemplaza el juicio profesional ni los servicios de emergencia.',
      icon: Icons.fact_check_outlined,
    ),
    (
      title: 'Resultado y confianza',
      body:
          'La confianza expresa cuánto favorece el clasificador su propia salida; no es probabilidad de cáncer, diagnóstico ni urgencia. Revise primero el resumen clínico y la orientación profesional; los datos técnicos permanecen disponibles como información secundaria.',
      icon: Icons.assessment_outlined,
    ),
    (
      title: 'Seguimiento, comparación e informes',
      body:
          'La línea de tiempo reúne las evaluaciones de una misma lesión. Para comparar se necesitan al menos dos evaluaciones de esa lesión y ambas deben incluir imagen y resultado del modelo. El informe PDF resume una evaluación individual y puede descargarse desde su tarjeta; recuerde que el archivo queda fuera de la aplicación.',
      icon: Icons.timeline_outlined,
    ),
    (
      title: 'Nueva imagen y reintento',
      body:
          'Otra imagen para esta lesión conserva paciente y lesión, pero limpia imagen, atestación, hallazgos y evaluación estructurada. Reintentar un fallo reutiliza la copia inmutable del intento original.',
      icon: Icons.refresh_outlined,
    ),
    (
      title: 'Historial',
      body:
          'Use búsqueda, fechas, salida del modelo y prioridad para revisar evaluaciones del centro activo. Desde cada registro puede volver a la ficha longitudinal de la lesión. Los enlaces clínicos siempre respetan el acceso vigente al workspace.',
      icon: Icons.history_outlined,
    ),
    (
      title: 'Autorización y privacidad',
      body:
          'Antes de analizar, confirme que obtuvo autorización para capturar, procesar y almacenar la imagen y el resultado. No comparta credenciales ni datos fuera del contexto asistencial autorizado.',
      icon: Icons.privacy_tip_outlined,
    ),
    (
      title: 'Soporte',
      body:
          'Si cámara, galería o conexión fallan, revise permisos y conectividad antes de reintentar. Soporte: soporte@bucalscan.local. Versión ${AppConstants.appName} ${AppConstants.appVersion} (${AppConstants.buildNumber}).',
      icon: Icons.support_agent_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final sections = _sections
        .where(
          (item) =>
              normalized.isEmpty ||
              item.title.toLowerCase().contains(normalized) ||
              item.body.toLowerCase().contains(normalized),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Centro de ayuda')),
      body: ResponsiveContent(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x26FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.support_agent_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Qué necesitas resolver?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Consulta los flujos clínicos, resultados y acciones disponibles en la versión actual.',
                          style: TextStyle(
                            color: Color(0xFFE8F1FF),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('helpSearchField'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Buscar ayuda',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Temas de ayuda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${sections.length} temas',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (sections.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No se encontraron temas relacionados.'),
                ),
              ),
            ...sections.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    key: ValueKey(item.title),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: AppColors.primary),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
