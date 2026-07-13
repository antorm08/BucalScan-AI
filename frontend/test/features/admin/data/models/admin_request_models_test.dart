import 'package:flutter_test/flutter_test.dart';
import 'package:bucalscan_ai/features/admin/data/models/admin_request_models.dart';

void main() {
  test('membership model maps aggregate requester and workspace data', () {
    final model = AdminMembershipRequestModel.fromJson({
      'id': 9,
      'status': 'pending',
      'role': 'professional',
      'created_at': '2026-07-12T10:00:00',
      'requester': {
        'id': 2,
        'full_name': 'Dra. Ana',
        'email': 'ana@example.test',
        'doctor_id': 'D-2',
        'profession': 'Odontóloga',
      },
      'workspace': {
        'id': 4,
        'name': 'Consulta Ana',
        'workspace_type': 'independent',
      },
    });
    expect(model.value.requester.fullName, 'Dra. Ana');
    expect(model.value.workspaceName, 'Consulta Ana');
    expect(model.value.isIndependent, isTrue);
  });
}
