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
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Codigo clinico *'),
            ),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre completo *'),
            ),
            TextField(
              controller: document,
              decoration: const InputDecoration(
                labelText: 'Documento (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (submit != true ||
        code.text.trim().isEmpty ||
        name.text.trim().isEmpty) {
      return;
    }
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
              'No se pudo crear el paciente. Revisa si el código o documento ya existe.',
        );
      }
    }
  }

  Future<void> _createLesion(Patient patient) async {
    final site = TextEditingController();
    final temporal = TextEditingController();
    final notes = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva lesion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: site,
              decoration: const InputDecoration(labelText: 'Sitio anatomico *'),
            ),
            TextField(
              controller: temporal,
              decoration: const InputDecoration(
                labelText: 'Fecha inicial o duracion *',
              ),
            ),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notas clinicas'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (submit != true ||
        site.text.trim().isEmpty ||
        temporal.text.trim().isEmpty) {
      return;
    }
    try {
      final lesion = await ref.read(createLesionUseCaseProvider)(
        patientId: patient.id,
        anatomicalSite: site.text.trim(),
        temporalDescription: temporal.text.trim(),
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
              'Paciente y lesion',
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
                label: const Text('Registrar nueva lesion'),
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
