
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConnectionTestScreen extends StatefulWidget {
  @override
  _ConnectionTestScreenState createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _status = 'Not tested';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing...';
    });

    try {
      // Test signup endpoint
      final response = await http.post(
        Uri.parse('http://13.61.234.145/logistics/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': 'testuser',
          'profile': 'admin',
        }),
      );

      setState(() {
        _status = 'Response Status Code: ${response.statusCode}\n'
            'Response Body: ${response.body}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backend Connection Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: Text('Test Backend Connection'),
            ),
            SizedBox(height: 20),
            Text('Status:'),
            SizedBox(height: 10),
            Text(_status),
          ],
        ),
      ),
    );
  }
}