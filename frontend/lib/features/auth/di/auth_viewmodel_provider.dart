import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bucalscan_ai/features/profile/di/profile_providers.dart';

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) {
  return AuthViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(updateProfileUseCaseProvider),
    ref.watch(hasSessionTokenUseCaseProvider),
    ref.watch(getCachedUserUseCaseProvider),
    ref.watch(logoutUseCaseProvider),
  );
});
