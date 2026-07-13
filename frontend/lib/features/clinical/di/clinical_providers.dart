import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bucalscan_ai/features/auth/di/auth_providers.dart';
import 'package:bucalscan_ai/features/clinical/data/repositories/clinical_repository_impl.dart';
import 'package:bucalscan_ai/features/clinical/domain/repositories/clinical_repository.dart';
import 'package:bucalscan_ai/features/clinical/domain/usecases/clinical_usecases.dart';

final clinicalRepositoryProvider = Provider<ClinicalRepository>((ref) {
  return ClinicalRepositoryImpl(ref.watch(authApiServiceProvider));
});

final getMembershipsUseCaseProvider = Provider<GetMembershipsUseCase>(
  (ref) => GetMembershipsUseCase(ref.watch(clinicalRepositoryProvider)),
);

final discoverWorkspacesUseCaseProvider = Provider<DiscoverWorkspacesUseCase>(
  (ref) => DiscoverWorkspacesUseCase(ref.watch(clinicalRepositoryProvider)),
);

final selectWorkspaceUseCaseProvider = Provider<SelectWorkspaceUseCase>(
  (ref) => SelectWorkspaceUseCase(ref.watch(clinicalRepositoryProvider)),
);

final searchPatientsUseCaseProvider = Provider<SearchPatientsUseCase>(
  (ref) => SearchPatientsUseCase(ref.watch(clinicalRepositoryProvider)),
);

final createPatientUseCaseProvider = Provider<CreatePatientUseCase>(
  (ref) => CreatePatientUseCase(ref.watch(clinicalRepositoryProvider)),
);

final getPatientUseCaseProvider = Provider<GetPatientUseCase>(
  (ref) => GetPatientUseCase(ref.watch(clinicalRepositoryProvider)),
);

final getLesionsUseCaseProvider = Provider<GetLesionsUseCase>(
  (ref) => GetLesionsUseCase(ref.watch(clinicalRepositoryProvider)),
);

final createLesionUseCaseProvider = Provider<CreateLesionUseCase>(
  (ref) => CreateLesionUseCase(ref.watch(clinicalRepositoryProvider)),
);

final getLesionDetailUseCaseProvider = Provider<GetLesionDetailUseCase>(
  (ref) => GetLesionDetailUseCase(ref.watch(clinicalRepositoryProvider)),
);

final updateLesionUseCaseProvider = Provider<UpdateLesionUseCase>(
  (ref) => UpdateLesionUseCase(ref.watch(clinicalRepositoryProvider)),
);
