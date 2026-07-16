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
    final hasContext = clinical.patient != null && clinical.lesion != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveContent(
        maxWidth: 840,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnalysisProgress(
                hasContext: hasContext,
                hasImage: hasImage,
                assessmentComplete: !priority.available || priority.complete,
              ),
              const SizedBox(height: 16),
              const PatientLesionPicker(),
              const SizedBox(height: 16),
              const _StepHeading(
                title: 'Imagen clínica',
                description:
                    'Tome una fotografía o elija una imagen de la lesión seleccionada.',
              ),
              const SizedBox(height: 12),
              _CapturePreviewCard(selectedImage: _selectedImage),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isLoading || !hasContext
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
                      onPressed: viewModel.isLoading || !hasContext
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
              const SizedBox(height: 8),
              const _CaptureTipsCard(),
              if (hasImage) ...[
                const SizedBox(height: 20),
                const _StepHeading(
                  title: 'Evaluación y autorización',
                  description:
                      'Complete los datos requeridos antes de enviar la imagen.',
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: const Key('clinicalObservationsSection'),
                    leading: const Icon(Icons.notes_outlined),
                    title: const Text('Agregar hallazgos'),
                    subtitle: const Text('Opcional'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
                      TextField(
                        key: const Key('clinicalObservationsField'),
                        controller: _clinicalObservationsController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Hallazgos de esta evaluación',
                          hintText:
                              'Ej.: bordes, color, superficie y síntomas observados hoy',
                          helperText:
                              'Se guardan separados de las notas longitudinales.',
                          helperMaxLines: 2,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const ClinicalAssessmentCard(),
                const SizedBox(height: 12),
                _ConsentCard(
                  isEnabled: !viewModel.isLoading,
                  value: _hasStorageConsent,
                  onChanged: (value) {
                    setState(() => _hasStorageConsent = value ?? false);
                  },
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed:
                    _selectedImage == null ||
                        viewModel.isLoading ||
                        clinical.patient == null ||
                        clinical.lesion == null ||
                        !_hasStorageConsent ||
                        priority.loading ||
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
                      : priority.loading
                      ? 'Consultando evaluación clínica...'
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

class _AnalysisProgress extends StatelessWidget {
  final bool hasContext;
  final bool hasImage;
  final bool assessmentComplete;

  const _AnalysisProgress({
    required this.hasContext,
    required this.hasImage,
    required this.assessmentComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progreso del análisis en tres pasos',
      child: Row(
        children: [
          _ProgressItem(
            number: 1,
            label: 'Contexto',
            complete: hasContext,
            active: !hasContext,
          ),
          const _ProgressLine(),
          _ProgressItem(
            number: 2,
            label: 'Imagen',
            complete: hasImage,
            active: hasContext && !hasImage,
          ),
          const _ProgressLine(),
          _ProgressItem(
            number: 3,
            label: 'Evaluación',
            complete: hasImage && assessmentComplete,
            active: hasImage && !assessmentComplete,
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final int number;
  final String label;
  final bool complete;
  final bool active;

  const _ProgressItem({
    required this.number,
    required this.label,
    required this.complete,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final emphasized = active || complete;
    final color = emphasized ? AppColors.primary : AppColors.onSurfaceVariant;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            key: Key('analysisProgressStep$number'),
            duration: const Duration(milliseconds: 180),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: emphasized
                  ? AppColors.primary
                  : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: emphasized ? AppColors.primary : AppColors.outline,
              ),
            ),
            alignment: Alignment.center,
            child: complete
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 19)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 2,
    margin: const EdgeInsets.only(bottom: 22),
    color: AppColors.outlineVariant,
  );
}

class _StepHeading extends StatelessWidget {
  final String title;
  final String description;

  const _StepHeading({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
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

class _CaptureTipsCard extends StatelessWidget {
  const _CaptureTipsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.tips_and_updates_outlined),
        title: const Text('Consejos para una buena captura'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: const [
          _TipRow(
            icon: Icons.light_mode_outlined,
            text: 'Busque luz uniforme y evite sombras fuertes.',
          ),
          SizedBox(height: 10),
          _TipRow(
            icon: Icons.crop_free_outlined,
            text: 'Centre la lesión y muéstrela completa.',
          ),
          SizedBox(height: 10),
          _TipRow(
            icon: Icons.privacy_tip_outlined,
            text:
                'El resultado es apoyo clínico y no reemplaza evaluación profesional.',
          ),
        ],
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
