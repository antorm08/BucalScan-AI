import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patient_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientsView extends ConsumerStatefulWidget {
  final void Function(Patient, OralLesion) onRepeatAnalysis;

  const PatientsView({super.key, required this.onRepeatAnalysis});

  @override
  ConsumerState<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends ConsumerState<PatientsView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(patientFollowUpControllerProvider.notifier).searchPatients(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Patient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailView(
          patientId: patient.id,
          onRepeatAnalysis: widget.onRepeatAnalysis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientFollowUpControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Pacientes'),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(patientFollowUpControllerProvider.notifier)
            .searchPatients(_search.text.trim()),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Seguimiento longitudinal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Busca por código clínico, documento o nombre.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('patientsSearchField'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => ref
                  .read(patientFollowUpControllerProvider.notifier)
                  .searchPatients(value.trim()),
              decoration: InputDecoration(
                labelText: 'Buscar pacientes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => ref
                      .read(patientFollowUpControllerProvider.notifier)
                      .searchPatients(_search.text.trim()),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (state.status == FollowUpStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.status == FollowUpStatus.error)
              _Message(
                icon: Icons.cloud_off_outlined,
                text: state.error ?? 'No se pudieron cargar los pacientes.',
                action: 'Reintentar',
                onPressed: () => ref
                    .read(patientFollowUpControllerProvider.notifier)
                    .searchPatients(_search.text.trim()),
              )
            else if (state.status == FollowUpStatus.empty)
              const _Message(
                icon: Icons.person_search_outlined,
                text: 'No se encontraron pacientes en este espacio.',
              )
            else
              ...state.patients.map(
                (patient) => Card(
                  child: ListTile(
                    key: Key('patient-${patient.id}'),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(patient.fullName),
                    subtitle: Text(
                      '${patient.clinicalCode}${patient.identityDocument == null ? '' : ' · ${patient.identityDocument}'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(patient),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onPressed;

  const _Message({
    required this.icon,
    required this.text,
    this.action,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    ),
  );
}
