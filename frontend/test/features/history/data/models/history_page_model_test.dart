import 'package:bucalscan_ai/features/history/data/models/history_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps paginated clinical detail and provenance fields', () {
    final page = HistoryPageModel.fromJson({
      'items': [
        {
          'id': 7,
          'prediction': 'new-label',
          'confidence': 0.4,
          'timestamp': '2026-01-01T10:00:00Z',
          'patient_record_id': 2,
          'lesion_id': 3,
          'lesion_site': 'Lengua',
          'evaluated_at': '2026-01-01T09:59:00Z',
          'clinical_observations': 'Hallazgo actual',
          'professional_id': 4,
          'professional_name': 'Dra. Ana',
          'professional_doctor_id': 'DOC-4',
          'professional_profession': 'Odontóloga',
          'professional_specialty': 'Patología oral',
        },
      ],
      'page': 2,
      'page_size': 25,
      'total': 30,
      'has_next': true,
      'priority_filter_enabled': true,
    }).toEntity();

    expect(page.page, 2);
    expect(page.total, 30);
    expect(page.hasNext, true);
    expect(page.priorityFilterEnabled, true);
    expect(page.items.single.lesionSite, 'Lengua');
    expect(page.items.single.clinicalObservations, 'Hallazgo actual');
    expect(page.items.single.professionalSpecialty, 'Patología oral');
  });

  test('accepts the legacy raw-list response during rollout', () {
    final page = HistoryPageModel.fromJson([
      {
        'id': 1,
        'prediction': 'benign',
        'confidence': 0.8,
        'timestamp': '2026-01-01T10:00:00Z',
      },
    ]).toEntity();

    expect(page.items, hasLength(1));
    expect(page.total, 1);
    expect(page.hasNext, false);
    expect(page.priorityFilterEnabled, false);
  });
}
