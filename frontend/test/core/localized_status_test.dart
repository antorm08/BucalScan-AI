import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known lifecycle, model and priority values are localized', () {
    expect(localizedUserStatus('suspended').label, 'Suspendido');
    expect(localizedWorkspaceStatus('rejected').label, 'Rechazado');
    expect(localizedMembershipStatus('inactive').label, 'Inactivo');
    expect(localizedLesionStatus('monitoring').label, 'En seguimiento');
    expect(localizedModelOutput('malignant').label, 'Patrón maligno');
    expect(
      localizedPriorityStatus('emergency').label,
      'Atención de emergencia',
    );
    expect(
      localizedModelRecommendation('benign'),
      contains('Continúe la evaluación profesional'),
    );
    expect(
      localizedModelRecommendation('malignant'),
      contains('no establece un diagnóstico'),
    );
  });

  test('unsupported and null values are always neutral and non-success', () {
    final statuses = [
      localizedUserStatus(null),
      localizedWorkspaceStatus('future'),
      localizedMembershipStatus('future'),
      localizedLesionStatus('future'),
      localizedPriorityStatus('future'),
    ];
    for (final status in statuses) {
      expect(status.label, 'No disponible');
      expect(status.icon, Icons.help_outline);
      expect(status.tone, StatusTone.neutral);
    }
    final model = localizedModelOutput('future');
    expect(model.label, 'Salida desconocida');
    expect(model.icon, Icons.help_outline);
    expect(model.tone, StatusTone.neutral);
  });
}
