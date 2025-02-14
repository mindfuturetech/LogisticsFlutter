import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class ApiService {
  static const String baseUrl = 'https://shreelalchand.com/logistics';
  Future<Map<String, dynamic>> signup(String username, String profile) async {
    try {
      print('Sending signup request for user: $username with profile: $profile');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username.trim(),
          'profile': profile.trim(),
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Handle different status codes
      switch (response.statusCode) {
        case 200:
        case 201:
          return responseData;
        case 409: // HTTP 409 Conflict - typically used for duplicate resource
          throw UserExistsException(responseData['message'] ?? 'Username already exists');
        case 400:
          throw ValidationException(responseData['message'] ?? 'Invalid input data');
        default:
          throw Exception(responseData['message'] ?? 'Signup failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during signup: $e');
      rethrow; // Rethrow to maintain the specific exception type
    }
  }
}

// Add these custom exceptions
class UserExistsException implements Exception {
  final String message;
  UserExistsException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}
