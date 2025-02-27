import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/services/auth_service.dart';
import 'login_screen.dart';


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

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    await setAuth(false);

    // Delay to ensure stack is cleared before navigation
    await Future.delayed(Duration(milliseconds: 100));

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // // Navigate to Login screen & clear all previous routes
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginScreen()),
    //       (route) => false,
    // );

    // Navigate to Login screen & clear all previous routes
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );

  }

}