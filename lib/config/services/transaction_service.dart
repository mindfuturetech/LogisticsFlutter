import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../model/truck_details_model.dart';

class TripDetailsService {
  static String get baseUrl {
    if (Platform.isAndroid && !kIsWeb) {
      return 'http://10.0.2.2:5000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  Future<List<TripDetails>> fetchTripDetails({String? startDate, String? endDate}) async {
    try {
      bool hasNetwork = await _checkConnectivity();
      if (!hasNetwork) {
        throw Exception('No internet connection. Please check your network settings.');
      }

      final url = Uri.parse('$baseUrl/logistics/list-all-transactions');
      print('Attempting to connect to: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        }),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check if the server is running on port 5000.');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body-Fetch: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TripDetails.fromJson(_transformResponse(json))).toList();
      } else if (response.statusCode == 404) {
        print('No data found for the specified date range');
        return [];
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception('Unable to connect to server. Please verify:\n1. Server is running on port 5000\n2. You\'re using the correct URL for your device\n3. No firewall is blocking the connection');
    } catch (e) {
      print('General Exception: $e');
      throw Exception('Error fetching trip details: $e');
    }
  }
  Future<bool> updateTransaction(TripDetails trip, String? id) async {
    try {
      final url = Uri.parse('$baseUrl/logistics/update-transactions');
      print('Attempting to update transaction at: $url');

      final payload = {
        'updateRows': {
          '_id': trip.id, // This should now be a string
          'destination_to': trip.destinationTo,
          'weight': trip.weight,
          'actual_weight': trip.actualWeight,
          'freight': trip.freight,
          'rate': trip.rate,
          'diesel': trip.dieselAmount,
          'advance': trip.advance,
          'toll': trip.toll,
          'tds': trip.tdsRate,
          'transaction_status': trip.transactionStatus,
          'amount': trip.amount,
          'billing_id': trip.billingId,
        }
      };

      print('Update payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Update response status code: ${response.statusCode}');
      print('Update response body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }
  // Updated to match the exact field names from your TripDetails model
  Map<String, dynamic> _transformResponse(Map<String, dynamic> json) {
    double _safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Failed to parse double from: $value. Error: $e');
          return 0.0;
        }
      }
      return 0.0;
    }

    return {
      '_id': json['_id'], // Changed to handle ID as string
      'TripID': json['trip_id']?.toString(), // Changed to handle ID as string
      'username': json['username']?.toString(),
      'TruckNumber': json['truck_no']?.toString(),
      'profile': json['profile']?.toString(),
      'Vendor': json['vendor']?.toString(),
      'DestinationTo': json['destination_to']?.toString(),
      'Weight': _safeParseDouble(json['weight']),
      'ActualWeight': _safeParseDouble(json['actual_weight']),
      'Freight': _safeParseDouble(json['freight']),
      'DieselAmount': _safeParseDouble(json['diesel']),
      'Advance': _safeParseDouble(json['advance']),
      'Toll': _safeParseDouble(json['toll']),
      'TDS_Rate': _safeParseDouble(json['tds']),
      'DifferenceInWeight': _safeParseDouble(json['short']),
      'TransactionStatus': json['transaction_status']?.toString(),
      'createdAt': json['date'] ?? json['time'],
      'updatedAt': json['date'] ?? json['time'],
      'rate': _safeParseDouble(json['rate']),
      'other_charges': _safeParseDouble(json['other_charges']),
      'amount': _safeParseDouble(json['amount']),
      'BillId': json['billing_id']?.toString(), // Changed to handle ID as string
    };
  }

  Future<void> generatePDF(List<String> selectedIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-pdf-transaction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            selectedIds.map((id) => {
              'id': id,
              'transaction_status': 'Billed'
            }).toList()
        ),
      );

      if (response.statusCode == 200) {
        // Get the temporary directory for storing the PDF
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'GeneratedTransactionBill.pdf';
        final filePath = '${directory.path}/$fileName';

        // Write the PDF data to a file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the PDF file
        await OpenFile.open(filePath);
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}