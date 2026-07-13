import 'package:bucalscan_ai/features/priority/domain/entities/clinical_priority.dart';

abstract class ClinicalPriorityRepository {
  Future<ClinicalPriorityCapability> getCapability();
}
