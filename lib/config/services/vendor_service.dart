import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/vendor_model.dart';

class VendorService {
  static const String baseUrl = 'https://shreelalchand.com/logistics';

  Future<List<VendorModel>> getVendorList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vendor'));
      print('Response status: ${response.statusCode}');
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse the response body
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extract the resultData array
        List<dynamic> resultData = jsonResponse['resultData'] ?? [];
        print('Found ${resultData.length} vendors in resultData');

        // Convert each item in resultData to a VendorModel
        List<VendorModel> vendors = resultData.map((item) =>
            VendorModel(
                companyName: item['companyName']?.toString() ?? '',
                companyOwner: item['companyOwner']?.toString() ?? '',
                tdsRate: (item['tdsRate'] is num)
                    ? (item['tdsRate'] as num).toDouble()
                    : double.tryParse(item['tdsRate']?.toString() ?? '0') ?? 0.0,
                pan: item['pan']?.toString() ?? '',
                gst: item['gst']?.toString() ?? ''
            )
        ).toList();

        print('Successfully converted ${vendors.length} vendors');
        return vendors;
      } else {
        throw Exception('Failed to load vendors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getVendorList: $e');
      throw Exception('Failed to load vendors: $e');
    }
  }

  Future<void> addVendor(VendorModel vendor) async {
    try {
      final requestBody = json.encode(vendor.toJson());

      final response = await http.post(
        Uri.parse('$baseUrl/add-vendor'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add vendor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding vendor: $e');
    }
  }
}