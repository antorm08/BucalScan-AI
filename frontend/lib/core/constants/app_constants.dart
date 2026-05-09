class AppConstants {
  static const String appName = 'BucalScan AI';
  static const String apiBaseUrl = 'http://192.168.1.45:8000';
  static const String apiVersion = '/api/v1';

  static const String predictEndpoint = '$apiBaseUrl$apiVersion/predict';
  static const String registerEndpoint = '$apiBaseUrl$apiVersion/auth/register';
  static const String loginEndpoint = '$apiBaseUrl$apiVersion/auth/login';
  static const String historyEndpoint = '$apiBaseUrl$apiVersion/history';

  static const List<String> lesionClasses = ['benign', 'malignant'];

  static const String recommendationBenign = 'No immediate concern. Regular check-ups recommended.';
  static const String recommendationMalignant = 'Malignant lesion suspected. Immediate medical attention required.';
}
