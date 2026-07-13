import 'package:bucalscan_ai/data/services/api_service.dart';
import 'package:bucalscan_ai/features/priority/data/models/clinical_priority_models.dart';
import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

class ClinicalPriorityRemoteDataSource {
  final ApiService _api;

  const ClinicalPriorityRemoteDataSource(this._api);

  Future<ClinicalPriorityCapability> getCapability() async {
    return ClinicalPriorityCapabilityModel.fromJson(
      await _api.getClinicalPriorityCapability(),
    );
  }
}
