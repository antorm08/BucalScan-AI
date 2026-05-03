import 'package:flutter/material.dart';
import 'package:oral_lesion_detector/core/theme/app_colors.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;

  const AppAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      elevation: 0,
      title: Row(
        children: [
          if (showLogo) ...[
            const Icon(Icons.medical_services, color: AppColors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            title.isEmpty ? 'DeepOral-DX' : title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: actions ??
          [
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
