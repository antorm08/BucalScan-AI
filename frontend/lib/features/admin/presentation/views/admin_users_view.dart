import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/admin/di/admin_providers.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_list_controllers.dart';
import 'package:bucalscan_ai/features/admin/presentation/views/admin_destination_views.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersView extends ConsumerStatefulWidget {
  final VoidCallback? onLoggedOut;

  const AdminUsersView({super.key, this.onLoggedOut});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> {
  int _index = 0;
  late final List<Widget> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = const [
      AdminCentersView(),
      AdminAccessView(),
      AdminUsersDestinationView(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  Future<void> _refreshAll() async {
    if (ref.read(authViewModelProvider).currentUser?.isAdmin != true) return;
    ref.invalidate(adminSummaryProvider);
    await Future.wait([
      ref.read(adminCentersControllerProvider.notifier).refresh(),
      ref.read(adminAccessControllerProvider.notifier).refresh(),
      ref.read(adminUsersPageControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir del panel administrativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authViewModelProvider.notifier).logout();
    if (mounted) widget.onLoggedOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authViewModelProvider).currentUser?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('No tienes acceso a esta sección.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BucalScan AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Administración',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
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
            key: const Key('adminRefreshButton'),
            tooltip: 'Actualizar todos los datos',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            key: const Key('adminLogoutButton'),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _destinations),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain),
            label: 'Centros',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Accesos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }
}
