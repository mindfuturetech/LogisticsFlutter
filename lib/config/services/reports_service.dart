// reports_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/truck_details_model.dart';


class ReportsService {
  final Dio _dio;
  final String baseUrl = 'http://10.0.2.2:5000/logistics/api';
  // Constructor with flexible base URL
  ReportsService({String? baseUrl}) : _dio = Dio(BaseOptions(
    // Use platform-aware base URL
    baseUrl: baseUrl ?? getPlatformSpecificBaseUrl(),
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Platform-specific base URL helper
  static String getPlatformSpecificBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/logistics'; // Android emulator localhost
    } else if (Platform.isIOS) {
      return 'http://10.0.2.2:5000/logistics'; // iOS simulator localhost
    }
    return 'http://10.0.2.2:5000/logistics'; // Default fallback
  }

  Future<List<TripDetails>> getReports({
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
    String? truckNumber,
  }) async {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');

      Map<String, dynamic> queryParams = {
        if (startDate != null) 'startDate': dateFormat.format(startDate),
        if (endDate != null) 'endDate': dateFormat.format(endDate),
        if (vendor?.isNotEmpty ?? false) 'vendor': vendor!.trim(),
        if (truckNumber?.isNotEmpty ?? false) 'truckNumber': truckNumber!.trim(),
      };

      print('Fetching reports with filters:');
      print('Start Date: ${queryParams['startDate']}');
      print('End Date: ${queryParams['endDate']}');
      print('Vendor: ${queryParams['vendor']}');
      print('Truck: ${queryParams['truckNumber']}');
      print('Request URL: ${_dio.options.baseUrl}/api/reports');
      print('Query Parameters: $queryParams');

      final response = await _dio.get(
        '/api/reports',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.data != null && response.data['tableData'] != null) {
        final List<dynamic> tableData = response.data['tableData'];
        return tableData.map((json) => TripDetails.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('Dio Error: ${e.message}');
      print('Error Response: ${e.response?.data}');
      print('Error Status Code: ${e.response?.statusCode}');

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          throw Exception('Connection timeout. Please check your internet connection.');
        case DioExceptionType.connectionError:
          throw Exception(
              'Unable to connect to the server. Please verify the server is running and accessible.\n'
                  'If using an emulator, make sure you\'re using the correct localhost address '
                  '(10.0.2.2 for Android, localhost for iOS).'
          );
        case DioExceptionType.badResponse:
          throw Exception(e.response?.data['message'] ?? 'Server returned an error');
        default:
          throw Exception('Network error occurred. Please try again. (${e.type})');
      }
    } catch (e) {
      print('General Error: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
  Future<List<String>> getVendors() async {
    try {
      print('Fetching vendors...');
      final response = await _dio.get('/api/vendors');
      print('Vendors Response: ${response.data}');

      if (response.data != null && response.data['vendorData'] != null) {
        final List<dynamic> vendorData = response.data['vendorData'];
        return vendorData
            .map((vendor) => vendor['company_name'].toString())
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print('Vendor Fetch Error: ${e.message}');
      throw Exception('Failed to fetch vendors: ${e.message}');
    }
  }
// Method to download file
  Future<void> downloadFile(String id, String field, String? originalName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/download/$id/$field'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = originalName ?? 'downloaded_file';
        final filePath = '${directory.path}/$fileName';

        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the file
        await OpenFile.open(filePath);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to download file');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  // Method to update trip details
  Future<void> updateReport(
      String id,
      double weight,
      double actualWeight, // ✅ Change to Double
      String transactionStatus,
      Map<String, File?> files) async {
    try {
      var uri = '$baseUrl/reports/$id';
      FormData formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry("id", id),
        MapEntry("transactionStatus", transactionStatus),
        MapEntry("weight", weight.toString()),
        MapEntry("actualWeight", actualWeight.toString()), // ✅ Convert Double to String
      ]);

      // Add files if they exist
      for (var entry in files.entries) {
        if (entry.value != null) {
          formData.files.add(MapEntry(
            entry.key,
            await MultipartFile.fromFile(entry.value!.path,
                filename: entry.value!.path.split('/').last),
          ));
        }
      }

      var response = await _dio.post(uri,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}));

      if (response.statusCode != 200) {
        throw Exception('Failed to update report: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error updating report: $e');
    }
  }


  Future<List<String>> getTrucks() async {
    try {
      print('Fetching trucks...');
      final response = await _dio.get('/api/trucks');
      print('Trucks Response: ${response.data}');

      if (response.data != null && response.data['truckData'] != null) {
        final List<dynamic> truckData = response.data['truckData'];
        return truckData
            .map((truck) => truck['truck_no'].toString())
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print('Truck Fetch Error: ${e.message}');
      throw Exception('Failed to fetch trucks: ${e.message}');
    }
  }
}