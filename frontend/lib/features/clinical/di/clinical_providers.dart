import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/clinical/data/repositories/clinical_repository_impl.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';

final clinicalRepositoryProvider = Provider<ClinicalRepository>((ref) {
  return ClinicalRepositoryImpl(ref.watch(authApiServiceProvider));
});
