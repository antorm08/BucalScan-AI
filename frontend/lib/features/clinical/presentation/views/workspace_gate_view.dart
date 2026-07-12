import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';

class WorkspaceGateView extends ConsumerStatefulWidget {
  final Widget child;
  const WorkspaceGateView({super.key, required this.child});

  @override
  ConsumerState<WorkspaceGateView> createState() => _WorkspaceGateViewState();
}

class _WorkspaceGateViewState extends ConsumerState<WorkspaceGateView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(clinicalControllerProvider.notifier).loadWorkspaces(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicalControllerProvider);
    if (state.activeWorkspace != null) return widget.child;
    return Scaffold(
      appBar: AppBar(title: const Text('Espacio de trabajo')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(clinicalControllerProvider.notifier)
                  .loadWorkspaces(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Seleccione donde atendera hoy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los pacientes, lesiones e historial se mantienen separados por espacio clinico.',
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (state.workspaces.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay membresias disponibles. Si acaba de registrarse, su clinica o aprobacion profesional puede estar pendiente.',
                        ),
                      ),
                    ),
                  ...state.workspaces.map(
                    (workspace) => _WorkspaceTile(
                      workspace: workspace,
                      onTap: workspace.canEnter
                          ? () => ref
                                .read(clinicalControllerProvider.notifier)
                                .selectWorkspace(workspace)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _WorkspaceTile extends StatelessWidget {
  final ClinicalWorkspace workspace;
  final VoidCallback? onTap;
  const _WorkspaceTile({required this.workspace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pending = !workspace.canEnter;
    return Card(
      child: ListTile(
        leading: Icon(
          workspace.type == 'independent'
              ? Icons.person_pin_circle_outlined
              : Icons.local_hospital_outlined,
        ),
        title: Text(workspace.name),
        subtitle: Text(
          pending
              ? workspace.status == 'pending'
                    ? 'Clinica pendiente de aprobacion'
                    : 'Aprobacion profesional pendiente'
              : '${workspace.role ?? 'professional'} · Activo',
        ),
        trailing: pending
            ? const Chip(label: Text('Pendiente'))
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
