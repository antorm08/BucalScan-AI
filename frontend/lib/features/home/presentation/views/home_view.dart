import 'package:bucalscan_ai/core/session/user_sensitive_state.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patients_view.dart';
import 'package:bucalscan_ai/features/history/presentation/views/history_tab_view.dart';
import 'package:bucalscan_ai/features/home/presentation/views/home_tab_view.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/views/capture_tab_view.dart';
import 'package:bucalscan_ai/features/profile/presentation/views/help_center_view.dart';
import 'package:bucalscan_ai/features/profile/presentation/views/model_info_view.dart';
import 'package:bucalscan_ai/features/profile/presentation/views/profile_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _AccountAction { profile, help, model, workspace, logout }

class HomeView extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeView({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  late int _currentIndex;
  List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );
  late final Set<int> _visited;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _visited = {_currentIndex};
  }

  void _selectTab(int index) => setState(() {
    _currentIndex = index;
    _visited.add(index);
  });

  void _repeatAnalysis(Patient patient, OralLesion lesion) {
    ref.read(clinicalControllerProvider.notifier)
      ..selectPatient(patient)
      ..selectLesion(lesion);
    ref.read(predictionViewModelProvider.notifier).clearResult();
    for (final key in _navigatorKeys) {
      key.currentState?.popUntil((route) => route.isFirst);
    }
    _selectTab(2);
  }

  Future<void> _changeWorkspace() async {
    final active = ref
        .read(clinicalControllerProvider)
        .workspaces
        .where((workspace) => workspace.canEnter)
        .toList();
    if (active.length <= 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar centro de trabajo'),
        content: const Text(
          'Se limpiarán únicamente la selección actual, la imagen y los borradores no guardados. Los pacientes, lesiones y análisis ya guardados permanecerán disponibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cambiar centro'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final key in _navigatorKeys) {
      key.currentState?.popUntil((route) => route.isFirst);
    }
    ref.resetWorkspaceSensitiveState();
    setState(() {
      _currentIndex = 0;
      _visited
        ..clear()
        ..add(0);
      _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Se descartará cualquier borrador no guardado.'),
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
    if (confirmed == true && mounted) {
      await ref.read(authViewModelProvider.notifier).logout();
    }
  }

  void _open(Widget page) {
    _navigatorKeys[_currentIndex].currentState?.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _handleAccountAction(_AccountAction action) {
    switch (action) {
      case _AccountAction.profile:
        _open(const ProfileTabView());
        return;
      case _AccountAction.help:
        _open(const HelpCenterView());
        return;
      case _AccountAction.model:
        _open(const ModelInfoView());
        return;
      case _AccountAction.workspace:
        _changeWorkspace();
        return;
      case _AccountAction.logout:
        _logout();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinical = ref.watch(clinicalControllerProvider);
    final workspace = clinical.activeWorkspace;
    final canSwitch =
        clinical.workspaces.where((item) => item.canEnter).length > 1;
    final destinations = <Widget>[
      HomeTabView(
        onStartCapture: () => _selectTab(2),
        onOpenPatients: () => _selectTab(1),
        onOpenHistory: () => _selectTab(3),
      ),
      PatientsView(onRepeatAnalysis: _repeatAnalysis),
      CaptureTabView(onOpenHistory: () => _selectTab(3)),
      HistoryTabView(onRepeatAnalysis: _repeatAnalysis),
    ];

    return PopScope(
      canPop: !(_navigatorKeys[_currentIndex].currentState?.canPop() ?? false),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigatorKeys[_currentIndex].currentState?.maybePop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BucalScan AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (workspace != null)
                      Text(
                        '${workspace.name} · ${_roleLabel(workspace.role)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<_AccountAction>(
              key: const Key('accountMenuButton'),
              tooltip: 'Cuenta y ayuda',
              onSelected: _handleAccountAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _AccountAction.profile,
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Cuenta y perfil'),
                  ),
                ),
                const PopupMenuItem(
                  value: _AccountAction.help,
                  child: ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('Centro de ayuda'),
                  ),
                ),
                const PopupMenuItem(
                  value: _AccountAction.model,
                  child: ListTile(
                    leading: Icon(Icons.psychology_alt_outlined),
                    title: Text('Modelo y apoyo de decisión'),
                  ),
                ),
                if (canSwitch)
                  const PopupMenuItem(
                    value: _AccountAction.workspace,
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Cambiar centro'),
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _AccountAction.logout,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            destinations.length,
            (index) => !_visited.contains(index)
                ? const SizedBox.shrink()
                : Navigator(
                    key: _navigatorKeys[index],
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => destinations[index],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Pacientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_a_photo_outlined),
              selectedIcon: Icon(Icons.add_a_photo),
              label: 'Analizar',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(String? role) => switch (role) {
  'clinic_admin' => 'Administración clínica',
  'assistant' => 'Asistente',
  _ => 'Profesional',
};
