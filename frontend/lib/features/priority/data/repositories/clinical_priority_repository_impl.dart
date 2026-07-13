import 'package:bucalscan_ai/features/priority/data/datasources/clinical_priority_remote_datasource.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';
import 'package:bucalscan_ai/features/priority/domain/repositories/clinical_priority_repository.dart';

class ClinicalPriorityRepositoryImpl implements ClinicalPriorityRepository {
  final ClinicalPriorityRemoteDataSource _remote;

  const ClinicalPriorityRepositoryImpl(this._remote);

  @override
  Future<ClinicalPriorityCapability> getCapability() async =>
      (await _remote.getCapability());
}
