import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:oral_lesion_detector/providers/prediction_provider.dart';
import 'package:oral_lesion_detector/screens/result_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        if (mounted) {
          context.read<PredictionProvider>().predictImage(File(image.path));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00355F);
    const surfaceContainerLowest = Colors.white;
    const surfaceContainerHighest = Color(0xFFE0E3E5);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF42474F);
    const secondaryFixedDim = Color(0xFFB7C8E1);
    const error = Color(0xFFBA1A1A);
    const background = Color(0xFFF7F9FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.medical_services, color: primary),
            const SizedBox(width: 4),
            Text(
              'OralScan AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenida de nuevo, Dra. Jenkins',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aquí está su resumen clínico para hoy, 24 de octubre.',
                    style: TextStyle(
                      fontSize: 16,
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _PrimaryActionCard(
                        icon: Icons.add_a_photo,
                        title: 'Iniciar Nueva Captura',
                        subtitle: 'Capturar imágenes del paciente a través de cámara clínica externa',
                        onTap: _showImageSourceDialog,
                      ),
                      const SizedBox(height: 12),
                      _SecondaryActionCard(
                        icon: Icons.upload_file,
                        title: 'Subir Imagen de Galería',
                        subtitle: 'Analizar escaneos de pacientes existentes de la galería',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Card(
                    color: surfaceContainerLowest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: surfaceContainerHighest),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RESUMEN DE HOY',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '12',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Escaneos Analizados',
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              _StatRow(
                                color: secondaryFixedDim,
                                label: 'Benigno',
                                value: '11',
                              ),
                              const SizedBox(height: 8),
                              _StatRow(
                                color: error,
                                label: 'Riesgo Maligno',
                                value: '1',
                                valueColor: error,
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryContainer = Color(0xFF0F4C81);
    const primaryFixed = Color(0xFFD2E4FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFD2E4FF),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryFixed,
                        ),
                      ),
                    ],
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

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryContainer = Color(0xFF0F4C81);
    const surfaceContainerLowest = Colors.white;
    const surfaceContainerLow = Color(0xFFF2F4F6);
    const outlineVariant = Color(0xFFC2C7D1);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF42474F);
    const outline = Color(0xFF727780);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: primaryContainer, size: 32),
                  ),
                  Icon(Icons.arrow_forward, color: outline),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.color,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    const onSurface = Color(0xFF191C1E);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: onSurface),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? onSurface,
          ),
        ),
      ],
    );
  }
}
