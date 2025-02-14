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
  final String baseUrl = 'https://shreelalchand.com/logistics';
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
      return 'https://shreelalchand.com/logistics'; // Android emulator localhost
    } else if (Platform.isIOS) {
      return 'https://shreelalchand.com/logistics'; // iOS simulator localhost
    }
    return 'https://shreelalchand.com/logistics'; // Default fallback
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
  // Future<List<String>> getVendors() async {
  //   try {
  //     print('Fetching vendors...');
  //     final response = await _dio.get('/api/vendors');
  //     print('Vendors Response: ${response.data}');
  //
  //     if (response.data != null && response.data['vendorData'] != null) {
  //       final List<dynamic> vendorData = response.data['vendorData'];
  //       return vendorData
  //           .map((vendor) => vendor['company_name'].toString())
  //           .toList();
  //     }
  //     return [];
  //   } on DioException catch (e) {
  //     print('Vendor Fetch Error: ${e.message}');
  //     throw Exception('Failed to fetch vendors: ${e.message}');
  //   }
  // }


  Future<void> updateReport(
      String id,
      double weight,
      double actualWeight,
      String transactionStatus,
      Map<String, File?> files) async {
    try {
      print('Updating report with ID: $id');

      // Create FormData instance
      final formData = FormData();

      // Add basic fields
      formData.fields.addAll([
        MapEntry('id', id),
        MapEntry('transactionStatus', transactionStatus),
        MapEntry('weight', weight.toString()),
        MapEntry('actualWeight', actualWeight.toString()),
      ]);

      // Add files with specific field names matching backend
      final validFileFields = [
        'DieselSlipImage',
        'LoadingAdvice',
        'InvoiceCompany',
        'WeightmentSlip'
      ];

      for (var entry in files.entries) {
        if (entry.value != null && validFileFields.contains(entry.key)) {
          print('Adding file for field: ${entry.key}');

          // Create MultipartFile
          final file = await MultipartFile.fromFile(
            entry.value!.path,
            filename: entry.value!.path.split('/').last,
          );

          // Add to FormData with the exact field name expected by backend
          formData.files.add(MapEntry(entry.key, file));
        }
      }

      print('Sending request to: $baseUrl/api/reports/$id');

      final response = await _dio.post(
        '/api/reports/$id',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode != 200) {
        final errorMessage = response.data?['message'] ?? 'Failed to update report';
        throw Exception(errorMessage);
      }

      // Successfully updated
      print('Report updated successfully');
    } on DioException catch (e) {
      print('Dio error: ${e.message}');
      print('Response error: ${e.response?.data}');

      final errorMessage = e.response?.data?['message'] ?? 'Error updating report';
      throw Exception(errorMessage);
    } catch (e) {
      print('General error: $e');
      throw Exception('Error updating report: $e');
    }
  }

  // Future<List<String>> getTrucks() async {
  //   try {
  //     print('Fetching trucks...');
  //     final response = await _dio.get('/api/trucks');
  //     print('Trucks Response: ${response.data}');
  //
  //     if (response.data != null && response.data['truckData'] != null) {
  //       final List<dynamic> truckData = response.data['truckData'];
  //       return truckData
  //           .map((truck) => truck['truck_no'].toString())
  //           .toList();
  //     }
  //     return [];
  //   } on DioException catch (e) {
  //     print('Truck Fetch Error: ${e.message}');
  //     throw Exception('Failed to fetch trucks: ${e.message}');
  //   }
  // }
  Future<void> downloadFile(String id, String field, String? originalName) async {
    if (originalName == null || originalName.isEmpty) {
      throw Exception('Invalid file name');
    }

    try {
      final url = '$baseUrl/api/download/$id/$field';
      print('Downloading from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': '*/*',
          // Add any other required headers
        },
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$originalName';

        print('Saving file to: $filePath');

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception('Failed to open file: ${result.message}');
        }
      } else {
        // Parse error message from response if available
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Unknown error occurred';
        } catch (e) {
          errorMessage = 'Error downloading file (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Download error details: $e');
      rethrow;
    }
  }


  Future<List<String>> getVendors() async {
    try {
      print('Fetching vendors from: ${_dio.options.baseUrl}/api/vendors');

      final response = await _dio.get(
        '/api/vendors',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('Vendors Response: ${response.data}');

      if (response.data != null && response.data['vendorData'] != null) {
        final List<dynamic> vendors = response.data['vendorData'];
        final List<String> vendorNames = vendors
            .where((vendor) => vendor['company_name'] != null)
            .map((vendor) => vendor['company_name'].toString())
            .toList();

        print('Parsed Vendor Names: $vendorNames');
        return vendorNames;
      }

      print('No vendor data found in response');
      return [];
    } on DioException catch (e) {
      print('Vendor Fetch Error: ${e.message}');
      print('Error Type: ${e.type}');
      print('Error Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      throw Exception('Failed to fetch vendors: ${e.message}');
    } catch (e) {
      print('Unexpected error in getVendors: $e');
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  Future<List<String>> getTrucks() async {
    try {
      print('Fetching trucks from: ${_dio.options.baseUrl}/api/trucks');

      final response = await _dio.get(
        '/api/trucks',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('Trucks Response: ${response.data}');

      if (response.data != null && response.data['truckData'] != null) {
        final List<dynamic> trucks = response.data['truckData'];
        final List<String> truckNumbers = trucks
            .where((truck) => truck['truck_no'] != null)
            .map((truck) => truck['truck_no'].toString())
            .toList();

        print('Parsed Truck Numbers: $truckNumbers');
        return truckNumbers;
      }

      print('No truck data found in response');
      return [];
    } on DioException catch (e) {
      print('Truck Fetch Error: ${e.message}');
      print('Error Type: ${e.type}');
      print('Error Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      }
      throw Exception('Failed to fetch trucks: ${e.message}');
    } catch (e) {
      print('Unexpected error in getTrucks: $e');
      throw Exception('Failed to fetch trucks: $e');
    }
  }
}



