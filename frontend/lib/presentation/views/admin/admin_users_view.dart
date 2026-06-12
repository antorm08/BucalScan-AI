import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/models/admin_user_model.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final _searchController = TextEditingController();
  List<AdminUserModel> _users = [];
  bool _isLoading = true;
  String? _error;
  int? _updatingUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await context.read<ApiService>().getAdminUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(AdminUserModel user) async {
    final nextStatus = user.isActive ? 'suspended' : 'active';
    setState(() => _updatingUserId = user.id);

    try {
      final updated = await context.read<ApiService>().updateAdminUserStatus(
        userId: user.id,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() {
        _users = _users
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isActive ? 'Usuario reactivado.' : 'Usuario suspendido.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUserId = null);
      }
    }
  }

  List<AdminUserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.doctorId.toLowerCase().contains(query) ||
          (user.medicalCenter?.toLowerCase().contains(query) ?? false) ||
          user.role.toLowerCase().contains(query) ||
          user.status.toLowerCase().contains(query);
    }).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;
    final currentUserId = context.watch<AuthViewModel>().currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AdminHeader(onRefresh: _isLoading ? null : _fetchUsers),
          _SearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
          ),
          Expanded(child: _buildBody(users, currentUserId)),
        ],
      ),
    );
  }

  Widget _buildBody(List<AdminUserModel> users, int? currentUserId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar la gestión administrativa',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No hay usuarios para mostrar.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AdminUserCard(
        user: users[index],
        isUpdating: _updatingUserId == users[index].id,
        isCurrentUser: users[index].id == currentUserId,
        onToggleStatus: () => _toggleStatus(users[index]),
        formatDate: _formatDate,
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final VoidCallback? onRefresh;

  const _AdminHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 14,
        16,
        18,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back,
            tooltip: 'Volver',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.group_add, color: AppColors.primary, size: 30),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gestión de usuarios',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _HeaderButton(
            icon: Icons.refresh,
            tooltip: 'Actualizar',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.primary),
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: controller.text.isEmpty
                ? const Icon(Icons.tune, color: AppColors.onSurfaceVariant)
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Limpiar búsqueda',
                  ),
            hintText: 'Buscar por nombre, correo, ID médico o centro...',
            hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUserModel user;
  final bool isUpdating;
  final bool isCurrentUser;
  final VoidCallback onToggleStatus;
  final String Function(DateTime?) formatDate;

  const _AdminUserCard({
    required this.user,
    required this.isUpdating,
    required this.isCurrentUser,
    required this.onToggleStatus,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isActive ? AppColors.benignText : AppColors.error;
    final statusBg = user.isActive
        ? AppColors.benignBg
        : AppColors.errorContainer;
    final actionColor = user.isActive ? AppColors.primary : AppColors.benignText;

    return Container(
      decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primaryFixed, Color(0xFFEAF2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    user.isAdmin
                        ? Icons.shield_outlined
                        : Icons.medical_information_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 10),
                      const SizedBox(width: 8),
                      Text(
                        user.isActive ? 'Activo' : 'Suspendido',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.surfaceVariant),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _InfoChip(
                      icon: Icons.person_outline,
                      label: 'Rol',
                      value: user.isAdmin ? 'Admin' : 'Doctor',
                      width: itemWidth,
                    ),
                    _InfoChip(
                      icon: Icons.badge_outlined,
                      label: 'ID médico',
                      value: user.doctorId,
                      width: itemWidth,
                    ),
                    _InfoChip(
                      icon: Icons.apartment_outlined,
                      label: 'Centro',
                      value: user.medicalCenter?.isNotEmpty == true
                          ? user.medicalCenter!
                          : 'No registrado',
                      width: itemWidth,
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Alta',
                      value: formatDate(user.createdAt),
                      width: itemWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 180,
                  child: OutlinedButton.icon(
                    onPressed: isUpdating || isCurrentUser ? null : onToggleStatus,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: actionColor,
                      side: BorderSide(color: actionColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isUpdating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: actionColor,
                            ),
                          )
                        : Icon(
                            user.isActive
                                ? Icons.block
                                : Icons.check_circle_outline,
                          ),
                    label: Text(
                      isCurrentUser
                          ? 'Tu cuenta'
                          : user.isActive
                          ? 'Suspender'
                          : 'Reactivar',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double width;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
