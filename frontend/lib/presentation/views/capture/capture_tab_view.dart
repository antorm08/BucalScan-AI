import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/presentation/views/result/result_view.dart';
import 'package:bucalscan_ai/presentation/widgets/app_app_bar.dart';

class CaptureTabView extends StatefulWidget {
  const CaptureTabView({super.key});

  @override
  State<CaptureTabView> createState() => _CaptureTabViewState();
}

class _CaptureTabViewState extends State<CaptureTabView> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();

  @override
  void dispose() {
    _patientIdController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final predictionViewModel = context.read<PredictionViewModel>();

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted) {
        return;
      }

      if (image == null) {
        return;
      }

      predictionViewModel.clearResult();
      _patientIdController.clear();
      _patientNameController.clear();
      setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la imagen seleccionada. $e'),
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      return;
    }

    final viewModel = context.read<PredictionViewModel>();
    if (viewModel.isLoading) {
      return;
    }

    final imageFile = _selectedImage!;
    final patientId = _patientIdController.text.trim();
    final patientName = _patientNameController.text.trim();

    unawaited(viewModel.predictImage(
      imageFile,
      patientId: patientId.isEmpty ? null : patientId,
      patientName: patientName.isEmpty ? null : patientName,
    ));

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultView(imageFile: imageFile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PredictionViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Captura para análisis'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Captura clinica',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seleccione una foto nitida de la cavidad oral y revise la vista previa antes del analisis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CapturePreviewCard(selectedImage: _selectedImage),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(
                      _selectedImage == null ? 'Camara' : 'Nueva foto',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      _selectedImage == null ? 'Galeria' : 'Cambiar imagen',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedImage == null
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    color: _selectedImage == null
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedImage == null
                          ? 'Elija una imagen desde camara o galeria para habilitar el analisis.'
                          : 'Imagen lista. Revise el encuadre y luego continue con el analisis.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppColors.surfaceContainerLowest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos del paciente (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _patientIdController,
                      decoration: InputDecoration(
                        labelText: 'ID del Paciente',
                        hintText: 'Ej: PAC-001',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _patientNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Paciente',
                        hintText: 'Ej: Juan Pérez',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.outlineVariant),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _selectedImage == null || viewModel.isLoading
                  ? null
                  : _analyzeImage,
              icon: viewModel.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_outlined, size: 18),
              label: Text(
                viewModel.isLoading
                    ? 'Iniciando analisis...'
                    : 'Analizar imagen seleccionada',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guía rápida',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    _StepItem(
                      number: 1,
                      text:
                          'Tome o cargue una imagen bien iluminada de la cavidad oral',
                    ),
                    _StepItem(
                      number: 2,
                      text:
                          'Revise la imagen antes de enviarla para evitar errores de analisis',
                    ),
                    _StepItem(
                      number: 3,
                      text:
                          'Consulte el resultado y la confianza estimada al finalizar',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturePreviewCard extends StatelessWidget {
  final File? selectedImage;

  const _CapturePreviewCard({required this.selectedImage});

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImage != null;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceContainerLow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(selectedImage!, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Vista previa lista para analizar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 72,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Seleccione una imagen clinica',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puede tomar una foto en el momento o elegir una desde su galeria para continuar con el flujo de analisis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
