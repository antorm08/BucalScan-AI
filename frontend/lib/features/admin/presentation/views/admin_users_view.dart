import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_approvals_controller.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_users_controller.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class AdminUsersView extends ConsumerStatefulWidget {
  const AdminUsersView({super.key});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(adminApprovalsControllerProvider.notifier).load(),
      ref.read(adminUsersControllerProvider.notifier).fetchUsers(),
    ]);
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _workspaceDecision(
    AdminWorkspaceRequest item,
    bool approve,
  ) async {
    if (!await _confirm(
      approve ? 'Aprobar centro' : 'Rechazar centro',
      '${approve ? 'Aprobar' : 'Rechazar'} ${item.name} y su acceso inicial?',
    )) {
      return;
    }
    final ok = await ref
        .read(adminApprovalsControllerProvider.notifier)
        .decideWorkspace(item.id, approve);
    if (mounted) {
      _result(ok, approve ? 'Centro aprobado.' : 'Centro rechazado.');
    }
  }

  Future<void> _membershipDecision(
    AdminMembershipRequest item,
    bool approve,
  ) async {
    var role = 'professional';
    if (approve) {
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Asignar rol'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'clinic_admin'),
              child: const Text('Administrador de clínica'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'professional'),
              child: const Text('Profesional'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'assistant'),
              child: const Text('Asistente'),
            ),
          ],
        ),
      );
      if (selected == null) return;
      role = selected;
    }
    if (!await _confirm(
      approve ? 'Aprobar acceso' : 'Rechazar acceso',
      '${approve ? 'Aprobar' : 'Rechazar'} la solicitud de ${item.requester.fullName}?',
    )) {
      return;
    }
    final ok = await ref
        .read(adminApprovalsControllerProvider.notifier)
        .decideMembership(item.id, approve, role);
    if (mounted) {
      _result(ok, approve ? 'Acceso aprobado.' : 'Acceso rechazado.');
    }
  }

  Future<void> _toggleUser(AdminUser user) async {
    final verb = user.isActive ? 'suspender' : 'reactivar';
    if (!await _confirm(
      '${user.isActive ? 'Suspender' : 'Reactivar'} usuario',
      '¿Desea $verb a ${user.fullName}?',
    )) {
      return;
    }
    final result = await ref
        .read(adminUsersControllerProvider.notifier)
        .toggleStatus(user);
    if (mounted) {
      _result(
        result != null,
        result?.isActive == true
            ? 'Usuario reactivado.'
            : 'Usuario suspendido.',
      );
    }
  }

  void _result(bool ok, String success) {
    final approvalsError = ref.read(adminApprovalsControllerProvider).error;
    final usersError = ref.read(adminUsersControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? success
              : (approvalsError ??
                        usersError ??
                        'No se pudo completar la acción.')
                    .replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvals = ref.watch(adminApprovalsControllerProvider);
    final users = ref.watch(adminUsersControllerProvider);
    final currentUserId = ref.watch(authViewModelProvider).currentUser?.id;
    final workspaceCount =
        approvals.summary?.pendingWorkspaces ?? approvals.workspaces.length;
    final membershipCount =
        approvals.summary?.pendingMemberships ?? approvals.memberships.length;
    final busy = approvals.isLoading || users.isLoading;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Panel administrativo'),
          actions: [
            IconButton(
              onPressed: busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Centros ($workspaceCount)'),
              Tab(text: 'Accesos ($membershipCount)'),
              Tab(
                text:
                    'Usuarios (${approvals.summary?.totalUsers ?? users.users.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _requestBody(
              loading: approvals.isLoading,
              error: approvals.error,
              empty: approvals.workspaces.isEmpty,
              emptyText: 'No hay centros pendientes. La cola está al día.',
              retry: _refresh,
              list: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: approvals.workspaces.length,
                itemBuilder: (_, index) => _WorkspaceCard(
                  item: approvals.workspaces[index],
                  busy:
                      approvals.decidingKey ==
                      'w${approvals.workspaces[index].id}',
                  decide: (approve) =>
                      _workspaceDecision(approvals.workspaces[index], approve),
                ),
              ),
            ),
            _requestBody(
              loading: approvals.isLoading,
              error: approvals.error,
              empty: approvals.memberships.isEmpty,
              emptyText: 'No hay accesos pendientes. La cola está al día.',
              retry: _refresh,
              list: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: approvals.memberships.length,
                itemBuilder: (_, index) => _MembershipCard(
                  item: approvals.memberships[index],
                  busy:
                      approvals.decidingKey ==
                      'm${approvals.memberships[index].id}',
                  decide: (approve) => _membershipDecision(
                    approvals.memberships[index],
                    approve,
                  ),
                ),
              ),
            ),
            _requestBody(
              loading: users.isLoading,
              error: users.error,
              empty: users.users.isEmpty,
              emptyText: 'No hay usuarios para mostrar.',
              retry: _refresh,
              list: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.users.length,
                itemBuilder: (_, index) {
                  final user = users.users[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          user.isAdmin
                              ? Icons.shield_outlined
                              : Icons.person_outline,
                        ),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(
                        '${user.email}\n${user.profession ?? user.role} · ${user.isActive ? 'Activo' : 'Suspendido'}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: user.id == currentUserId
                            ? 'No puede suspender su propia cuenta'
                            : (user.isActive ? 'Suspender' : 'Reactivar'),
                        onPressed:
                            users.updatingUserId == user.id ||
                                user.id == currentUserId
                            ? null
                            : () => _toggleUser(user),
                        icon: users.updatingUserId == user.id
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                user.isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestBody({
    required bool loading,
    required String? error,
    required bool empty,
    required String emptyText,
    required Future<void> Function() retry,
    required Widget list,
  }) {
    if (loading && empty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && empty) {
      return _Message(
        icon: Icons.error_outline,
        text: error.replaceFirst('Exception: ', ''),
        action: retry,
      );
    }
    if (empty) {
      return _Message(icon: Icons.task_alt, text: emptyText, action: retry);
    }
    return RefreshIndicator(onRefresh: retry, child: list);
  }
}

class _WorkspaceCard extends StatelessWidget {
  final AdminWorkspaceRequest item;
  final bool busy;
  final ValueChanged<bool> decide;
  const _WorkspaceCard({
    required this.item,
    required this.busy,
    required this.decide,
  });

  @override
  Widget build(BuildContext context) => _DecisionCard(
    title: item.name,
    type: item.workspaceType == 'independent'
        ? 'Práctica independiente'
        : item.workspaceType,
    details:
        '${item.requester?.fullName ?? 'Solicitante no disponible'}\n${item.requester?.profession ?? 'Profesión no indicada'} · ${item.requester?.specialty ?? 'Sin especialidad'}\n${item.city ?? 'Ciudad no indicada'}',
    busy: busy,
    decide: decide,
  );
}

class _MembershipCard extends StatelessWidget {
  final AdminMembershipRequest item;
  final bool busy;
  final ValueChanged<bool> decide;
  const _MembershipCard({
    required this.item,
    required this.busy,
    required this.decide,
  });

  @override
  Widget build(BuildContext context) => _DecisionCard(
    title: item.requester.fullName,
    type: item.isIndependent ? 'Profesional independiente' : item.workspaceName,
    details:
        '${item.requester.email}\n${item.requester.profession ?? 'Profesión no indicada'} · ${item.requester.specialty ?? 'Sin especialidad'}',
    busy: busy,
    decide: decide,
  );
}

class _DecisionCard extends StatelessWidget {
  final String title;
  final String type;
  final String details;
  final bool busy;
  final ValueChanged<bool> decide;
  const _DecisionCard({
    required this.title,
    required this.type,
    required this.details,
    required this.busy,
    required this.decide,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Chip(label: Text(type)),
          const SizedBox(height: 6),
          Text(details),
          const SizedBox(height: 14),
          if (busy)
            const LinearProgressIndicator()
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => decide(false),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => decide(true),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Future<void> Function() action;
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    ),
  );
}
