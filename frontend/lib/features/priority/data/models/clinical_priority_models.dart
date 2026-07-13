import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

class ClinicalPriorityCapabilityModel {
  static ClinicalPriorityCapability fromJson(Map<String, dynamic> json) {
    final rawMode = json['mode']?.toString();
    final activeRuleset = json['active_ruleset']?.toString();
    final parsedMode = switch (rawMode) {
      'disabled' => ClinicalPriorityMode.disabled,
      'academic' => ClinicalPriorityMode.academic,
      'enabled' => ClinicalPriorityMode.enabled,
      _ => ClinicalPriorityMode.unsupported,
    };
    final supported =
        activeRuleset == null ||
        activeRuleset == supportedClinicalPriorityRuleset;
    return ClinicalPriorityCapability(
      mode: supported ? parsedMode : ClinicalPriorityMode.unsupported,
      available: json['available'] == true && supported,
      activeRuleset: activeRuleset,
      assessmentSchemaVersion:
          json['assessment_schema_version']?.toString() ?? '',
      engineVersion: json['engine_version']?.toString() ?? '',
      notice: json['notice']?.toString() ?? '',
    );
  }
}

class ClinicalPriorityResultModel {
  static ClinicalPriorityResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    return ClinicalPriorityResult(
      priorityCode: json['priority_code']?.toString() ?? 'incomplete',
      reasonCodes: (json['reason_codes'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      reasons: (json['rendered_reasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      rulesetId: json['ruleset_id']?.toString() ?? '',
      rulesetVersion: json['ruleset_version']?.toString() ?? '',
      engineVersion: json['engine_version']?.toString() ?? '',
      evaluatedAt: DateTime.tryParse(json['evaluated_at']?.toString() ?? ''),
      completionStatus: json['completion_status']?.toString() ?? 'incomplete',
    );
  }
}
