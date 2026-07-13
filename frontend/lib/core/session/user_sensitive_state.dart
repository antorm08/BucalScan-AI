import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_approvals_controller.dart';
import 'package:bucalscan_ai/features/admin/presentation/viewmodels/admin_users_controller.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/clinical_controller.dart';
import 'package:bucalscan_ai/features/dashboard/presentation/viewmodels/summary_viewmodel.dart';
import 'package:bucalscan_ai/features/history/presentation/viewmodels/history_viewmodel.dart';
import 'package:bucalscan_ai/features/prediction/presentation/viewmodels/prediction_viewmodel.dart';
import 'package:bucalscan_ai/features/clinical/presentation/viewmodels/patient_follow_up_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _resetUserSensitiveState(Ref ref) {
  ref.read(clinicalControllerProvider.notifier).clearSession();
  ref.invalidate(clinicalControllerProvider);
  ref.invalidate(historyViewModelProvider);
  ref.invalidate(summaryViewModelProvider);
  ref.invalidate(predictionViewModelProvider);
  ref.invalidate(patientFollowUpControllerProvider);
  ref.invalidate(adminUsersControllerProvider);
  ref.invalidate(adminApprovalsControllerProvider);
}

extension UserSensitiveRefReset on Ref {
  void resetUserSensitiveState() => _resetUserSensitiveState(this);
}

extension UserSensitiveWidgetRefReset on WidgetRef {
  void resetUserSensitiveState() {
    read(clinicalControllerProvider.notifier).clearSession();
    invalidate(clinicalControllerProvider);
    invalidate(historyViewModelProvider);
    invalidate(summaryViewModelProvider);
    invalidate(predictionViewModelProvider);
    invalidate(patientFollowUpControllerProvider);
    invalidate(adminUsersControllerProvider);
    invalidate(adminApprovalsControllerProvider);
  }

  void resetWorkspaceSensitiveState() {
    read(clinicalControllerProvider.notifier).leaveWorkspace();
    read(patientFollowUpControllerProvider.notifier).clear();
    invalidate(patientFollowUpControllerProvider);
    invalidate(historyViewModelProvider);
    invalidate(summaryViewModelProvider);
    read(predictionViewModelProvider.notifier).clearResult();
    invalidate(predictionViewModelProvider);
  }
}
