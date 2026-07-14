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
            title: const Text('Registrar lesión'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
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
                      ),
                      TextFormField(
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
                      const SizedBox(height: 12),
                      const Text(
                        'Notas para seguimiento (opcional)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Describa la evolución general de la lesión. Los hallazgos de una evaluación puntual se registran durante el análisis.',
                      ),
                      const SizedBox(height: 8),
                      TextField(
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _Profile(patient: patient),
                const SizedBox(height: 20),
                Text(
                  'Lesiones (${state.lesions.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (state.lesions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aún no hay lesiones registradas. Añade la primera para iniciar seguimiento.',
                      ),
                    ),
                  )
                else
                  ...state.lesions.map(
                    (lesion) => Card(
                      key: Key('lesion-${lesion.id}'),
                      child: ListTile(
                        leading: const Icon(
                          Icons.adjust,
                          color: AppColors.primary,
                        ),
                        title: Text(lesion.anatomicalSite),
                        subtitle: Text(
                          '${lesion.temporalDescription} · ${_status(lesion.status)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
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
    );
  }
}

String _status(String value) => localizedLesionStatus(value).label;

class _Profile extends StatelessWidget {
  final Patient patient;
  const _Profile({required this.patient});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Código clínico: ${patient.clinicalCode}',
          style: const TextStyle(color: AppColors.primaryFixed),
        ),
        if (patient.identityDocument != null)
          Text(
            'Documento: ${patient.identityDocument}',
            style: const TextStyle(color: AppColors.primaryFixed),
          ),
        if (patient.telephone != null)
          Text(
            'Teléfono: ${patient.telephone}',
            style: const TextStyle(color: AppColors.primaryFixed),
          ),
        if (patient.notes != null) ...[
          const SizedBox(height: 10),
          Text(patient.notes!, style: const TextStyle(color: Colors.white)),
        ],
      ],
    ),
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
