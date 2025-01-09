import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/vendor_model.dart';

class VendorService {
  static const String baseUrl = 'http://10.0.2.2:5000/logistics';

  Future<List<VendorModel>> getVendorList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vendor'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');  // Log the response body to see its structure

      if (response.statusCode == 200) {
        // Assuming the response body is wrapped in an object, e.g., { "vendors": [...] }
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('vendors')) {
          List<dynamic> vendorData = data['vendors'];
          return vendorData.map((json) => VendorModel.fromJson(json)).toList();
        } else {
          throw Exception('No vendor data found');
        }
      } else {
        throw Exception('Failed to load vendor data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }



  // In vendor_service.dart, modify the addVendor method:
  // In vendor_service.dart, enhance the addVendor method with more logging:
  Future<void> addVendor(VendorModel vendor) async {
    try {
      final requestBody = json.encode({
        'companyName': vendor.companyName,
        'companyOwner': vendor.companyOwner,
        'tdsRate': vendor.tdsRate,
        'pan': vendor.pan,
        'gst': vendor.gst,
      });

      print('Request URL: $baseUrl/add-vendor');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/add-vendor'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to add vendor: ${response.body}');
      }

      // Try to parse the response to ensure it's valid
      final responseData = json.decode(response.body);
      print('Parsed Response: $responseData');
    } catch (e) {
      print('Exception in addVendor: $e');
      throw Exception('Error: $e');
    }
  }
}