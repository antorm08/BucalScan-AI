import 'dart:async';

import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/session/user_sensitive_state.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceGateView extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onLoggedOut;

  const WorkspaceGateView({super.key, required this.child, this.onLoggedOut});

  @override
  ConsumerState<WorkspaceGateView> createState() => _WorkspaceGateViewState();
}

class _WorkspaceGateViewState extends ConsumerState<WorkspaceGateView>
    with WidgetsBindingObserver {
  static const _approvalRefreshInterval = Duration(seconds: 12);

  bool _loggingOut = false;
  bool _autoRefreshing = false;
  Timer? _approvalTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
      () => ref.read(clinicalControllerProvider.notifier).loadWorkspaces(),
    );
    _approvalTimer = Timer.periodic(
      _approvalRefreshInterval,
      (_) => unawaited(_autoRefresh()),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _approvalTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await ref.read(clinicalControllerProvider.notifier).loadWorkspaces();
  }

  Future<void> _autoRefresh() async {
    if (!mounted || _autoRefreshing) return;
    final state = ref.read(clinicalControllerProvider);
    if (state.loading || state.activeWorkspace != null) return;
    _autoRefreshing = true;
    try {
      await _refresh();
    } finally {
      _autoRefreshing = false;
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    ref.resetUserSensitiveState();
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const SizedBox.shrink();
    if (user.isAdmin) return widget.child;

    final state = ref.watch(clinicalControllerProvider);
    if (state.activeWorkspace != null) return widget.child;
    final active = state.workspaces.where((item) => item.canEnter).toList();
    final pending = state.workspaces.where((item) => !item.canEnter).toList();
    final gateStatus = _gateStatus(pending);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(onLogout: _logout)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      if (state.loading && state.workspaces.isEmpty)
                        const _LoadingState()
                      else ...[
                        if (state.error != null) ...[
                          _ConnectionStatus(onRetry: _refresh),
                          const SizedBox(height: 20),
                        ] else ...[
                          _StatusPanel(
                            hasAccess: active.isNotEmpty,
                            status: gateStatus,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (active.length > 1) ...[
                          const _SectionTitle(
                            title: 'Elige tu espacio de trabajo',
                            subtitle:
                                'Los pacientes y análisis permanecen separados por centro.',
                          ),
                          const SizedBox(height: 12),
                          ...active.map(
                            (workspace) => _WorkspaceCard(
                              workspace: workspace,
                              onTap: () => ref
                                  .read(clinicalControllerProvider.notifier)
                                  .selectWorkspace(workspace),
                            ),
                          ),
                        ],
                        if (pending.isNotEmpty) ...[
                          _SectionTitle(
                            title: active.isEmpty
                                ? 'Solicitud en revisión'
                                : 'Otros espacios solicitados',
                            subtitle:
                                'Aquí puedes consultar el estado informado por cada centro.',
                          ),
                          const SizedBox(height: 12),
                          ...pending.map(
                            (workspace) => _WorkspaceCard(workspace: workspace),
                          ),
                        ],
                        if (state.workspaces.isEmpty && state.error == null)
                          const _EmptyCard(),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: state.loading ? null : _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            state.loading
                                ? 'Consultando estado...'
                                : 'Actualizar estado',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'El estado se actualiza automáticamente. También puedes deslizar hacia abajo o actualizar manualmente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton.icon(
                          key: const Key('workspaceGateLogoutButton'),
                          onPressed: _loggingOut ? null : _logout,
                          icon: _loggingOut
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.logout_rounded),
                          label: const Text('Cerrar sesión'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onLogout;

  const _Header({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BucalScan AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Acceso clínico seguro',
                  style: TextStyle(color: AppColors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool hasAccess;
  final _GateStatus status;

  const _StatusPanel({required this.hasAccess, required this.status});

  String get _badge => switch (status) {
    _GateStatus.pending => 'APROBACIÓN PENDIENTE',
    _GateStatus.rejected => 'SOLICITUD RECHAZADA',
    _GateStatus.inactive => 'ACCESO INACTIVO',
    _GateStatus.empty => 'SIN ACCESO ASOCIADO',
  };

  String get _title => switch (status) {
    _GateStatus.pending => 'Tu espacio está en revisión',
    _GateStatus.rejected => 'Tu solicitud fue rechazada',
    _GateStatus.inactive => 'Tu acceso está inactivo',
    _GateStatus.empty => 'No tienes espacios disponibles',
  };

  String get _description => switch (status) {
    _GateStatus.pending =>
      'La aprobación confirma tu vínculo profesional antes de habilitar pacientes, historias y análisis.',
    _GateStatus.rejected =>
      'Contacta al administrador del centro si necesitas revisar esta decisión.',
    _GateStatus.inactive =>
      'Un administrador del centro debe reactivar tu membresía para continuar.',
    _GateStatus.empty =>
      'Solicita acceso a un centro clínico para comenzar a trabajar.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: hasAccess ? AppColors.benignBg : AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasAccess ? Icons.domain_verification_outlined : Icons.schedule,
            size: 44,
            color: hasAccess ? AppColors.benignText : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasAccess ? AppColors.benignBg : AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            hasAccess ? 'ACCESO DISPONIBLE' : _badge,
            style: TextStyle(
              color: hasAccess ? AppColors.benignText : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasAccess ? 'Selecciona dónde atenderás' : _title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasAccess
              ? 'El acceso activo protege el contexto clínico de cada institución.'
              : _description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final ClinicalWorkspace workspace;
  final VoidCallback? onTap;

  const _WorkspaceCard({required this.workspace, this.onTap});

  String get _typeLabel => switch (workspace.type) {
    'independent' => 'Consultorio independiente',
    'hospital' => 'Hospital',
    'clinic' => 'Centro clínico',
    _ => 'Espacio clínico',
  };

  String get _statusLabel {
    if (workspace.canEnter) return 'Activo';
    if (workspace.status == 'rejected') return 'Centro rechazado';
    if (workspace.status == 'inactive') return 'Centro inactivo';
    if (workspace.type == 'independent') {
      return 'Aprobación profesional pendiente';
    }
    if (workspace.status == 'pending') {
      return 'Centro pendiente de aprobación';
    }
    if (workspace.membershipStatus == MembershipStatus.rejected) {
      return 'Membresía rechazada';
    }
    if (workspace.membershipStatus == MembershipStatus.inactive) {
      return 'Membresía inactiva';
    }
    return 'Aprobación de membresía pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final active = workspace.canEnter;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.benignBg
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    workspace.type == 'independent'
                        ? Icons.person_pin_circle_outlined
                        : Icons.local_hospital_outlined,
                    color: active ? AppColors.benignText : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _typeLabel,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          color: active
                              ? AppColors.benignText
                              : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _GateStatus { pending, rejected, inactive, empty }

_GateStatus _gateStatus(List<ClinicalWorkspace> workspaces) {
  if (workspaces.any(
    (item) =>
        item.status == 'pending' ||
        item.membershipStatus == MembershipStatus.pending,
  )) {
    return _GateStatus.pending;
  }
  if (workspaces.any(
    (item) =>
        item.status == 'rejected' ||
        item.membershipStatus == MembershipStatus.rejected,
  )) {
    return _GateStatus.rejected;
  }
  if (workspaces.any(
    (item) =>
        item.status == 'inactive' ||
        item.membershipStatus == MembershipStatus.inactive,
  )) {
    return _GateStatus.inactive;
  }
  return _GateStatus.empty;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text('Consultando tus espacios clínicos...'),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.error),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No pudimos actualizar el estado. Revisa tu conexión e inténtalo nuevamente.',
              style: TextStyle(color: AppColors.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ConnectionStatus({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.cloud_off_outlined, size: 58, color: AppColors.error),
      const SizedBox(height: 14),
      const Text(
        'No pudimos consultar tus espacios',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      _ErrorCard(onRetry: onRetry),
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.domain_disabled_outlined, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Aún no hay espacios asociados',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Si acabas de registrarte, espera unos minutos y actualiza. También puedes cerrar sesión de forma segura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
