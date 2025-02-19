
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://shreelalchand.com/logistics';

  // For maintaining auth state
  static Future<void> setAuthToken(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', value);
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAuthenticated') ?? false;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        print('Success: ${response.statusCode}');
         setAuthToken(true);
        return json.decode(response.body);

      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await setAuthToken(false);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Logout failed');
      }
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
    // Function to clear user session (remove stored credentials)
    Future<void> clearSession() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears all stored authentication data
    }
  }


  Future<bool> checkAuth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-auth'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}