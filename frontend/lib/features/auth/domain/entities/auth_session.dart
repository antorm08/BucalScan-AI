import 'auth_user.dart';

class AuthSession {
  final AuthUser user;
  final String token;

  const AuthSession({required this.user, required this.token});
}
