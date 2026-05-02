import 'package:flutter/material.dart';
import 'package:oral_lesion_detector/core/theme/app_colors.dart';
import 'package:oral_lesion_detector/presentation/views/capture/capture_tab_view.dart';
import 'package:oral_lesion_detector/presentation/views/history/history_tab_view.dart';
import 'package:oral_lesion_detector/presentation/views/home/home_tab_view.dart';
import 'package:oral_lesion_detector/presentation/views/profile/profile_tab_view.dart';
import 'package:oral_lesion_detector/presentation/widgets/nav_bar_item.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeTabView(),
    CaptureTabView(),
    HistoryTabView(),
    ProfileTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: const Border(top: BorderSide(color: AppColors.surfaceVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                NavBarItem(
                  icon: Icons.add_a_photo,
                  label: 'Nueva Captura',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                NavBarItem(
                  icon: Icons.history,
                  label: 'Historial',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                NavBarItem(
                  icon: Icons.person,
                  label: 'Perfil',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
