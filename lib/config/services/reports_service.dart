// reports_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../model/truck_details_model.dart';
import 'package:path/path.dart' as path;


class ReportsService {
  final Dio _dio;
  final String baseUrl = 'https://shreelalchand.com/logistics';
  // Constructor with flexible base URL
  ReportsService({String? baseUrl}) : _dio = Dio(BaseOptions(
    // Use platform-aware base URL
    baseUrl: baseUrl ?? getPlatformSpecificBaseUrl(),
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
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
        'sort': 'createdAt',  // Add sorting parameter
        'order': 'desc'       // Specify descending order
      };

      print('Fetching reports with filters:');
      print('Start Date: ${queryParams['startDate']}');
      print('End Date: ${queryParams['endDate']}');
      print('Vendor: ${queryParams['vendor']}');
      print('Truck: ${queryParams['truckNumber']}');
      print('Sort: ${queryParams['sort']}');
      print('Order: ${queryParams['order']}');
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
        List<TripDetails> reports = tableData.map((json) => TripDetails.fromJson(json)).toList();

        // Additional client-side sorting as a fallback
        reports.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        return reports;
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
      double actualWeight, // ✅ Change to Double
      String transactionStatus,
      Map<String, File?> files) async {
    try {
      var uri = '$baseUrl/api/reports/$id';
      FormData formData = FormData();

      // Add text fields
      formData.fields.addAll([
        MapEntry("id", id),
        MapEntry("transactionStatus", transactionStatus),
        MapEntry("weight", weight.toString()),
        MapEntry("actualWeight", actualWeight.toString()), // ✅ Convert Double to String
      ]);

      // Add files if they exist - with proper content type handling
      for (var entry in files.entries) {
        if (entry.value != null) {
          String fileName = entry.value!.path.split('/').last;
          String mimeType = 'application/octet-stream'; // Default

          // Set proper mime type for PDFs
          if (fileName.toLowerCase().endsWith('.pdf')) {
            mimeType = 'application/pdf';
          }

          formData.files.add(MapEntry(
            entry.key,
            await MultipartFile.fromFile(
              entry.value!.path,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            ),
          ));
        }
      }

      // Use POST with appropriate headers
      var response = await _dio.post(
        uri,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          // Increase timeout to 60 seconds (or adjust as needed)
          receiveTimeout: const Duration(seconds: 140),
          sendTimeout: const Duration(seconds: 140),

        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update report: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error updating report: $e');
    }
  }

  // Future<void> updateReport(
  //     String id,
  //     double weight,
  //     double actualWeight,
  //     String transactionStatus,
  //     Map<String, dynamic> uploadedFiles,
  //     ) async {
  //   try {
  //     print('Updating report with ID: $id');
  //
  //     // Create FormData instance
  //     final formData = FormData();
  //
  //     // Add basic fields
  //     formData.fields.addAll([
  //       MapEntry('id', id),
  //       MapEntry('transactionStatus', transactionStatus),
  //       MapEntry('weight', weight.toString()),
  //       MapEntry('actualWeight', actualWeight.toString()),
  //     ]);
  //
  //     // Add files with specific field names matching backend
  //     final validFileFields = [
  //       'DieselSlipImage',
  //       'LoadingAdvice',
  //       'InvoiceCompany',
  //       'WeightmentSlip'
  //     ];
  //
  //     for (var entry in uploadedFiles.entries) {
  //       if (validFileFields.contains(entry.key)) {
  //         print('Adding file for field: ${entry.key}');
  //
  //         // Handle the file data correctly based on structure
  //         if (entry.value is Map) {
  //           // If uploadedFiles contains response data from uploadFile method
  //           if (entry.value['data'] != null && entry.value['data']['filepath'] != null) {
  //             // If the backend returns a filepath, you might want to send that rather than the original file
  //             formData.fields.add(MapEntry(entry.key, entry.value['data']['filepath']));
  //           }
  //         } else if (entry.value is File) {
  //           // If uploadedFiles contains File objects
  //           final file = await MultipartFile.fromFile(
  //             entry.value.path,
  //             filename: path.basename(entry.value.path),
  //             contentType: MediaType('application', 'pdf'),
  //           );
  //           formData.files.add(MapEntry(entry.key, file));
  //         } else {
  //           // Skip invalid entries
  //           print('Skipping invalid entry for ${entry.key}: ${entry.value.runtimeType}');
  //         }
  //       }
  //     }
  //
  //     print('Sending request to: $baseUrl/api/reports/$id');
  //
  //     final response = await _dio.post(
  //       '/api/reports/$id',
  //       data: formData,
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'multipart/form-data',
  //         },
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );
  //
  //     print('Response status: ${response.statusCode}');
  //     print('Response data: ${response.data}');
  //
  //     if (response.statusCode != 200) {
  //       final errorMessage = response.data?['message'] ?? 'Failed to update report';
  //       throw Exception(errorMessage);
  //     }
  //
  //     // Successfully updated
  //     print('Report updated successfully');
  //   } on DioException catch (e) {
  //     print('Dio error: ${e.message}');
  //     print('Response error: ${e.response?.data}');
  //
  //     final errorMessage = e.response?.data?['message'] ?? 'Error updating report';
  //     throw Exception(errorMessage);
  //   } catch (e) {
  //     print('General error: $e');
  //     throw Exception('Error updating report: $e');
  //   }
  // }

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
  // Future<void> downloadFile(String id, String field, String? originalName) async {
  //   if (originalName == null || originalName.isEmpty) {
  //     throw Exception('Invalid file name');
  //   }
  //
  //   try {
  //     final url = '$baseUrl/api/download/$id/$field';
  //     print('Downloading from: $url');
  //
  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {
  //         'Accept': '*/*',
  //         // Add any other required headers
  //       },
  //     );
  //
  //     print('Response status: ${response.statusCode}');
  //
  //     if (response.statusCode == 200) {
  //       final directory = await getTemporaryDirectory();
  //       final filePath = '${directory.path}/$originalName';
  //
  //       print('Saving file to: $filePath');
  //
  //       final file = File(filePath);
  //       await file.writeAsBytes(response.bodyBytes);
  //
  //       final result = await OpenFile.open(filePath);
  //       if (result.type != ResultType.done) {
  //         throw Exception('Failed to open file: ${result.message}');
  //       }
  //     } else {
  //       // Parse error message from response if available
  //       String errorMessage;
  //       try {
  //         final errorData = jsonDecode(response.body);
  //         errorMessage = errorData['message'] ?? 'Unknown error occurred';
  //       } catch (e) {
  //         errorMessage = 'Error downloading file (${response.statusCode})';
  //       }
  //       throw Exception(errorMessage);
  //     }
  //   } catch (e) {
  //     print('Download error details: $e');
  //     rethrow;
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
        // Get the downloads directory path, depending on platform
        final Directory downloadsDir;

        if (Platform.isAndroid) {
          // On Android, save to the Downloads folder
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
        } else if (Platform.isIOS) {
          // On iOS, save to Documents directory
          downloadsDir = await getApplicationDocumentsDirectory();
        } else {
          // Fallback for other platforms
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        // Create a unique filename to prevent overwriting
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final filename = '${path.basenameWithoutExtension(originalName)}_$timestamp${path.extension(originalName)}';
        final filePath = '${downloadsDir.path}/$filename';

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
  // Method to upload a single file
  Future<Map<String, dynamic>?> uploadFile(File file, String field) async {
    try {
      // Create form data
      String fileName = path.basename(file.path);
      FormData formData = FormData.fromMap({
        'field': field,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      });

      // Make the API call
      Response response = await _dio.post(
        '$baseUrl/upload',
        data: formData,
        options: Options(
          headers: {
            // Add any required headers
            'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Replace with actual token
            'Accept': 'application/pdf',
          },
        ),
        onSendProgress: (int sent, int total) {
          final progress = (sent / total * 100).toStringAsFixed(2);
          print('Upload Progress: $progress%');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('File uploaded successfully: $field');
        print('Response data: ${response.data}');

        return {
          'success': true,
          'data': response.data,
          'field': field,
          'originalname': fileName,
          'filepath': response.data['filepath'] ?? '',
        };
      } else {
        throw Exception('Failed to upload file. Status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio error uploading file: ${e.message}');
      print('Response error: ${e.response?.data}');

      // Handle Dio specific errors
      String errorMessage = 'Upload failed';

      if (e.response != null) {
        // Server responded with error
        errorMessage = e.response?.data?['message'] ?? 'Server error occurred';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timed out';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server not responding';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Failed to send request';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('General error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }
}



