import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http_parser/http_parser.dart';

import '../model/vehicle_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/logistics'; // Use your IP address for real device

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vehicle'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      throw Exception('Error: $e');
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

      request.fields['truckNo'] = truckNo;
      request.fields['make'] = make;
      request.fields['companyOwner'] = companyOwner;

      // Add document dates
      documents.forEach((key, value) {
        request.fields['${key}_startDate'] = value['startDate'];
        request.fields['${key}_endDate'] = value['endDate'];
      });

      // Add files
      for (var entry in files.entries) {
        if (entry.value.isNotEmpty) {
          var file = await http.MultipartFile.fromPath(
            entry.key,
            entry.value,
            contentType: MediaType('application', 'pdf'),
          );
          request.files.add(file);
        }
      }

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to add vehicle');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> downloadFile(String truckNo, String fieldName, String fileName) async {
    final url = '$baseUrl/download/$truckNo/$fieldName/$fileName';
    // Implement file download using path_provider package
    // Store the file in app's documents directory
  }
}
