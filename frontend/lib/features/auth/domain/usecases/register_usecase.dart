import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<void> call({
    required String fullName,
    required String doctorId,
    String? medicalCenter,
    required String email,
    required String password,
    required String profession,
    String? specialty,
    String? workspaceChoice,
    String? workspaceId,
    String? workspaceName,
    String? workspaceType,
  }) {
    return _repository.register(
      fullName: fullName,
      doctorId: doctorId,
      medicalCenter: medicalCenter,
      email: email,
      password: password,
      profession: profession,
      specialty: specialty,
      workspaceChoice: workspaceChoice,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      workspaceType: workspaceType,
    );
  }
}
