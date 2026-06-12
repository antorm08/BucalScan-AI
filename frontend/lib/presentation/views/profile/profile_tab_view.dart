import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/presentation/views/auth/login_view.dart';
import 'package:bucalscan_ai/presentation/views/profile/edit_profile_view.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    context.read<AuthViewModel>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _formatMemberSince(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Perfil'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.surfaceContainerLowest,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryContainer,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? '—',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '—',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: AppColors.surfaceContainerLowest,
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.badge,
                    title: 'ID Médico',
                    subtitle: user?.doctorId ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                  _ProfileTile(
                    icon: Icons.local_hospital,
                    title: 'Centro médico',
                    subtitle: user?.medicalCenter ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                  _ProfileTile(
                    icon: Icons.calendar_today,
                    title: 'Miembro desde',
                    subtitle: _formatMemberSince(user?.createdAt),
                  ),
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                  _ProfileTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Rol de acceso',
                    subtitle: user?.isAdmin == true
                        ? 'Administrador'
                        : 'Doctor',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: AppColors.surfaceContainerLowest,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: const Text('Configuración'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileView(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: const Text('Ayuda y soporte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: AppColors.surfaceVariant),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(title, style: const TextStyle(color: AppColors.onSurface)),
      subtitle: Text(subtitle),
    );
  }
}
