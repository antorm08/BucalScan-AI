import 'package:flutter/material.dart';

enum StatusTone { neutral, info, success, warning, danger }

class LocalizedStatus {
  final String label;
  final IconData icon;
  final StatusTone tone;

  const LocalizedStatus(this.label, this.icon, this.tone);
}

const _unknownStatus = LocalizedStatus(
  'No disponible',
  Icons.help_outline,
  StatusTone.neutral,
);

LocalizedStatus localizedUserStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'pending' => const LocalizedStatus(
        'Pendiente',
        Icons.schedule,
        StatusTone.warning,
      ),
      'active' => const LocalizedStatus(
        'Activo',
        Icons.check_circle_outline,
        StatusTone.success,
      ),
      'suspended' => const LocalizedStatus(
        'Suspendido',
        Icons.block,
        StatusTone.danger,
      ),
      _ => _unknownStatus,
    };

LocalizedStatus localizedWorkspaceStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'pending' => const LocalizedStatus(
        'Pendiente',
        Icons.schedule,
        StatusTone.warning,
      ),
      'active' => const LocalizedStatus(
        'Activo',
        Icons.check_circle_outline,
        StatusTone.success,
      ),
      'rejected' => const LocalizedStatus(
        'Rechazado',
        Icons.cancel_outlined,
        StatusTone.danger,
      ),
      _ => _unknownStatus,
    };

LocalizedStatus localizedMembershipStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'pending' => const LocalizedStatus(
        'Pendiente',
        Icons.schedule,
        StatusTone.warning,
      ),
      'active' => const LocalizedStatus(
        'Activo',
        Icons.check_circle_outline,
        StatusTone.success,
      ),
      'rejected' => const LocalizedStatus(
        'Rechazado',
        Icons.cancel_outlined,
        StatusTone.danger,
      ),
      'inactive' => const LocalizedStatus(
        'Inactivo',
        Icons.pause_circle_outline,
        StatusTone.neutral,
      ),
      _ => _unknownStatus,
    };

LocalizedStatus localizedLifecycleStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'suspended' => localizedUserStatus(value),
      'inactive' => localizedMembershipStatus(value),
      'rejected' => localizedWorkspaceStatus(value),
      'pending' || 'active' => localizedMembershipStatus(value),
      _ => _unknownStatus,
    };

LocalizedStatus localizedLesionStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'active' => const LocalizedStatus(
        'Activa',
        Icons.radio_button_checked,
        StatusTone.warning,
      ),
      'monitoring' => const LocalizedStatus(
        'En seguimiento',
        Icons.visibility_outlined,
        StatusTone.info,
      ),
      'resolved' => const LocalizedStatus(
        'Resuelta',
        Icons.check_circle_outline,
        StatusTone.success,
      ),
      _ => _unknownStatus,
    };

LocalizedStatus localizedModelOutput(String? value) =>
    switch (value?.toLowerCase()) {
      'benign' || 'benigno' => const LocalizedStatus(
        'Patrón benigno',
        Icons.info_outline,
        StatusTone.info,
      ),
      'malignant' || 'maligno' => const LocalizedStatus(
        'Patrón maligno',
        Icons.priority_high,
        StatusTone.warning,
      ),
      _ => const LocalizedStatus(
        'Salida desconocida',
        Icons.help_outline,
        StatusTone.neutral,
      ),
    };

String localizedModelRecommendation(String? prediction) => switch (prediction
    ?.trim()
    .toLowerCase()) {
  'benign' || 'benigno' =>
    'Continúe la evaluación profesional; la salida del modelo no descarta preocupación clínica.',
  'malignant' || 'maligno' =>
    'La salida del modelo sugiere una revisión profesional oportuna; no establece un diagnóstico.',
  _ =>
    'La orientación no está disponible para esta salida. Continúe con la evaluación profesional.',
};

LocalizedStatus localizedPriorityStatus(String? value) =>
    switch (value?.toLowerCase()) {
      'standard' => const LocalizedStatus(
        'Atención habitual',
        Icons.event_available,
        StatusTone.success,
      ),
      'prompt' => const LocalizedStatus(
        'Atención pronta',
        Icons.update,
        StatusTone.info,
      ),
      'urgent' => const LocalizedStatus(
        'Atención urgente',
        Icons.priority_high,
        StatusTone.warning,
      ),
      'emergency' => const LocalizedStatus(
        'Atención de emergencia',
        Icons.emergency_outlined,
        StatusTone.danger,
      ),
      'incomplete' => const LocalizedStatus(
        'Evaluación incompleta',
        Icons.pending_actions,
        StatusTone.neutral,
      ),
      _ => _unknownStatus,
    };
