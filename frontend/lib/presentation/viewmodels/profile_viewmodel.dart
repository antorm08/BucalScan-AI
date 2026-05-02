import 'package:flutter/foundation.dart';
import 'package:oral_lesion_detector/domain/entities/user.dart';

class ProfileViewModel extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
