import 'package:bucalscan_ai/core/constants/app_constants.dart';
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
          'El centro activo define qué pacientes y registros puede consultar. Cambiar de centro elimina solo selecciones, imagen y borradores no guardados; los registros guardados permanecen.',
      icon: Icons.domain_outlined,
    ),
    (
      title: 'Pacientes y lesiones',
      body:
          'Los pacientes se comparten entre profesionales autorizados del centro. La fecha de primera observación y la duración estimada son datos distintos. Las notas de lesión describen su seguimiento longitudinal.',
      icon: Icons.people_outline,
    ),
    (
      title: 'Captura y hallazgos',
      body:
          'Seleccione un paciente, una lesión y una imagen clara. Cada imagen corresponde a una sola lesión y evaluación. Los hallazgos actuales pertenecen únicamente a esa evaluación.',
      icon: Icons.add_a_photo_outlined,
    ),
    (
      title: 'Resultados, confianza y prioridad',
      body:
          'La confianza expresa cuánto favorece el clasificador su propia salida; no es probabilidad de cáncer, diagnóstico ni urgencia. La prioridad clínica, cuando está habilitada, se calcula por separado en el servidor a partir de respuestas estructuradas.',
      icon: Icons.assessment_outlined,
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
          'Use búsqueda y filtros para revisar evaluaciones guardadas del centro activo. Un resultado desconocido se muestra de forma neutral. Los enlaces clínicos respetan el acceso vigente.',
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
          'Si cámara, galería o conexión fallan, revise permisos y conectividad antes de reintentar. Soporte: soporte@bucalscan.local. Versión ${AppConstants.appName} 1.1.0 (3).',
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
            TextField(
              key: const Key('helpSearchField'),
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Buscar ayuda',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No se encontraron temas relacionados.'),
              ),
            ...sections.map(
              (item) => Card(
                child: ExpansionTile(
                  key: ValueKey(item.title),
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(item.body)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
