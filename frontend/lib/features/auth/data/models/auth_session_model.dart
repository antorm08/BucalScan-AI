import '../../domain/entities/auth_session.dart';
import 'auth_user_model.dart';

class AuthSessionModel extends AuthSession {
  final Map<String, dynamic> userJson;

  const AuthSessionModel({
    required AuthUserModel super.user,
    required super.token,
    required this.userJson,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('missing_auth_data');
    }

    final userJson = data['user'] as Map<String, dynamic>?;
    final token = data['token'] as String?;
    if (userJson == null || token == null || token.isEmpty) {
      throw const FormatException('incomplete_auth_response');
    }

    return AuthSessionModel(
      user: AuthUserModel.fromJson(userJson),
      token: token,
      userJson: userJson,
    );
  }
}
