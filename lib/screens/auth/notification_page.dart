import 'package:flutter/material.dart';
import 'dart:convert';
import '../../config/model/notification_model.dart';
import '../../config/services/notification_service.dart';
import 'package:intl/intl.dart';

// Model class for Document Notification
// class DocumentNotification {
//   final String truckNo;
//   final String documentType;
//   final String expiryDate;
//
//   DocumentNotification({
//     required this.truckNo,
//     required this.documentType,
//     required this.expiryDate,
//   });
//
//   factory DocumentNotification.fromJson(Map<String, dynamic> json) {
//     return DocumentNotification(
//       truckNo: json['truck_no'] ?? '',
//       documentType: json['field_name'] ?? '',
//       expiryDate: json['end_date'] ?? '',
//     );
//   }
// }

// Service to fetch data from the API
// class NotificationService {
//   Future<List<DocumentNotification>> fetchNotifications() async {
//     try {
//       final response = await http.get(Uri.parse('http://10.0.2.2:5000/logistics/notify-trucks'));
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         return data.map((json) => DocumentNotification.fromJson(json)).toList();
//       } else {
//         throw Exception('Failed to load notifications');
//       }
//     } catch (e) {
//       throw Exception('Error: $e');
//     }
//   }
// }

// Notification Page
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _service = NotificationService();
  List<DocumentNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _service.fetchNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final DateTime expiryDate = DateTime.parse(notification.expiryDate);
          final bool isExpired = expiryDate.isBefore(DateTime.now());
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 2,
            child: Container(
              color: isExpired ?  Color(0xFFFFF9C4): Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Truck No',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          notification.truckNo.replaceAll(' ', ''), //remove spaces
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.documentType.length > 12
                              ? notification.documentType.substring(0, 12)
                              : notification.documentType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isExpired) // Show icon only if expired
                          Icon(
                            Icons.warning, // Choose an appropriate icon
                            size: 16, // Adjust size as needed
                            color: Colors.red, // Make it red to indicate urgency
                          ),
                        if (isExpired) const SizedBox(height: 2),
                        Text(
                          'Expires on',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(notification.expiryDate)),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
