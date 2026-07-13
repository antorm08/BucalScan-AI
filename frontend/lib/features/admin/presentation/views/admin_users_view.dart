import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_approvals_controller.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_users_controller.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersView extends ConsumerStatefulWidget {
  final VoidCallback? onLoggedOut;

  const AdminUsersView({super.key, this.onLoggedOut});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  @override
  void initState() {
    super.initState();
    if (ref.read(authViewModelProvider).currentUser?.isAdmin == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() => Future.wait([
    ref.read(adminApprovalsControllerProvider.notifier).load(),
    ref.read(adminUsersControllerProvider.notifier).fetchUsers(),
  ]);

  Future<void> _logout() async {
    final confirmed = await _confirm(
      'Cerrar sesión',
      '¿Deseas salir del panel administrativo?',
    );
    if (!confirmed || !mounted) return;
    await ref.read(authViewModelProvider.notifier).logout();
    if (!mounted) return;
    if (widget.onLoggedOut != null) {
      widget.onLoggedOut!();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
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
    if (approve && item.requester.isSuspended) {
      return;
    }
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
      if (selected == null) {
        return;
      }
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
    final activate = !user.isActive;
    if (!await _confirm(
      '${activate ? 'Reactivar' : 'Suspender'} usuario',
      '¿Desea ${activate ? 'reactivar' : 'suspender'} a ${user.fullName}?',
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
    final error =
        ref.read(adminApprovalsControllerProvider).error ??
        ref.read(adminUsersControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? success
              : (error ?? 'No se pudo completar la acción.').replaceFirst(
                  'Exception: ',
                  '',
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authViewModelProvider).currentUser?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('No tienes acceso a esta sección.')),
      );
    }
    final approvals = ref.watch(adminApprovalsControllerProvider);
    final users = ref.watch(adminUsersControllerProvider);
    final currentUserId = ref.watch(authViewModelProvider).currentUser?.id;
    final workspaceCount =
        approvals.summary?.pendingWorkspaces ?? approvals.workspaces.length;
    final membershipCount =
        approvals.summary?.pendingMemberships ?? approvals.memberships.length;
    final userCount = approvals.summary?.totalUsers ?? users.users.length;
    final busy = approvals.isLoading || users.isLoading;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          titleSpacing: 16,
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, size: 25),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BucalScan AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Administración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: busy ? null : _refresh,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar datos',
            ),
            IconButton(
              onPressed: busy ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: AppColors.surfaceContainerLowest,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  _TabLabel(label: 'Centros', count: workspaceCount),
                  _TabLabel(label: 'Accesos', count: membershipCount),
                  _TabLabel(label: 'Usuarios', count: userCount),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _body(
              loading: approvals.isLoading,
              error: approvals.error,
              empty: approvals.workspaces.isEmpty,
              emptyText: 'No hay centros pendientes.\nLa cola está al día.',
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                itemCount: approvals.workspaces.length,
                itemBuilder: (_, i) => _WorkspaceCard(
                  item: approvals.workspaces[i],
                  busy:
                      approvals.decidingKey == 'w${approvals.workspaces[i].id}',
                  decide: (value) =>
                      _workspaceDecision(approvals.workspaces[i], value),
                ),
              ),
            ),
            _body(
              loading: approvals.isLoading,
              error: approvals.error,
              empty: approvals.memberships.isEmpty,
              emptyText: 'No hay accesos pendientes.\nLa cola está al día.',
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                itemCount: approvals.memberships.length,
                itemBuilder: (_, i) => _MembershipCard(
                  item: approvals.memberships[i],
                  busy:
                      approvals.decidingKey ==
                      'm${approvals.memberships[i].id}',
                  decide: (value) =>
                      _membershipDecision(approvals.memberships[i], value),
                ),
              ),
            ),
            _body(
              loading: users.isLoading,
              error: users.error,
              empty: users.users.isEmpty,
              emptyText: 'No hay usuarios para mostrar.',
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                itemCount: users.users.length,
                itemBuilder: (_, i) {
                  final user = users.users[i];
                  return _UserCard(
                    user: user,
                    isCurrent: user.id == currentUserId,
                    busy: users.updatingUserId == user.id,
                    toggle: user.canToggleStatus
                        ? () => _toggleUser(user)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body({
    required bool loading,
    required String? error,
    required bool empty,
    required String emptyText,
    required Widget child,
  }) {
    if (loading && empty) return const _LoadingState();
    if (error != null && empty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: error.replaceFirst('Exception: ', ''),
        action: _refresh,
      );
    }
    if (empty) {
      return _Message(
        icon: Icons.task_alt_rounded,
        text: emptyText,
        action: _refresh,
      );
    }
    return RefreshIndicator(onRefresh: _refresh, child: child);
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Tab(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.item,
    required this.busy,
    required this.decide,
  });
  final AdminWorkspaceRequest item;
  final bool busy;
  final ValueChanged<bool> decide;

  @override
  Widget build(BuildContext context) => _DecisionCard(
    icon: Icons.domain_outlined,
    title: item.name,
    type: _workspaceType(item.workspaceType),
    status: _status(item.status),
    fields: [
      _Field('Solicitante', item.requester?.fullName ?? 'No disponible'),
      _Field('Profesión', item.requester?.profession ?? 'No indicada'),
      _Field('Especialidad', item.requester?.specialty ?? 'No indicada'),
      _Field('Email', item.requester?.email ?? 'No disponible'),
      _Field('Ciudad', item.city ?? 'No indicada'),
    ],
    busy: busy,
    decide: decide,
  );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.item,
    required this.busy,
    required this.decide,
  });
  final AdminMembershipRequest item;
  final bool busy;
  final ValueChanged<bool> decide;

  @override
  Widget build(BuildContext context) => _DecisionCard(
    icon: Icons.badge_outlined,
    title: item.requester.fullName,
    type: item.isIndependent ? 'Profesional independiente' : 'Acceso a centro',
    status: _status(item.status),
    warning: item.requester.isSuspended
        ? 'Usuario suspendido. Reactiva su cuenta antes de aprobar.'
        : null,
    fields: [
      _Field('Profesión', item.requester.profession ?? 'No indicada'),
      _Field('Especialidad', item.requester.specialty ?? 'No indicada'),
      _Field('Email', item.requester.email),
      _Field('Espacio de trabajo', item.workspaceName),
    ],
    busy: busy,
    approvalEnabled: !item.requester.isSuspended,
    decide: decide,
  );
}

class _Field {
  const _Field(this.label, this.value);
  final String label;
  final String value;
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.icon,
    required this.title,
    required this.type,
    required this.status,
    required this.fields,
    required this.busy,
    required this.decide,
    this.warning,
    this.approvalEnabled = true,
  });
  final IconData icon;
  final String title;
  final String type;
  final String status;
  final List<_Field> fields;
  final bool busy;
  final String? warning;
  final bool approvalEnabled;
  final ValueChanged<bool> decide;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: AppColors.surfaceContainerLowest,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryFixed,
                foregroundColor: AppColors.primary,
                child: Icon(icon, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(text: type),
                        _Pill(text: status, accent: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 98,
                    child: Text(
                      field.label,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      field.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      warning!,
                      style: const TextStyle(
                        color: AppColors.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 9),
          if (busy)
            const LinearProgressIndicator(minHeight: 3)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => decide(false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Rechazar'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: approvalEnabled ? () => decide(true) : null,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Aprobar'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isCurrent,
    required this.busy,
    required this.toggle,
  });
  final AdminUser user;
  final bool isCurrent;
  final bool busy;
  final VoidCallback? toggle;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryFixed,
                foregroundColor: AppColors.primary,
                child: Icon(
                  user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _StatusPill(status: user.lifecycleStatus),
            ],
          ),
          const SizedBox(height: 10),
          _UserLine(label: 'Rol', value: _role(user.role)),
          _UserLine(
            label: 'Profesión',
            value: user.profession ?? 'No indicada',
          ),
          _UserLine(label: 'Email', value: user.email),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: isCurrent
                ? const _Pill(text: 'Tu cuenta', accent: true)
                : user.canToggleStatus
                ? OutlinedButton.icon(
                    onPressed: busy ? null : toggle,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            user.isActive
                                ? Icons.block_outlined
                                : Icons.restart_alt_rounded,
                            size: 18,
                          ),
                    label: Text(user.isActive ? 'Suspender' : 'Reactivar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.isActive
                          ? AppColors.error
                          : AppColors.benignText,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  );
}

