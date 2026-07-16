import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/responsive_content.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/views/result_view.dart';
import 'package:bucalscan_ai/features/clinical/presentation/views/patient_lesion_picker.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/priority/presentation/viewmodels/clinical_priority_controller.dart';
import 'package:bucalscan_ai/features/priority/presentation/widgets/clinical_assessment_card.dart';

class CaptureTabView extends ConsumerStatefulWidget {
  final VoidCallback? onOpenHistory;

  const CaptureTabView({super.key, this.onOpenHistory});

  @override
  ConsumerState<CaptureTabView> createState() => _CaptureTabViewState();
}

class _CaptureTabViewState extends ConsumerState<CaptureTabView> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _hasStorageConsent = false;
  final TextEditingController _clinicalObservationsController =
      TextEditingController();

  @override
  void dispose() {
    _clinicalObservationsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final predictionViewModel = ref.read(predictionViewModelProvider.notifier);

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
      final clinical = ref.read(clinicalControllerProvider);
      if (clinical.patient != null && clinical.lesion != null) {
        predictionViewModel
          ..prepareContext(
            patientId: clinical.patient!.id,
            patientName: clinical.patient!.fullName,
            lesionId: clinical.lesion!.id,
            clinicalCode: clinical.patient!.clinicalCode,
            lesionSite: clinical.lesion!.anatomicalSite,
          )
          ..prepareImage();
      }
      setState(() {
        _selectedImage = File(image.path);
        _hasStorageConsent = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo acceder a ${source == ImageSource.camera ? 'la camara' : 'la galeria'}. Revise el permiso de BucalScan AI en los ajustes del dispositivo. $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      return;
    }

    final viewModel = ref.read(predictionViewModelProvider);
    if (viewModel.isLoading) {
      return;
    }

    final imageFile = _selectedImage!;
    final clinical = ref.read(clinicalControllerProvider);
    final priority = ref.read(clinicalPriorityControllerProvider);

    unawaited(
      ref
          .read(predictionViewModelProvider.notifier)
          .predictImage(
            imageFile,
            patientId: clinical.patient?.id,
            patientName: clinical.patient?.fullName,
            lesionId: clinical.lesion?.id,
            consentToStore: _hasStorageConsent,
            clinicalObservations: _clinicalObservationsController.text.trim(),
            assessment: priority.payload,
            clinicalCode: clinical.patient?.clinicalCode,
            lesionSite: clinical.lesion?.anatomicalSite,
          ),
    );

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultView(
          imageFile: imageFile,
          onOpenHistory: widget.onOpenHistory,
          onAnotherImage: _resetForSameLesion,
          onNewAnalysis: _startClean,
        ),
      ),
    );
  }

  void _resetForSameLesion() {
    ref.read(predictionViewModelProvider.notifier).clearResult();
    ref.read(clinicalPriorityControllerProvider.notifier).clearAssessment();
    setState(() {
      _selectedImage = null;
      _hasStorageConsent = false;
      _clinicalObservationsController.clear();
    });
  }

  void _startClean() {
    _resetForSameLesion();
    ref.read(clinicalControllerProvider.notifier).clearPatientSelection();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(clinicalControllerProvider, (previous, next) {
      if (previous?.patient?.id == next.patient?.id &&
          previous?.lesion?.id == next.lesion?.id) {
        return;
      }
      ref.read(predictionViewModelProvider.notifier).clearResult();
      if (next.patient != null && next.lesion != null) {
        ref
            .read(predictionViewModelProvider.notifier)
            .prepareContext(
              patientId: next.patient!.id,
              patientName: next.patient!.fullName,
              lesionId: next.lesion!.id,
              clinicalCode: next.patient!.clinicalCode,
              lesionSite: next.lesion!.anatomicalSite,
            );
      }
      ref.read(clinicalPriorityControllerProvider.notifier).clearAssessment();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedImage = null;
          _hasStorageConsent = false;
          _clinicalObservationsController.clear();
        });
      });
    });
    final viewModel = ref.watch(predictionViewModelProvider);
    final hasImage = _selectedImage != null;
    final clinical = ref.watch(clinicalControllerProvider);
    final priority = ref.watch(clinicalPriorityControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveContent(
        maxWidth: 840,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PatientLesionPicker(),
              const SizedBox(height: 12),
              if (clinical.patient != null && clinical.lesion != null) ...[
                Container(
                  key: const Key('selectedClinicalContext'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${clinical.patient!.fullName} · ${clinical.patient!.clinicalCode}\nLesión: ${clinical.lesion!.anatomicalSite}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Limpiar paciente y lesión',
                        onPressed: _startClean,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Una imagen corresponde a una sola lesión y evaluación. Use otro análisis para una lesión o imagen diferente.',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _CaptureHeroCard(hasImage: hasImage),
              const SizedBox(height: 12),
              _CaptureTipsCard(hasImage: hasImage),
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
                        _selectedImage == null ? 'Tomar foto' : 'Nueva foto',
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
                        _selectedImage == null
                            ? 'Elegir archivo'
                            : 'Cambiar imagen',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                            ? 'Elija una foto clara de la cavidad oral para habilitar el análisis.'
                            : 'Imagen lista. Confirme que la lesión sea visible antes de continuar.',
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
              TextField(
                key: const Key('clinicalObservationsField'),
                controller: _clinicalObservationsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Hallazgos de la evaluación actual (opcional)',
                  hintText:
                      'Ej.: bordes, color, superficie y síntomas observados hoy',
                  helperText:
                      'Se guardan en esta evaluación, separados de las notas longitudinales de la lesión.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const ClinicalAssessmentCard(),
              const SizedBox(height: 12),
              _ConsentCard(
                isEnabled: hasImage && !viewModel.isLoading,
                value: _hasStorageConsent,
                onChanged: (value) {
                  setState(() => _hasStorageConsent = value ?? false);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed:
                    _selectedImage == null ||
                        viewModel.isLoading ||
                        clinical.patient == null ||
                        clinical.lesion == null ||
                        !_hasStorageConsent ||
                        (priority.available && !priority.complete)
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
                      ? 'Preparando análisis...'
                      : priority.available && !priority.complete
                      ? 'Complete la evaluación estructurada'
                      : hasImage
                      ? _hasStorageConsent
                            ? 'Confirmar y analizar imagen'
                            : 'Confirme la autorizacion para continuar'
                      : 'Seleccione una imagen para continuar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final bool isEnabled;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ConsentCard({
    required this.isEnabled,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: isEnabled ? onChanged : null,
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atestacion profesional de autorizacion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Como profesional actuante, confirmo que obtuve la autorizacion del paciente para capturar, analizar y almacenar esta imagen clinica y su resultado.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.onSurfaceVariant,
                    ),
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

class _CaptureHeroCard extends StatelessWidget {
  final bool hasImage;

  const _CaptureHeroCard({required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasImage ? Icons.check_circle_outline : Icons.center_focus_strong,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasImage ? 'Revise antes de enviar' : 'Captura guiada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasImage
                      ? 'La imagen está cargada. Verifique nitidez, encuadre y datos opcionales antes del análisis.'
                      : 'Primero seleccione una imagen clínica. Luego podrá confirmar la vista previa y registrar metadata opcional.',
                  style: const TextStyle(
                    color: AppColors.primaryFixed,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTipsCard extends StatelessWidget {
  final bool hasImage;

  const _CaptureTipsCard({required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasImage
                      ? Icons.fact_check_outlined
                      : Icons.tips_and_updates_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasImage ? 'Control previo' : 'Indicaciones de captura',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TipRow(
              icon: Icons.light_mode_outlined,
              text: hasImage
                  ? 'La zona debe verse iluminada y sin sombras fuertes.'
                  : 'Busque luz uniforme sobre la cavidad oral.',
            ),
            const SizedBox(height: 8),
            _TipRow(
              icon: Icons.crop_free_outlined,
              text: hasImage
                  ? 'La lesión debe quedar centrada y completa en la imagen.'
                  : 'Centre la lesión y evite recortes innecesarios.',
            ),
            const SizedBox(height: 8),
            _TipRow(
              icon: Icons.privacy_tip_outlined,
              text:
                  'El resultado es apoyo clínico y no reemplaza evaluación profesional.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
