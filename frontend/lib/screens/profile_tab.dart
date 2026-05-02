import 'package:flutter/material.dart';
import 'package:oral_lesion_detector/screens/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryContainer = Color(0xFF0F4C81);
    const surfaceVariant = Color(0xFFE0E3E5);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF42474F);
    const background = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primaryContainer,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF8EBDF9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dra. Jenkins',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dr.jenkins@hospital.org',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.badge,
                    title: 'ID Médico',
                    subtitle: 'MD-12345678',
                  ),
                  Divider(height: 1, color: surfaceVariant),
                  _ProfileTile(
                    icon: Icons.local_hospital,
                    title: 'Centro médico',
                    subtitle: 'Hospital General',
                  ),
                  Divider(height: 1, color: surfaceVariant),
                  _ProfileTile(
                    icon: Icons.calendar_today,
                    title: 'Miembro desde',
                    subtitle: 'Octubre 2024',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.settings, color: onSurfaceVariant),
                    title: const Text('Configuración'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: surfaceVariant),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: onSurfaceVariant),
                    title: const Text('Ayuda y soporte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: surfaceVariant),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
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
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF42474F);

    return ListTile(
      leading: Icon(icon, color: onSurfaceVariant),
      title: Text(title, style: TextStyle(color: onSurface)),
      subtitle: Text(subtitle),
    );
  }
}
