class AppConstants {
  static const String appName = 'BucalScan AI';
  /*static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bucalscan-ai.onrender.com',
  );*/
  static const String apiBaseUrl = 'http://127.0.0.1:8000';
  static const String apiVersion = '/api/v1';

  static const String predictEndpoint = '$apiBaseUrl$apiVersion/predict';
  static const String registerEndpoint = '$apiBaseUrl$apiVersion/auth/register';
  static const String loginEndpoint = '$apiBaseUrl$apiVersion/auth/login';
  static const String historyEndpoint = '$apiBaseUrl$apiVersion/history';

  static const List<String> lesionClasses = ['benign', 'malignant'];

  static const String recommendationBenign = 'No immediate concern. Regular check-ups recommended.';
  static const String recommendationMalignant = 'Malignant lesion suspected. Immediate medical attention required.';
}
