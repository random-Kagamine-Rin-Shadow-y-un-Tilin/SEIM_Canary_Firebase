import 'package:seim_canary/models/user_model.dart';

class CurrentUser {
  static final CurrentUser _instance = CurrentUser._internal();

  factory CurrentUser() {
    return _instance;
  }

  CurrentUser._internal();

  UserModel? user;

  bool get isLoggedIn => user != null;

  void clear() {
    user = null;
  }
}