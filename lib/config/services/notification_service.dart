import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/notification_model.dart';

class NotificationService {
  Future<List<DocumentNotification>> fetchNotifications() async {
    try {
      final response = await http.get(
          Uri.parse('http://10.0.2.2:5000/logistics/notify-trucks'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DocumentNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}