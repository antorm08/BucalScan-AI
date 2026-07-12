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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _findPatients() async {
    setState(() => _loading = true);
    try {
      final patients = await ref
          .read(clinicalRepositoryProvider)
          .searchPatients(_search.text.trim());
      if (mounted) {
        setState(() => _patients = patients);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _choosePatient(Patient patient) async {
    ref.read(clinicalControllerProvider.notifier).selectPatient(patient);
    setState(() => _loading = true);
    final lesions = await ref
        .read(clinicalRepositoryProvider)
        .getLesions(patient.id);
    if (mounted) {
      setState(() {
        _lesions = lesions;
        _loading = false;
      });
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
    final patient = await ref
        .read(clinicalRepositoryProvider)
        .createPatient(
          clinicalCode: code.text.trim(),
          fullName: name.text.trim(),
          identityDocument: document.text.trim(),
        );
    await _choosePatient(patient);
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
    final lesion = await ref
        .read(clinicalRepositoryProvider)
        .createLesion(
          patientId: patient.id,
          anatomicalSite: site.text.trim(),
          temporalDescription: temporal.text.trim(),
          notes: notes.text.trim(),
        );
    ref.read(clinicalControllerProvider.notifier).selectLesion(lesion);
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
                  onPressed: () => ref.invalidate(clinicalControllerProvider),
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
              TextButton.icon(
                onPressed: () => _createLesion(patient),
                icon: const Icon(Icons.add),
                label: const Text('Registrar nueva lesion'),
              ),
            ],
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
