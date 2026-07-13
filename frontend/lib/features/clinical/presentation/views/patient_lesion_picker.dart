import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/di/clinical_providers.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';

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
        if (previousLesion != null &&
            lesions.any((item) => item.id == previousLesion.id)) {
          ref
              .read(clinicalControllerProvider.notifier)
              .selectLesion(previousLesion);
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
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo paciente'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: code,
                decoration: const InputDecoration(
                  labelText: 'Código clínico *',
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Ingrese un código clínico.'
                    : null,
              ),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? 'Ingrese el nombre completo.'
                    : null,
              ),
              TextField(
                controller: document,
                decoration: const InputDecoration(
                  labelText: 'Documento (opcional)',
                ),
              ),
            ],
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (submit != true) return;
    try {
      final patient = await ref.read(createPatientUseCaseProvider)(
        clinicalCode: code.text.trim(),
        fullName: name.text.trim(),
        identityDocument: document.text.trim(),
      );
      if (mounted) await _choosePatient(patient);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo crear el paciente. El código clínico o documento puede estar registrado en este centro.',
        );
      }
    }
  }

  Future<void> _createLesion(Patient patient) async {
    final site = TextEditingController();
    final duration = TextEditingController();
    final notes = TextEditingController();
    DateTime? observedAt;
    final formKey = GlobalKey<FormState>();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva lesión'),
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
                      hintText: 'Ej.: borde lateral de lengua',
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
                      hintText: 'Ej.: aproximadamente 3 semanas',
                      helperText:
                          'Independiente de la fecha de primera observación.',
                    ),
                    validator: (value) =>
                        observedAt == null && value!.trim().isEmpty
                        ? 'Indique una fecha o una duración estimada.'
                        : null,
                  ),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notas longitudinales de la lesión',
                      helperText:
                          'Describen su seguimiento, no los hallazgos de una evaluación puntual.',
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
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (submit != true) return;
    try {
      final lesion = await ref.read(createLesionUseCaseProvider)(
        patientId: patient.id,
        anatomicalSite: site.text.trim(),
        observedAt: observedAt,
        estimatedDuration: duration.text.trim().isEmpty
            ? null
            : duration.text.trim(),
        notes: notes.text.trim(),
      );
      if (!mounted) return;
      setState(() => _lesions = [..._lesions, lesion]);
      ref.read(clinicalControllerProvider.notifier).selectLesion(lesion);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar la lesión.');
    }
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
                  subtitle: Text(item.clinicalCode),
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
                subtitle: Text(patient.clinicalCode),
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
              ..._lesions.map(
                (lesion) => ListTile(
                  leading: Icon(
                    clinical.lesion?.id == lesion.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(lesion.anatomicalSite),
                  subtitle: Text(
                    '${lesion.temporalDescription} · ${lesion.status}',
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
