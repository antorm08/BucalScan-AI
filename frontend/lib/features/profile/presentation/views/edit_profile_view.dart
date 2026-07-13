import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/widgets/app_app_bar.dart';
import 'package:bucalscan_ai/core/widgets/app_text_field.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _medicalCenterController;
  late final TextEditingController _emailController;
  late final TextEditingController _professionController;
  late final TextEditingController _specialtyController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).currentUser;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _medicalCenterController = TextEditingController(
      text: user?.medicalCenter ?? '',
    );
    _emailController = TextEditingController(text: user?.email ?? '');
    _professionController = TextEditingController(text: user?.profession ?? '');
    _specialtyController = TextEditingController(text: user?.specialty ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _medicalCenterController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = ref.read(authViewModelProvider.notifier);
    final success = await authViewModel.updateProfile(
      fullName: _fullNameController.text.trim(),
      medicalCenter: _medicalCenterController.text.trim(),
      email: _emailController.text.trim(),
      profession: _professionController.text.trim(),
      specialty: _specialtyController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authViewModelProvider).error ??
                'Error al actualizar el perfil',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Editar perfil'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _fullNameController,
                label: 'Nombre completo',
                hint: 'Ej: María Fernández López',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _professionController,
                label: 'Profesión',
                hint: 'Ej: Odontólogo/a',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _specialtyController,
                label: 'Especialidad',
                hint: 'Opcional',
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'Ej: jane.doe@hospital.org',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }
                  if (!RegExp(
                    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                  ).hasMatch(value.trim())) {
                    return 'Correo electrónico no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _medicalCenterController,
                label: 'Centro médico',
                hint: 'Ej: Hospital Central',
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
