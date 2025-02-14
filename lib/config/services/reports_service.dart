// reports_service.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../model/truck_details_model.dart';


class ReportsService {
  final Dio _dio;

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
      return 'https://shreelalchand.com'; // Android emulator localhost
    } else if (Platform.isIOS) {
      return 'https://shreelalchand.com'; // iOS simulator localhost
    }
    return 'https://shreelalchand.com'; // Default fallback
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