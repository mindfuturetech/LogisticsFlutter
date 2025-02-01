import 'package:flutter/material.dart';

import '../../config/services/auth_service.dart';


class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = '';
  String _userProfile = '';

  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;
  String get userProfile => _userProfile;

  Future<void> init() async {
    final authService = AuthService();
    _isAuthenticated = await authService.checkAuth();
    notifyListeners();
  }

  Future<void> setAuth(bool value, {String? username, String? profile}) async {
    _isAuthenticated = value;
    _username = username ?? '';
    _userProfile = profile ?? '';
    await AuthService.setAuthToken(value);
    notifyListeners();
  }

  Future<void> logout() async {
    final authService = AuthService();
    await authService.logout();
    await setAuth(false);
  }
}