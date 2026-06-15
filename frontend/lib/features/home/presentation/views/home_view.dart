import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/nav_bar_item.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_users_view.dart';
import 'package:bucalscan_ai/features/history/presentation/views/history_tab_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_tab_view.dart';
import 'package:bucalscan_ai/features/prediction/presentation/views/capture_tab_view.dart';
import 'package:bucalscan_ai/features/profile/presentation/views/profile_tab_view.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class HomeView extends StatefulWidget {
  final int initialIndex;

  const HomeView({super.key, this.initialIndex = 0});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late int _currentIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTabView(
        onStartCapture: () => _selectTab(1),
        onOpenHistory: () => _selectTab(2),
      ),
      const CaptureTabView(),
      const HistoryTabView(),
      const ProfileTabView(),
    ];
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1).toInt();
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _MainDrawer(onSelectTab: _selectTab),
      body: _screens[_currentIndex],
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton.small(
            onPressed: () => Scaffold.of(context).openDrawer(),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            tooltip: 'Abrir menú',
            child: const Icon(Icons.menu),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: const Border(
            top: BorderSide(color: AppColors.surfaceVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavBarItem(
                  icon: Icons.home,
                  label: 'Inicio',
                  isActive: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                NavBarItem(
                  icon: Icons.add_a_photo,
                  label: 'Nueva Captura',
                  isActive: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                NavBarItem(
                  icon: Icons.history,
                  label: 'Historial',
                  isActive: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                NavBarItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  isActive: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  final ValueChanged<int> onSelectTab;

  const _MainDrawer({required this.onSelectTab});

  void _goToTab(BuildContext context, int index) {
    Navigator.pop(context);
    onSelectTab(index);
  }

  Future<void> _logout(BuildContext context) async {
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

    await context.read<AuthViewModel>().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppColors.onPrimary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BucalScan AI',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Usuario autenticado',
                    style: const TextStyle(color: AppColors.primaryFixed),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Inicio / Dashboard'),
              onTap: () => _goToTab(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: const Text('Captura o análisis'),
              onTap: () => _goToTab(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Historial'),
              onTap: () => _goToTab(context, 2),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => _goToTab(context, 3),
            ),
            if (user?.isAdmin ?? false)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Administración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersView()),
                  );
                },
              ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
