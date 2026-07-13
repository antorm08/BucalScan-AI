import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/core/theme/app_colors.dart';
import 'package:bucalscan_ai/core/validators/auth_validators.dart';
import 'package:bucalscan_ai/core/widgets/app_text_field.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/auth/presentation/views/login_view.dart';
import 'package:bucalscan_ai/features/auth/presentation/widgets/clinic_selector.dart';
import 'package:bucalscan_ai/features/clinical/domain/entities/clinical_entities.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _medicalCenterController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherSpecialtyController = TextEditingController();
  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showPasswordConfirmation = false;
  String _workspaceChoice = 'existing';
  String _workspaceType = 'clinic';
  ClinicalWorkspace? _selectedWorkspace;
  String _profession = 'Odontólogo/a';
  String _specialty = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authViewModelProvider.notifier).clearError(),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _doctorIdController.dispose();
    _medicalCenterController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otherSpecialtyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe aceptar los términos y condiciones'),
          ),
        );
        return;
      }
      final viewModel = ref.read(authViewModelProvider.notifier);
      final success = await viewModel.register(
        fullName: _fullNameController.text.trim(),
        doctorId: _doctorIdController.text.trim(),
        medicalCenter:
            _workspaceChoice == 'new' &&
                _medicalCenterController.text.trim().isNotEmpty
            ? _medicalCenterController.text.trim()
            : null,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profession: _profession,
        specialty: _specialty == 'Otra'
            ? _otherSpecialtyController.text.trim()
            : _specialty.isEmpty
            ? null
            : _specialty,
        workspaceChoice: _workspaceChoice,
        workspaceId: _workspaceChoice == 'existing'
            ? _selectedWorkspace?.id
            : null,
        workspaceName: _workspaceChoice == 'new'
            ? _medicalCenterController.text.trim()
            : null,
        workspaceType: _workspaceChoice == 'new' ? _workspaceType : null,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Solicitud registrada. Inicie sesion para consultar su estado de aprobacion.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.benignText,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.01,
                            color: AppColors.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Regístrese para acceder a herramientas avanzadas de IA clínica.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: AppColors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: AppColors.surfaceVariant,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _fullNameController,
                              label: 'Nombre completo',
                              hint: 'María Fernández López',
                              icon: Icons.person,
                              validator: AuthValidators.validateFullName,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _doctorIdController,
                              label: 'Colegiatura o registro profesional',
                              hint: 'COP-123456',
                              icon: Icons.badge,
                              validator: AuthValidators.validateDoctorId,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _profession,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Profesión',
                                prefixIcon: Icon(
                                  Icons.medical_services_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  const [
                                        'Odontólogo/a',
                                        'Médico/a general',
                                        'Estomatólogo/a',
                                        'Cirujano/a dentista',
                                        'Otro profesional de salud',
                                      ]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setState(
                                () => _profession = value ?? _profession,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _specialty,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Especialidad (opcional)',
                                prefixIcon: Icon(
                                  Icons.workspace_premium_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  const {
                                        '': 'Sin especialidad',
                                        'Odontología general':
                                            'Odontología general',
                                        'Patología oral': 'Patología oral',
                                        'Medicina oral': 'Medicina oral',
                                        'Cirugía maxilofacial':
                                            'Cirugía maxilofacial',
                                        'Oncología de cabeza y cuello':
                                            'Oncología de cabeza y cuello',
                                        'Otra': 'Otra',
                                      }.entries
                                      .map(
                                        (entry) => DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(entry.value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => setState(() {
                                _specialty = value ?? '';
                                if (_specialty != 'Otra') {
                                  _otherSpecialtyController.clear();
                                }
                              }),
                            ),
                            if (_specialty == 'Otra') ...[
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _otherSpecialtyController,
                                label: 'Especifique su especialidad',
                                hint: 'Nombre de la especialidad',
                                icon: Icons.edit_outlined,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Ingrese la especialidad'
                                    : null,
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Text(
                              'Modalidad de trabajo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            _WorkModeOption(
                              selected: _workspaceChoice != 'independent',
                              icon: Icons.local_hospital_outlined,
                              title: 'Centro de atención',
                              subtitle:
                                  'Busca una clínica, consultorio u hospital.',
                              onTap: () => setState(() {
                                _workspaceChoice = 'existing';
                                _medicalCenterController.clear();
                                _selectedWorkspace = null;
                              }),
                            ),
                            const SizedBox(height: 8),
                            _WorkModeOption(
                              selected: _workspaceChoice == 'independent',
                              icon: Icons.person_outline,
                              title: 'Práctica independiente',
                              subtitle:
                                  'Para profesionales que atienden por cuenta propia.',
                              onTap: () => setState(() {
                                _workspaceChoice = 'independent';
                                _medicalCenterController.clear();
                                _selectedWorkspace = null;
                              }),
                            ),
                            const SizedBox(height: 16),
                            if (_workspaceChoice != 'independent')
                              FormField<ClinicalWorkspace>(
                                validator: (_) =>
                                    _selectedWorkspace == null &&
                                        _medicalCenterController.text
                                            .trim()
                                            .isEmpty
                                    ? 'Seleccione un centro o solicite su registro'
                                    : null,
                                builder: (field) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ClinicSelector(
                                      selectedWorkspace: _selectedWorkspace,
                                      onSelected: (workspace) {
                                        setState(() {
                                          _selectedWorkspace = workspace;
                                          _workspaceChoice = 'existing';
                                          _medicalCenterController.clear();
                                        });
                                        field.didChange(workspace);
                                      },
                                      onRequestNew: (name) {
                                        setState(() {
                                          _selectedWorkspace = null;
                                          _workspaceChoice = 'new';
                                          _medicalCenterController.text = name;
                                        });
                                        field.didChange(null);
                                      },
                                    ),
                                    if (_workspaceChoice == 'new')
                                      Card(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.add_business_outlined,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      _medicalCenterController
                                                          .text,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip:
                                                        'Cancelar solicitud',
                                                    onPressed: () {
                                                      setState(() {
                                                        _workspaceChoice =
                                                            'existing';
                                                        _medicalCenterController
                                                            .clear();
                                                      });
                                                      field.didChange(null);
                                                    },
                                                    icon: const Icon(
                                                      Icons.close,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Text(
                                                'Solicitud de nuevo centro pendiente de revisión',
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                initialValue: _workspaceType,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Tipo de centro',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'clinic',
                                                    child: Text('Clínica'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'consultorio',
                                                    child: Text('Consultorio'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'hospital',
                                                    child: Text('Hospital'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'university',
                                                    child: Text('Universidad'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'campaign',
                                                    child: Text(
                                                      'Campaña de salud',
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) => setState(
                                                  () => _workspaceType =
                                                      value ?? 'clinic',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          top: 6,
                                        ),
                                        child: Text(
                                          field.errorText!,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              _workspaceChoice == 'new'
                                  ? 'La clinica quedara visible como pendiente y sera revisada para evitar duplicados.'
                                  : _workspaceChoice == 'independent'
                                  ? 'Tu practica y cuenta profesional quedaran pendientes de aprobacion.'
                                  : 'Busca tu clinica por nombre. Si no existe, podras solicitar su registro.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Correo profesional',
                              hint: 'jane.doe@hospital.org',
                              icon: Icons.mail,
                              keyboardType: TextInputType.emailAddress,
                              validator: AuthValidators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              hint: '••••••••',
                              icon: Icons.lock,
                              obscureText: !_showPassword,
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Ocultar contraseña'
                                    : 'Mostrar contraseña',
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator:
                                  AuthValidators.validateRegisterPassword,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmar contraseña',
                              hint: '••••••••',
                              icon: Icons.lock,
                              obscureText: !_showPasswordConfirmation,
                              suffixIcon: IconButton(
                                tooltip: _showPasswordConfirmation
                                    ? 'Ocultar confirmación'
                                    : 'Mostrar confirmación',
                                onPressed: () => setState(
                                  () => _showPasswordConfirmation =
                                      !_showPasswordConfirmation,
                                ),
                                icon: Icon(
                                  _showPasswordConfirmation
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) =>
                                  AuthValidators.validateConfirmPassword(
                                    value,
                                    _passwordController.text,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(
                                        () => _acceptTerms = value ?? false,
                                      );
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.outlineVariant,
                                    ),
                                    activeColor: AppColors.primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Acepto los ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Términos de Servicio',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' y la ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Política de Privacidad',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ' que rigen el manejo de datos clínicos.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (viewModel.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  viewModel.error!.replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ElevatedButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Registrarse',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '¿Ya estás registrado? ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginView()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Inicia sesión aquí',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkModeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WorkModeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? colors.primary : colors.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
