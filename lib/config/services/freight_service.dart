import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/freight_model.dart';


class FreightService {
  static const String baseUrl = 'http://shreelalchand.com/logistics';

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
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(freight.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add freight data');
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