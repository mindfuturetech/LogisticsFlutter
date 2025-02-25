import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/freight_model.dart';


class FreightService {
  static const String baseUrl = 'https://shreelalchand.com/logistics';

  static Future<List<Freight>> getFreightData() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Freight.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load freight data');
    }
  }

  static Future<void> addFreightData(Freight freight) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(freight.toJson()),
      );

      if (response.statusCode == 201) {
        return; // Success case
      }

      // Handle error response from backend
      final errorData = json.decode(response.body);
      throw errorData['message'] ?? 'Failed to add freight data';

    } catch (e) {
      // If it's already a String (from our throw above), return it directly
      if (e is String) {
        throw e;
      }
      // For parsing errors
      if (e is FormatException) {
        throw 'Invalid response from server';
      }
      // For network errors
      if (e is http.ClientException) {
        throw 'Connection failed. Please check your internet connection.';
      }
      // For any other unexpected errors
      throw 'Unable to add freight data. Please try again.';
    }
  }
}


// // Update freight rate
//   Future<void> updateFreight(Freight oldFreight, Freight newFreight) async {
//     try {
//       final prefs = await _prefs;
//       final List<String> existingDataString = prefs.getStringList(_storageKey) ?? [];
//
//       final List<Map<String, dynamic>> existingData = existingDataString
//           .map((string) => json.decode(string) as Map<String, dynamic>)
//           .toList();
//
//       final index = existingData.indexWhere((item) => item['id'] == oldFreight.id);
//
//       if (index != -1) {
//         existingData[index] = newFreight.toJson();
//
//         final updatedDataString = existingData
//             .map((data) => json.encode(data))
//             .toList();
//
//         await prefs.setStringList(_storageKey, updatedDataString);
//       }
//     } catch (e) {
//       print('Error updating freight: $e');
//       throw Exception('Failed to update freight');
//     }
//   }
// }