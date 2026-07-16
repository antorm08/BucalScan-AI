import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

String localizedPriorityReason(String code, {String? fallback}) {
  const fixedReasons = {
    'priority.standard.complete':
        'La evaluación está completa y no se activó una regla de atención superior.',
    'priority.prompt.score':
        'Los hallazgos estructurados alcanzaron el umbral académico de atención pronta.',
    'priority.prompt.persistence_sign':
        'Se registró persistencia junto con al menos un signo de preocupación.',
    'priority.urgent.score':
        'Los hallazgos estructurados alcanzaron el umbral académico de atención urgente.',
    'priority.urgent.high_concern_combination':
        'Se registró una combinación académica de signos de alta preocupación.',
  };
  if (fixedReasons[code] case final reason?) return reason;

  final separator = code.indexOf('.');
  if (separator > 0) {
    final prefix = code.substring(0, separator);
    final field = code.substring(separator + 1);
    final label = clinicalAssessmentFields[field];
    if (label != null) {
      return switch (prefix) {
        'emergency' => 'Se confirmó un signo de emergencia: $label.',
        'missing' => 'Falta evaluar: $label.',
        _ =>
          fallback?.trim().isNotEmpty == true
              ? fallback!.trim()
              : 'Motivo registrado por el ruleset activo.',
      };
    }
  }

  return fallback?.trim().isNotEmpty == true
      ? fallback!.trim()
      : 'Motivo registrado por el ruleset activo.';
}

List<String> localizedPriorityReasons(ClinicalPriorityResult priority) {
  if (priority.reasonCodes.isEmpty) {
    return priority.reasons;
  }
  return [
    for (var index = 0; index < priority.reasonCodes.length; index++)
      localizedPriorityReason(
        priority.reasonCodes[index],
        fallback: index < priority.reasons.length
            ? priority.reasons[index]
            : null,
      ),
  ];
}
