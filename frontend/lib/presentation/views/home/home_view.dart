import 'package:flutter/material.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/views/capture/capture_tab_view.dart';
import 'package:bucalscan_ai/presentation/views/history/history_tab_view.dart';
import 'package:bucalscan_ai/presentation/views/home/home_tab_view.dart';
import 'package:bucalscan_ai/presentation/views/profile/profile_tab_view.dart';
import 'package:bucalscan_ai/presentation/widgets/nav_bar_item.dart';

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
      HomeTabView(onStartCapture: () => _selectTab(1)),
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
      body: _screens[_currentIndex],
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
