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
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar lesión'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: site,
                    decoration: const InputDecoration(
                      labelText: 'Sitio anatómico *',
                      hintText: 'Ej.: mucosa yugal derecha',
                    ),
                    validator: (value) => value?.trim().isEmpty == true
                        ? 'Ingrese el sitio anatómico.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showDatePicker(
                        context: context,
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
                    decoration: const InputDecoration(
                      labelText: 'Duración estimada',
                      hintText: 'Ej.: cerca de 2 semanas',
                      helperText: 'Puede registrar fecha, duración o ambas.',
                    ),
                    validator: (value) =>
                        observedAt == null && value!.trim().isEmpty
                        ? 'Indique una fecha o una duración.'
                        : null,
                  ),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas longitudinales de la lesión',
                      helperText:
                          'Evolución general; los hallazgos actuales se registran al analizar.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (submit != true) return;
    await ref
        .read(patientFollowUpControllerProvider.notifier)
        .addLesion(
          anatomicalSite: site.text.trim(),
          observedAt: observedAt,
          estimatedDuration: duration.text.trim().isEmpty
              ? null
              : duration.text.trim(),
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        );
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
