import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';

class PatientLesionPicker extends ConsumerStatefulWidget {
  const PatientLesionPicker({super.key});

  @override
  ConsumerState<PatientLesionPicker> createState() =>
      _PatientLesionPickerState();
}

class _PatientLesionPickerState extends ConsumerState<PatientLesionPicker> {
  final _search = TextEditingController();
  List<Patient> _patients = const [];
  List<OralLesion> _lesions = const [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    final patient = ref.read(clinicalControllerProvider).patient;
    if (patient != null) Future.microtask(() => _choosePatient(patient));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _findPatients() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final patients = await ref.read(searchPatientsUseCaseProvider)(
        _search.text.trim(),
      );
      if (mounted && generation == _requestGeneration) {
        setState(() {
          _patients = patients;
          _searched = true;
        });
      }
    } catch (_) {
      if (mounted && generation == _requestGeneration) {
        setState(() => _error = 'No se pudieron buscar pacientes.');
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _choosePatient(Patient patient) async {
    final generation = ++_requestGeneration;
    final previousLesion = ref.read(clinicalControllerProvider).lesion;
    ref.read(clinicalControllerProvider.notifier).selectPatient(patient);
    setState(() {
      _loading = true;
      _error = null;
      _lesions = const [];
    });
    try {
      final lesions = await ref.read(getLesionsUseCaseProvider)(patient.id);
      if (mounted && generation == _requestGeneration) {
        setState(() => _lesions = lesions);
        final refreshedLesion = previousLesion == null
            ? null
            : lesions.where((item) => item.id == previousLesion.id).firstOrNull;
        if (refreshedLesion != null) {
          ref
              .read(clinicalControllerProvider.notifier)
              .selectLesion(refreshedLesion);
        }
      }
    } catch (_) {
      if (mounted && generation == _requestGeneration) {
        setState(() => _error = 'No se pudieron cargar las lesiones.');
      }
    } finally {
      if (mounted && generation == _requestGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createPatient() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final document = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Patient? createdPatient;
    var submitting = false;
    String? submitError;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => PopScope(
          canPop: !submitting,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: const Text('Nuevo paciente'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('newPatientClinicalCode'),
                        controller: code,
                        enabled: !submitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Código clínico *',
                          hintText: 'Ej.: 000123',
                          helperText: 'Debe contener exactamente 6 dígitos.',
                          helperMaxLines: 2,
                        ),
                        validator: (value) => value?.trim().length == 6
                            ? null
                            : 'Ingrese exactamente 6 dígitos.',
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        key: const Key('newPatientFullName'),
                        controller: name,
                        enabled: !submitting,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : 'Ingrese el nombre completo.',
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        key: const Key('newPatientDocument'),
                        controller: document,
                        enabled: !submitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Documento (opcional)',
                          helperText:
                              'Si lo registra, debe tener al menos 7 dígitos.',
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          final digits = value?.trim() ?? '';
                          if (digits.isEmpty || digits.length >= 7) return null;
                          return 'Ingrese al menos 7 dígitos o déjelo vacío.';
                        },
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(color: Colors.red),
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
                key: const Key('createPatientSubmit'),
                onPressed: submitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        updateDialog(() {
                          submitting = true;
                          submitError = null;
                        });
                        try {
                          createdPatient =
                              await ref.read(createPatientUseCaseProvider)(
                                clinicalCode: code.text.trim(),
                                fullName: name.text.trim(),
                                identityDocument: document.text.trim(),
                              );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            updateDialog(() {
                              submitting = false;
                              submitError =
                                  'No se pudo crear. Verifique que el código o documento no estén registrados.';
                            });
                          }
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
                    : const Text('Crear'),
              ),
            ],
          ),
        ),
      ),
    );
    final patient = createdPatient;
    if (patient == null || !mounted) return;
    ref
        .read(patientFollowUpControllerProvider.notifier)
        .registerCreatedPatient(patient);
    await _choosePatient(patient);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente registrado correctamente.')),
      );
    }
  }

  Future<void> _createLesion(Patient patient) async {
    final site = TextEditingController();
    final duration = TextEditingController();
    final notes = TextEditingController();
    DateTime? observedAt;
    final formKey = GlobalKey<FormState>();
    OralLesion? createdLesion;
    var submitting = false;
    String? submitError;
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
            title: const Text('Nueva lesión'),
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
                          hintText: 'Ej.: borde lateral de lengua',
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
                          hintText: 'Ej.: aproximadamente 3 semanas',
                          helperText:
                              'Registre una fecha, una duración o ambas.',
                          helperMaxLines: 2,
                        ),
                        validator: (value) =>
                            observedAt == null && value!.trim().isEmpty
                            ? 'Indique una fecha o una duración estimada.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Notas para seguimiento (opcional)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use este campo para registrar la evolución general de la lesión. Los hallazgos de una evaluación específica se escriben al realizar el análisis.',
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('newLesionNotes'),
                        controller: notes,
                        enabled: !submitting,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Ej.: lesión sin cambios desde la última consulta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          submitError!,
                          style: const TextStyle(color: Colors.red),
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
                key: const Key('createLesionSubmit'),
                onPressed: submitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          submitting = true;
                          submitError = null;
                        });
                        try {
                          createdLesion =
                              await ref.read(createLesionUseCaseProvider)(
                                patientId: patient.id,
                                anatomicalSite: site.text.trim(),
                                observedAt: observedAt,
                                estimatedDuration: duration.text.trim().isEmpty
                                    ? null
                                    : duration.text.trim(),
                                notes: notes.text.trim().isEmpty
                                    ? null
                                    : notes.text.trim(),
                              );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              submitting = false;
                              submitError = 'No se pudo registrar la lesión.';
                            });
                          }
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
                    : const Text('Crear'),
              ),
            ],
          ),
        ),
      ),
    );
    final lesion = createdLesion;
    if (lesion == null || !mounted) return;
    setState(() => _lesions = [..._lesions, lesion]);
    ref.read(clinicalControllerProvider.notifier).selectLesion(lesion);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesión registrada correctamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinical = ref.watch(clinicalControllerProvider);
    final patient = clinical.patient;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paciente y lesión',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (patient == null) ...[
              TextField(
                controller: _search,
                onSubmitted: (_) => _findPatients(),
                decoration: InputDecoration(
                  labelText: 'Codigo, documento o nombre',
                  suffixIcon: IconButton(
                    onPressed: _findPatients,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              ..._patients.map(
                (item) => ListTile(
                  title: Text(item.fullName),
                  subtitle: _PatientMetadata(patient: item),
                  onTap: () => _choosePatient(item),
                ),
              ),
              if (_searched && _patients.isEmpty && !_loading && _error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No se encontraron pacientes.'),
                ),
              TextButton.icon(
                onPressed: _createPatient,
                icon: const Icon(Icons.person_add),
                label: const Text('Registrar nuevo paciente'),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(patient.fullName),
                subtitle: _PatientMetadata(patient: patient),
                trailing: TextButton(
                  onPressed: () {
                    ref
                        .read(clinicalControllerProvider.notifier)
                        .clearPatientSelection();
                    _requestGeneration++;
                    setState(() {
                      _lesions = const [];
                      _error = null;
                    });
                  },
                  child: const Text('Cambiar'),
                ),
              ),
              if (clinical.lesion != null)
                Container(
                  key: const Key('selectedClinicalContext'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lesión seleccionada',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              clinical.lesion!.anatomicalSite,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(clinicalControllerProvider.notifier)
                            .clearLesionSelection(),
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                ),
              if (clinical.lesion == null)
                ..._lesions.map(
                  (lesion) => ListTile(
                    leading: const Icon(Icons.radio_button_off),
                    title: Text(lesion.anatomicalSite),
                    subtitle: Text(
                      '${lesion.temporalDescription} · ${localizedLesionStatus(lesion.status).label}',
                    ),
                    onTap: () => ref
                        .read(clinicalControllerProvider.notifier)
                        .selectLesion(lesion),
                  ),
                ),
              if (_lesions.isEmpty && !_loading && _error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Este paciente aún no tiene lesiones.'),
                ),
              TextButton.icon(
                onPressed: () => _createLesion(patient),
                icon: const Icon(Icons.add),
                label: const Text('Registrar nueva lesión'),
              ),
            ],
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: patient == null
                        ? _findPatients
                        : () => _choosePatient(patient),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientMetadata extends StatelessWidget {
  final Patient patient;

  const _PatientMetadata({required this.patient});

  @override
  Widget build(BuildContext context) {
    final document = patient.identityDocument?.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          Text('Código clínico: ${patient.clinicalCode}'),
          if (document?.isNotEmpty == true) Text('Documento: $document'),
        ],
      ),
    );
  }
}
