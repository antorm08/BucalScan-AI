import 'dart:async';

import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_query.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_request.dart';
import 'package:bucalscan_ai/features/admin/domain/entities/admin_user.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_list_controllers.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/presentation/localized_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _accessDisclaimer =
    'La aprobación habilita únicamente el acceso a la aplicación. No verifica identidad, documentos, título, licencia, profesión, especialidad, credenciales ni competencia clínica.';
const _allFilterValue = '__all__';

class AdminCentersView extends ConsumerWidget {
  const AdminCentersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCentersControllerProvider);
    return _AdminList<AdminWorkspaceRequest>(
      storageKey: 'admin-centers-list',
      state: state,
      searchHint: 'Buscar centro, ciudad, ID o solicitante',
      statuses: const ['pending', 'active', 'rejected'],
      types: const [
        'clinic',
        'consultorio',
        'hospital',
        'university',
        'campaign',
      ],
      sorts: const {
        'created_at:desc': 'Más recientes',
        'created_at:asc': 'Más antiguos',
        'name:asc': 'Nombre A-Z',
      },
      onQuery: ref.read(adminCentersControllerProvider.notifier).changeQuery,
      onRefresh: ref.read(adminCentersControllerProvider.notifier).refresh,
      onLoadMore: ref.read(adminCentersControllerProvider.notifier).loadMore,
      card: (item) => _ResourceCard(
        icon: Icons.domain_outlined,
        title: item.name,
        subtitle:
            '${_workspaceType(item.workspaceType)} · ${item.city ?? 'Ciudad no indicada'}',
        status: item.status,
        onTap: () => _showAdminSheet(context, _CenterDetail(item: item)),
      ),
    );
  }
}

class AdminAccessView extends ConsumerWidget {
  const AdminAccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAccessControllerProvider);
    return _AdminList<AdminMembershipRequest>(
      storageKey: 'admin-access-list',
      state: state,
      searchHint: 'Buscar profesional, correo, ID o centro',
      statuses: const ['pending', 'active', 'rejected', 'inactive'],
      types: const [
        'independent',
        'clinic',
        'consultorio',
        'hospital',
        'university',
        'campaign',
      ],
      roles: const ['clinic_admin', 'professional', 'assistant'],
      sorts: const {
        'created_at:desc': 'Más recientes',
        'created_at:asc': 'Más antiguos',
        'status:asc': 'Estado',
      },
      onQuery: ref.read(adminAccessControllerProvider.notifier).changeQuery,
      onRefresh: ref.read(adminAccessControllerProvider.notifier).refresh,
      onLoadMore: ref.read(adminAccessControllerProvider.notifier).loadMore,
      card: (item) => _ResourceCard(
        icon: Icons.badge_outlined,
        title: item.requester.fullName,
        subtitle: '${item.workspaceName} · ${_role(item.role)}',
        status: item.status,
        warning: item.requester.isSuspended ? 'Solicitante suspendido' : null,
        onTap: () => _showAdminSheet(context, _AccessDetail(item: item)),
      ),
    );
  }
}

class AdminUsersDestinationView extends ConsumerWidget {
  const AdminUsersDestinationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersPageControllerProvider);
    return _AdminList<AdminUser>(
      storageKey: 'admin-users-list',
      state: state,
      searchHint: 'Buscar nombre, correo, ID o profesión',
      statuses: const ['pending', 'active', 'suspended'],
      roles: const ['platform_admin', 'professional', 'admin', 'doctor'],
      sorts: const {
        'created_at:desc': 'Más recientes',
        'created_at:asc': 'Más antiguos',
        'full_name:asc': 'Nombre A-Z',
      },
      onQuery: ref.read(adminUsersPageControllerProvider.notifier).changeQuery,
      onRefresh: ref.read(adminUsersPageControllerProvider.notifier).refresh,
      onLoadMore: ref.read(adminUsersPageControllerProvider.notifier).loadMore,
      card: (user) => _ResourceCard(
        icon: user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
        title: user.fullName,
        subtitle: '${_role(user.role)} · ${user.email}',
        status: user.status,
        onTap: () => _showAdminSheet(context, _UserDetail(user: user)),
      ),
    );
  }
}

class _AdminList<T> extends StatefulWidget {
  final String storageKey;
  final AdminListState<T> state;
  final String searchHint;
  final List<String> statuses;
  final List<String> types;
  final List<String> roles;
  final Map<String, String> sorts;
  final ValueChanged<AdminQuery> onQuery;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Widget Function(T) card;

