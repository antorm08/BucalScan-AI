import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/priority/data/repositories/clinical_priority_repository_impl.dart';
import 'package:bucalscan_ai/features/priority/data/datasources/clinical_priority_remote_datasource.dart';
import 'package:bucalscan_ai/features/priority/domain/repositories/clinical_priority_repository.dart';
import 'package:bucalscan_ai/features/priority/domain/usecases/get_clinical_priority_capability.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clinicalPriorityRepositoryProvider = Provider<ClinicalPriorityRepository>(
  (ref) => ClinicalPriorityRepositoryImpl(
    ClinicalPriorityRemoteDataSource(ref.watch(authApiServiceProvider)),
  ),
);

final getClinicalPriorityCapabilityProvider =
    Provider<GetClinicalPriorityCapability>(
      (ref) => GetClinicalPriorityCapability(
        ref.watch(clinicalPriorityRepositoryProvider),
      ),
    );
