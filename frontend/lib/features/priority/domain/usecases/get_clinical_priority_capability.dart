import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/domain/repositories/clinical_priority_repository.dart';

class GetClinicalPriorityCapability {
  final ClinicalPriorityRepository _repository;

  const GetClinicalPriorityCapability(this._repository);

  Future<ClinicalPriorityCapability> call() => _repository.getCapability();
}
