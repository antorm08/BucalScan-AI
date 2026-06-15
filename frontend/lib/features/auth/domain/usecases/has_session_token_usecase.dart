import 'package:bucalscan_ai/features/auth/domain/repositories/auth_repository.dart';

class HasSessionTokenUseCase {
  final AuthRepository _repository;

  const HasSessionTokenUseCase(this._repository);

  Future<bool> call() {
    return _repository.hasSessionToken();
  }
}