class _UserLine extends StatelessWidget {
  const _UserLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final AdminUserStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: status == AdminUserStatus.active
          ? AppColors.benignBg
          : status == AdminUserStatus.pending
          ? AppColors.primaryFixed
          : AppColors.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      switch (status) {
        AdminUserStatus.active => 'Activo',
        AdminUserStatus.pending => 'Pendiente de verificación',
        AdminUserStatus.suspended => 'Suspendido',
        AdminUserStatus.unknown => 'Estado desconocido',
      },
      style: TextStyle(
        color: status == AdminUserStatus.active
            ? AppColors.benignText
            : status == AdminUserStatus.pending
            ? AppColors.primary
            : AppColors.onErrorContainer,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: accent ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: accent ? AppColors.primary : AppColors.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 14),
        Text('Cargando información...'),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
  });
  final IconData icon;
  final String text;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    ),
  );
}

String _workspaceType(String value) => switch (value) {
  'independent' => 'Práctica independiente',
  'clinic' => 'Clínica',
  'hospital' => 'Hospital',
  _ => value.isEmpty ? 'Centro clínico' : value,
};

String _status(String value) => switch (value) {
  'pending' => 'Pendiente',
  'active' => 'Activo',
  'rejected' => 'Rechazado',
  'inactive' => 'Inactivo',
  'suspended' => 'Suspendido',
  _ => value,
};

String _role(String value) => switch (value) {
  'platform_admin' || 'admin' => 'Administrador de plataforma',
  'clinic_admin' => 'Administrador de clínica',
  'professional' => 'Profesional',
  'assistant' => 'Asistente',
  _ => value,
};
