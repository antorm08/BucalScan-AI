enum ClinicalPriorityMode { disabled, academic, enabled, unsupported }

enum ClinicalTriState { yes, no, unknown }

class ClinicalPriorityCapability {
  final ClinicalPriorityMode mode;
  final bool available;
  final String? activeRuleset;
  final String assessmentSchemaVersion;
  final String engineVersion;
  final String notice;

  const ClinicalPriorityCapability({
    required this.mode,
    required this.available,
    required this.activeRuleset,
    required this.assessmentSchemaVersion,
    required this.engineVersion,
    required this.notice,
  });
}

class ClinicalPriorityResult {
  final String priorityCode;
  final List<String> reasonCodes;
  final List<String> reasons;
  final String rulesetId;
  final String rulesetVersion;
  final String engineVersion;
  final DateTime? evaluatedAt;
  final String completionStatus;

  const ClinicalPriorityResult({
    required this.priorityCode,
    required this.reasonCodes,
    required this.reasons,
    required this.rulesetId,
    required this.rulesetVersion,
    required this.engineVersion,
    required this.evaluatedAt,
    required this.completionStatus,
  });
}

const supportedClinicalPriorityRuleset = 'clinical-priority-v1';

const clinicalAssessmentFields = <String, String>{
  'ulceration': 'Ulceración',
  'induration_or_fixation': 'Induración o fijación',
  'unexplained_bleeding': 'Sangrado sin causa explicada',
  'red_or_white_change': 'Cambio rojo o blanco',
  'rapid_growth': 'Crecimiento rápido',
  'pain': 'Dolor',
  'dysphagia': 'Dificultad para tragar',
  'altered_sensation': 'Alteración de la sensibilidad',
  'functional_limitation': 'Limitación funcional',
  'persistence_over_two_weeks': 'Persistencia mayor a dos semanas',
  'tobacco_exposure': 'Exposición al tabaco',
  'heavy_alcohol_exposure': 'Consumo elevado de alcohol',
  'prior_oral_malignancy': 'Antecedente de malignidad oral',
  'immunosuppression': 'Inmunosupresión',
  'airway_compromise': 'Compromiso de la vía aérea',
  'uncontrolled_bleeding': 'Sangrado no controlado',
  'inability_to_swallow': 'Imposibilidad para tragar',
  'rapidly_progressing_face_neck_swelling': 'Hinchazón rápida de cara o cuello',
};

String clinicalTriStateValue(ClinicalTriState value) => switch (value) {
  ClinicalTriState.yes => 'true',
  ClinicalTriState.no => 'false',
  ClinicalTriState.unknown => 'unknown',
};
