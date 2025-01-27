import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import '../model/vehicle_model.dart';

class VehicleService {
  static const String baseUrl = 'http://192.168.130.219:5000/logistics'; // Use your IP address for real device
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vehicle'));

      if (response.statusCode == 200) {
        print('API Response: ${response.body}');

        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('resultData')) {
          final List<dynamic> data = jsonResponse['resultData'];
          return data.map((json) => Vehicle.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error loading vehicles: $e');
    }
  }
  Future<void> addVehicle(
      String truckNo,
      String make,
      String companyOwner,
      Map<String, Map<String, dynamic>> documents,
      Map<String, String> files,
      ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/add-vehicle'));

      // Add basic vehicle details
      final fields = {
        'truckNo': truckNo,
        'make': make,
        'companyOwner': companyOwner,
      };
      request.fields.addAll(fields);

      // Add document dates with null checks
      documents.forEach((key, value) {
        if (value['startDate'] != null && value['startDate'].isNotEmpty) {
          request.fields['${key}_startDate'] = value['startDate'];
        }
        if (value['endDate'] != null && value['endDate'].isNotEmpty) {
          request.fields['${key}_endDate'] = value['endDate'];
        }
      });

      // Add files with proper error handling
      for (var entry in files.entries) {
        if (entry.value.isNotEmpty) {
          try {
            var file = await http.MultipartFile.fromPath(
              entry.key,
              entry.value,
              contentType: MediaType('application', 'pdf'),
            );
            request.files.add(file);
          } catch (e) {
            throw Exception('Error adding file ${entry.key}: $e');
          }
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw HttpException('Failed to add vehicle: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  // Enhanced download method with progress tracking
  Future<void> downloadFile(String truckNo, String fieldName, String fileName) async {
    final url = '$baseUrl/download/$truckNo/$fieldName/$fileName';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Implement file saving logic here
      } else {
        throw HttpException('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }
}