import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/data/models/admin_user_model.dart';
import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

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
      appBar: AppAppBar(
        title: 'Gestión de usuarios',
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre, correo, ID, rol o estado...',
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
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

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isAdmin
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainerHigh,
                  child: Icon(
                    user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Suspendido',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: 'Rol',
                  value: user.isAdmin ? 'Admin' : 'Doctor',
                ),
                _InfoChip(label: 'ID médico', value: user.doctorId),
                _InfoChip(
                  label: 'Centro',
                  value: user.medicalCenter?.isNotEmpty == true
                      ? user.medicalCenter!
                      : 'No registrado',
                ),
                _InfoChip(label: 'Alta', value: formatDate(user.createdAt)),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isUpdating || isCurrentUser ? null : onToggleStatus,
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