  const _AdminList({
    required this.storageKey,
    required this.state,
    required this.searchHint,
    this.statuses = const [],
    this.types = const [],
    this.roles = const [],
    required this.sorts,
    required this.onQuery,
    required this.onRefresh,
    required this.onLoadMore,
    required this.card,
  });

  @override
  State<_AdminList<T>> createState() => _AdminListState<T>();
}

class _AdminListState<T> extends State<_AdminList<T>> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.state.query.search);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => widget.onQuery(widget.state.query.copyWith(search: value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      children: [
        Material(
          color: AppColors.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: _searchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              _search.clear();
                              widget.onQuery(state.query.copyWith(search: ''));
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterMenu(
                        label: 'Estado',
                        value: state.query.status,
                        values: widget.statuses,
                        labelFor: _status,
                        onChanged: (value) => widget.onQuery(
                          state.query.copyWith(
                            status: value,
                            clearStatus: value == null,
                          ),
                        ),
                      ),
                      if (widget.types.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _FilterMenu(
                          label: 'Tipo',
                          value: state.query.type,
                          values: widget.types,
                          labelFor: _workspaceType,
                          onChanged: (value) => widget.onQuery(
                            state.query.copyWith(
                              type: value,
                              clearType: value == null,
                            ),
                          ),
                        ),
                      ],
                      if (widget.roles.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _FilterMenu(
                          label: 'Rol',
                          value: state.query.role,
                          values: widget.roles,
                          labelFor: _role,
                          onChanged: (value) => widget.onQuery(
                            state.query.copyWith(
                              role: value,
                              clearRole: value == null,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Ordenar resultados',
                        onSelected: (value) {
                          final parts = value.split(':');
                          widget.onQuery(
                            state.query.copyWith(
                              sortBy: parts.first,
                              sortDirection: parts.last,
                            ),
                          );
                        },
                        itemBuilder: (_) => widget.sorts.entries
                            .map(
                              (entry) => PopupMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        child: _ControlChip(
                          icon: Icons.sort,
                          label:
                              widget
                                  .sorts['${state.query.sortBy}:${state.query.sortDirection}'] ??
                              'Ordenar',
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      '${state.total} resultados',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.loading && state.items.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _body(state)),
      ],
    );
  }

  Widget _body(AdminListState<T> state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _ListMessage(
        icon: Icons.cloud_off_outlined,
        title: 'No se pudieron cargar los datos',
        detail: _cleanError(state.error!),
        onRetry: widget.onRefresh,
      );
    }
    if (state.items.isEmpty) {
      return _ListMessage(
        icon: Icons.search_off_outlined,
        title: state.query.search.isEmpty
            ? 'No hay registros para mostrar'
            : 'No hay coincidencias',
        detail: 'Prueba otra búsqueda o ajusta los filtros.',
        onRetry: widget.onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        key: PageStorageKey(widget.storageKey),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
        itemCount: state.items.length + (state.hasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return widget.card(state.items[index]);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              onPressed: state.loadingMore ? null : widget.onLoadMore,
              icon: state.loadingMore
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(state.loadingMore ? 'Cargando...' : 'Cargar más'),
            ),
          );
        },
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final String Function(String) labelFor;
  final ValueChanged<String?> onChanged;

  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Filtrar por $label',
    onSelected: (selected) {
      final nextValue = selected == _allFilterValue ? null : selected;
      if (nextValue != value) onChanged(nextValue);
    },
    itemBuilder: (_) => [
      PopupMenuItem(
        value: _allFilterValue,
        child: Text(_allFilterLabel(label)),
      ),
      ...values.map(
        (item) => PopupMenuItem(value: item, child: Text(labelFor(item))),
      ),
    ],
    child: _ControlChip(
      icon: Icons.filter_alt_outlined,
      label: value == null ? label : labelFor(value!),
      active: value != null,
    ),
  );
}

String _allFilterLabel(String label) => switch (label) {
  'Estado' => 'Todos los estados',
  'Tipo' => 'Todos los tipos',
  'Rol' => 'Todos los roles',
  _ => 'Todos',
};

class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _ControlChip({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 44),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: active ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
      border: Border.all(color: AppColors.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label),
        const SizedBox(width: 3),
        const Icon(Icons.arrow_drop_down, size: 18),
      ],
    ),
  );
}

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String? warning;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.warning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    elevation: 0,
    color: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryFixed,
              foregroundColor: AppColors.primary,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (warning != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      warning!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _CenterDetail extends ConsumerWidget {
  final AdminWorkspaceRequest item;

  const _CenterDetail({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _DetailLayout(
    title: item.name,
    status: item.status,
    sections: [
      _DetailSection('Centro', [
        _Field('Tipo', _workspaceType(item.workspaceType)),
        _Field('Ciudad', item.city),
        _Field('Dirección', item.address),
        _Field('Identificación tributaria', item.taxIdentifier),
        _Field('Teléfono', item.telephone),
        _Field('Correo institucional', item.institutionalEmail),
      ]),
      _requesterSection(item.requester),
      _DetailSection('Fechas y resolución', [
        _Field('Solicitud', _date(item.createdAt)),
        _Field('Última actualización', _date(item.updatedAt)),
        _Field('Resolución', _date(item.approvedAt)),
        _Field('Resuelto por', item.approvedBy?.fullName),
      ]),
    ],
    disclaimer: item.status == 'pending' ? _accessDisclaimer : null,
    actions: item.status == 'pending'
        ? _DecisionActions(
            busy: ref.watch(adminCentersControllerProvider).actingId == item.id,
            canApprove: item.requester?.isSuspended != true,
            onApprove: () => _decideCenter(context, ref, item, true),
            onReject: () => _decideCenter(context, ref, item, false),
          )
        : null,
  );
}

class _AccessDetail extends ConsumerWidget {
  final AdminMembershipRequest item;

  const _AccessDetail({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _DetailLayout(
    title: item.requester.fullName,
    status: item.status,
    sections: [
      _requesterSection(item.requester),
      _DetailSection('Acceso solicitado', [
        _Field('Centro', item.workspaceName),
        _Field('Tipo', _workspaceType(item.workspaceType)),
        _Field('Ciudad', item.workspaceCity),
        _Field('Rol solicitado', _role(item.role)),
        _Field('Solicitud', _date(item.createdAt)),
        _Field('Última actualización', _date(item.updatedAt)),
        _Field('Resolución', _date(item.approvedAt)),
        _Field('Resuelto por', item.approvedBy?.fullName),
      ]),
    ],
    warning: item.requester.isSuspended
        ? 'La cuenta del solicitante está suspendida. No puede aprobarse este acceso.'
        : null,
    disclaimer: _accessDisclaimer,
    actions: item.status == 'pending'
        ? _DecisionActions(
            busy: ref.watch(adminAccessControllerProvider).actingId == item.id,
            canApprove: !item.requester.isSuspended,
            onApprove: () => _decideAccess(context, ref, item, true),
            onReject: () => _decideAccess(context, ref, item, false),
          )
        : null,
  );
}

class _UserDetail extends ConsumerWidget {
  final AdminUser user;

  const _UserDetail({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(authViewModelProvider).currentUser?.id;
    return _DetailLayout(
      title: user.fullName,
      status: user.status,
      sections: [
        _DetailSection('Cuenta y perfil', [
          _Field('Correo', user.email),
          _Field('ID profesional declarado', user.doctorId),
          _Field('Profesión declarada', user.profession),
          _Field('Especialidad declarada', user.specialty),
          _Field('Centro declarado', user.medicalCenter),
          _Field('Rol de plataforma', _role(user.role)),
          _Field('Cuenta creada', _date(user.createdAt)),
        ]),
        ...user.memberships.map(
          (membership) =>
              _DetailSection('Membresía · ${membership.workspaceName}', [
                _Field('Tipo', _workspaceType(membership.workspaceType)),
                _Field('Rol', _role(membership.role)),
                _Field('Estado', _status(membership.status)),
                _Field('Creada', _date(membership.createdAt)),
                _Field('Actualizada', _date(membership.updatedAt)),
                _Field('Aprobada', _date(membership.approvedAt)),
              ]),
        ),
      ],
      actions: user.canToggleStatus && user.id != currentId
          ? _UserAction(
              busy:
                  ref.watch(adminUsersPageControllerProvider).actingId ==
                  user.id,
              label: user.isActive ? 'Suspender cuenta' : 'Reactivar cuenta',
              destructive: user.isActive,
              onPressed: () => _toggleUser(context, ref, user),
            )
          : null,
    );
  }
}

class _DetailLayout extends StatelessWidget {
  final String title;
  final String status;
  final List<_DetailSection> sections;
  final String? warning;
  final String? disclaimer;
  final Widget? actions;

  const _DetailLayout({
    required this.title,
    required this.status,
    required this.sections,
    this.warning,
    this.disclaimer,
    this.actions,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: CustomScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _StatusBadge(status),
                    ],
                  ),
                  if (warning != null) ...[
                    const SizedBox(height: 14),
                    _Notice(text: warning!, error: true),
                  ],
                  ...sections,
                  if (disclaimer != null) ...[
                    const SizedBox(height: 12),
                    _Notice(text: disclaimer!),
                  ],
                  if (actions != null) ...[
                    const SizedBox(height: 20),
                    actions!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_Field> fields;

  const _DetailSection(this.title, this.fields);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const Divider(height: 18),
        ...fields.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  field.value?.trim().isNotEmpty == true
                      ? field.value!
                      : 'No disponible',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Field {
  final String label;
  final String? value;
  const _Field(this.label, this.value);
}

_DetailSection _requesterSection(AdminRequester? requester) =>
    _DetailSection('Solicitante', [
      _Field('Nombre', requester?.fullName),
      _Field('Correo', requester?.email),
      _Field('ID profesional declarado', requester?.doctorId),
      _Field('Profesión declarada', requester?.profession),
      _Field('Especialidad declarada', requester?.specialty),
      _Field(
        'Estado de cuenta',
        requester == null ? null : _status(requester.status),
      ),
      _Field('Cuenta creada', _date(requester?.createdAt)),
    ]);

class _DecisionActions extends StatelessWidget {
  final bool busy;
  final bool canApprove;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DecisionActions({
    required this.busy,
    required this.canApprove,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final buttons = [
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('rejectAdminAction'),
            onPressed: busy ? null : onReject,
            icon: const Icon(Icons.close),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: busy || !canApprove ? null : onApprove,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Aprobar'),
          ),
        ),
      ];
      if (constraints.maxWidth < 340) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [buttons.first, const SizedBox(height: 10), buttons.last],
        );
      }
      return Row(
        children: [
          Expanded(child: buttons.first),
          const SizedBox(width: 12),
          Expanded(child: buttons.last),
        ],
      );
    },
  );
}

class _UserAction extends StatelessWidget {
  final bool busy;
  final String label;
  final bool destructive;
  final VoidCallback onPressed;

  const _UserAction({
    required this.busy,
    required this.label,
    required this.destructive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(destructive ? Icons.block_outlined : Icons.restart_alt),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: destructive ? AppColors.error : AppColors.benignText,
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final bool error;
  const _Notice({required this.text, this.error = false});

  @override
  Widget build(BuildContext context) => Semantics(
    label: text,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? AppColors.errorContainer : AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.warning_amber : Icons.info_outline,
            color: error ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final active = normalized == 'active';
    final pending = normalized == 'pending';
    final rejected = normalized == 'rejected' || normalized == 'suspended';
    final background = active
        ? AppColors.benignBg
        : pending
        ? AppColors.primaryFixed
        : rejected
        ? AppColors.errorContainer
        : AppColors.surfaceContainerLow;
    final foreground = active
        ? AppColors.benignText
        : pending
        ? AppColors.primary
        : rejected
        ? AppColors.onErrorContainer
        : AppColors.onSurfaceVariant;
    return Semantics(
      label: 'Estado: ${_status(status)}',
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _status(status),
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function() onRetry;

  const _ListMessage({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showAdminSheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.94,
        minChildSize: 0.6,
        maxChildSize: 0.98,
        builder: (context, controller) =>
            PrimaryScrollController(controller: controller, child: child),
      ),
    );

Future<void> _decideCenter(
  BuildContext context,
  WidgetRef ref,
  AdminWorkspaceRequest item,
  bool approve,
) async {
  if (!await _confirmDecision(
    context,
    title: approve ? 'Aprobar centro' : 'Rechazar centro',
    message:
        '${approve ? 'Aprobar' : 'Rechazar'} ${item.name} y su acceso inicial.',
    destructive: !approve,
  )) {
    return;
  }
  final authGeneration = ref.read(authViewModelProvider).generation;
  final ok = await runAdminAction(
    controller: ref.read(adminCentersControllerProvider.notifier),
    id: item.id,
    action: () => ref
        .read(adminRepositoryProvider)
        .decideWorkspace(item.id, approve: approve),
    sessionGeneration: authGeneration,
    currentSessionGeneration: () => ref.read(authViewModelProvider).generation,
  );
  if (!context.mounted ||
      authGeneration != ref.read(authViewModelProvider).generation) {
    return;
  }
  await _refreshAdmin(ref);
  if (!context.mounted) {
    return;
  }
  Navigator.pop(context);
  _showResult(context, ok, approve ? 'Centro aprobado.' : 'Centro rechazado.');
}

Future<void> _decideAccess(
  BuildContext context,
  WidgetRef ref,
  AdminMembershipRequest item,
  bool approve,
) async {
  var role = 'professional';
  if (approve && !item.isIndependent) {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Rol institucional'),
        children: const [
          _RoleOption('clinic_admin', 'Administrador de clínica'),
          _RoleOption('professional', 'Profesional'),
          _RoleOption('assistant', 'Asistente'),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    role = selected;
  }
  if (!await _confirmDecision(
    context,
    title: approve ? 'Aprobar acceso' : 'Rechazar acceso',
    message:
        '${approve ? 'Aprobar' : 'Rechazar'} el acceso de ${item.requester.fullName}.',
    destructive: !approve,
  )) {
    return;
  }
  final authGeneration = ref.read(authViewModelProvider).generation;
  final ok = await runAdminAction(
    controller: ref.read(adminAccessControllerProvider.notifier),
    id: item.id,
    action: () => ref
        .read(adminRepositoryProvider)
        .decideMembership(
          item.id,
          approve: approve,
          role: item.isIndependent ? 'professional' : role,
        ),
    sessionGeneration: authGeneration,
    currentSessionGeneration: () => ref.read(authViewModelProvider).generation,
  );
  if (!context.mounted ||
      authGeneration != ref.read(authViewModelProvider).generation) {
    return;
  }
  await _refreshAdmin(ref);
  if (!context.mounted) return;
  Navigator.pop(context);
  _showResult(context, ok, approve ? 'Acceso aprobado.' : 'Acceso rechazado.');
}

class _RoleOption extends StatelessWidget {
  final String value;
  final String label;
  const _RoleOption(this.value, this.label);

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
    onPressed: () => Navigator.pop(context, value),
    child: Text(label),
  );
}

Future<void> _toggleUser(
  BuildContext context,
  WidgetRef ref,
  AdminUser user,
) async {
  final activate = user.isSuspended;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(activate ? 'Reactivar cuenta' : 'Suspender cuenta'),
      content: Text(
        '¿Deseas ${activate ? 'reactivar' : 'suspender'} la cuenta de ${user.fullName}?',
      ),
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
  );
  if (confirmed != true) return;
  final authGeneration = ref.read(authViewModelProvider).generation;
  final ok = await runAdminAction(
    controller: ref.read(adminUsersPageControllerProvider.notifier),
    id: user.id,
    action: () async {
      await ref
          .read(adminRepositoryProvider)
          .updateUserStatus(
            userId: user.id,
            status: activate ? 'active' : 'suspended',
          );
    },
    sessionGeneration: authGeneration,
    currentSessionGeneration: () => ref.read(authViewModelProvider).generation,
  );
  if (!context.mounted ||
      authGeneration != ref.read(authViewModelProvider).generation) {
    return;
  }
  await _refreshAdmin(ref);
  if (!context.mounted) return;
  Navigator.pop(context);
  _showResult(
    context,
    ok,
    activate ? 'Cuenta reactivada.' : 'Cuenta suspendida.',
  );
}

Future<bool> _confirmDecision(
  BuildContext context, {
  required String title,
  required String message,
  required bool destructive,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 14),
              const Text(
                _accessDisclaimer,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          if (destructive)
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Rechazar'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aprobar'),
            ),
        ],
      ),
    ) ??
    false;

Future<void> _refreshAdmin(WidgetRef ref) async {
  ref.invalidate(adminSummaryProvider);
  await Future.wait([
    ref.read(adminCentersControllerProvider.notifier).refresh(),
    ref.read(adminAccessControllerProvider.notifier).refresh(),
    ref.read(adminUsersPageControllerProvider.notifier).refresh(),
  ]);
}

void _showResult(BuildContext context, bool ok, String success) {
  final message = ok
      ? success
      : 'No se pudo completar la acción. Los datos fueron actualizados.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _cleanError(String value) => value.replaceFirst('Exception: ', '');

String _date(DateTime? value) {
  if (value == null) return 'No disponible';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String _workspaceType(String value) => switch (value) {
  'independent' => 'Práctica independiente',
  'clinic' => 'Clínica',
  'consultorio' => 'Consultorio',
  'hospital' => 'Hospital',
  'university' => 'Universidad',
  'campaign' => 'Campaña',
  _ => 'Tipo no disponible',
};

String _status(String value) => localizedLifecycleStatus(value).label;

String _role(String value) => switch (value.toLowerCase()) {
  'platform_admin' || 'admin' => 'Administrador de plataforma',
  'clinic_admin' => 'Administrador de clínica',
  'professional' || 'doctor' => 'Profesional',
  'assistant' => 'Asistente',
  _ => 'Rol no disponible',
};
