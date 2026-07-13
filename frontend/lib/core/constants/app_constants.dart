class AppConstants {
  static const String appName = 'BucalScan AI';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bucalscan-ai.onrender.com',
  );
  static const String apiVersion = '/api/v1';

  static const String predictEndpoint = '$apiBaseUrl$apiVersion/predict';
  static const String registerEndpoint = '$apiBaseUrl$apiVersion/auth/register';
  static const String loginEndpoint = '$apiBaseUrl$apiVersion/auth/login';
  static const String historyEndpoint = '$apiBaseUrl$apiVersion/history';
  static const String readinessEndpoint = '/ready';

  static const List<String> lesionClasses = ['benign', 'malignant'];

  static const String recommendationBenign =
      'No immediate concern. Regular check-ups recommended.';
  static const String recommendationMalignant =
      'Malignant lesion suspected. Immediate medical attention required.';
}

class ClinicalEndpoints {
  static const String workspaces = '${AppConstants.apiVersion}/workspaces';
  static const String memberships = '$workspaces/mine';
  static const String patients = '${AppConstants.apiVersion}/patients';

  static String patientLesions(String patientId) =>
      '$patients/$patientId/lesions';
}
