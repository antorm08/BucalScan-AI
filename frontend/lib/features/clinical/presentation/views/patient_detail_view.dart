import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/lesion_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientDetailView extends ConsumerStatefulWidget {
  final String patientId;
  final void Function(Patient, OralLesion) onRepeatAnalysis;

  const PatientDetailView({
    super.key,
    required this.patientId,
    required this.onRepeatAnalysis,
  });

  @override
  ConsumerState<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends ConsumerState<PatientDetailView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(patientFollowUpControllerProvider.notifier)
          .loadPatient(widget.patientId),
    );
  }

  Future<void> _addLesion() async {
    final site = TextEditingController();
    final duration = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? observedAt;
    var submitting = false;
    String? submitError;
    var saved = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !submitting,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: const Text('Registrar lesión'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FormSectionLabel(
                        icon: Icons.location_on_outlined,
                        title: 'Ubicación de la lesión',
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('registerLesionSite'),
                        controller: site,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Sitio anatómico *',
                          hintText: 'Ej.: mucosa yugal derecha',
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : 'Ingrese el sitio anatómico.',
                      ),
                      const SizedBox(height: 22),
                      const _FormSectionLabel(
                        icon: Icons.schedule_outlined,
                        title: 'Temporalidad',
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('registerLesionObservedAt'),
                        onPressed: submitting
                            ? null
                            : () async {
                                final value = await showDatePicker(
                                  context: dialogContext,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  initialDate: observedAt ?? DateTime.now(),
                                );
                                if (value != null) {
                                  setDialogState(() => observedAt = value);
                                }
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          observedAt == null
                              ? 'Fecha de primera observación'
                              : 'Observada el ${observedAt!.day}/${observedAt!.month}/${observedAt!.year}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('registerLesionDuration'),
                        controller: duration,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Duración estimada',
                          hintText: 'Ej.: cerca de 2 semanas',
                          helperText:
                              'Registre una fecha, una duración o ambas.',
                          helperMaxLines: 2,
                        ),
                        validator: (value) =>
                            observedAt == null && value!.trim().isEmpty
                            ? 'Indique una fecha o una duración.'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      const _FormSectionLabel(
                        icon: Icons.notes_outlined,
                        title: 'Seguimiento longitudinal',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Describa la evolución general de la lesión. Los hallazgos de una evaluación puntual se registran durante el análisis.',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('registerLesionNotes'),
                        controller: notes,
                        enabled: !submitting,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Ej.: lesión estable desde la consulta anterior',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('registerLesionSubmit'),
                onPressed: submitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          submitting = true;
                          submitError = null;
                        });
                        saved = await ref
                            .read(patientFollowUpControllerProvider.notifier)
                            .addLesion(
                              anatomicalSite: site.text.trim(),
                              observedAt: observedAt,
                              estimatedDuration: duration.text.trim().isEmpty
                                  ? null
                                  : duration.text.trim(),
                              notes: notes.text.trim().isEmpty
                                  ? null
                                  : notes.text.trim(),
                            );
                        if (!dialogContext.mounted) return;
                        if (saved) {
                          Navigator.pop(dialogContext);
                        } else {
                          setDialogState(() {
                            submitting = false;
                            submitError =
                                'No se pudo registrar la lesión. Inténtelo nuevamente.';
                          });
                        }
                      },
                child: submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesión registrada correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientFollowUpControllerProvider);
    final patient = state.patient;
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del paciente')),
      floatingActionButton: patient == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('addLesionButton'),
              onPressed: state.actionStatus == FollowUpActionStatus.updating
                  ? null
                  : _addLesion,
              icon: const Icon(Icons.add),
              label: const Text('Añadir lesión'),
            ),
      body: state.status == FollowUpStatus.loading && patient == null
          ? const Center(child: CircularProgressIndicator())
          : state.status == FollowUpStatus.error && patient == null
          ? _Retry(
              message: state.error!,
              onRetry: () => ref
                  .read(patientFollowUpControllerProvider.notifier)
                  .loadPatient(widget.patientId),
            )
          : patient == null
          ? const Center(child: Text('Paciente no disponible.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    _Profile(patient: patient),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.monitor_heart_outlined,
                            color: AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lesiones en seguimiento',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${state.lesions.length} ${state.lesions.length == 1 ? 'lesión registrada' : 'lesiones registradas'}',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.lesions.isEmpty)
                      const _EmptyLesions()
                    else
                      ...state.lesions.map(
                        (lesion) => _LesionCard(
                          lesion: lesion,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LesionDetailView(
                                patient: patient,
                                lesionId: lesion.id,
                                onRepeatAnalysis: widget.onRepeatAnalysis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (state.actionError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          state.actionError!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Profile extends StatelessWidget {
  final Patient patient;
  const _Profile({required this.patient});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paciente',
                    style: TextStyle(
                      color: AppColors.primaryFixedDim,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    patient.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ProfileDatum(
              icon: Icons.badge_outlined,
              label: 'Código clínico',
              value: patient.clinicalCode,
            ),
            if (patient.identityDocument?.trim().isNotEmpty == true)
              _ProfileDatum(
                icon: Icons.credit_card_outlined,
                label: 'Documento',
                value: patient.identityDocument!,
              ),
            if (patient.telephone?.trim().isNotEmpty == true)
              _ProfileDatum(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: patient.telephone!,
              ),
          ],
        ),
        if (patient.notes?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              patient.notes!,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProfileDatum extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDatum({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryFixedDim),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LesionCard extends StatelessWidget {
  final OralLesion lesion;
  final VoidCallback onTap;

  const _LesionCard({required this.lesion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = localizedLesionStatus(lesion.status);
    return Card(
      key: Key('lesion-${lesion.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.adjust, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesion.anatomicalSite,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesion.temporalDescription,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            status.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLesions extends StatelessWidget {
  const _EmptyLesions();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.outlineVariant),
    ),
    child: const Column(
      children: [
        Icon(Icons.add_circle_outline, size: 38, color: AppColors.primary),
        SizedBox(height: 10),
        Text(
          'Sin lesiones registradas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Añade la primera lesión para iniciar su seguimiento longitudinal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class _FormSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FormSectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Retry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
