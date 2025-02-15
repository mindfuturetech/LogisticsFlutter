// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../model/truck_details_model.dart';

// class TripService {
//   final String baseUrl = 'http://localhost:5000/logistics/api/trip';
//
//   Future<TripDetails> getTripById(String id) async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/$id'));
//
//       if (response.statusCode == 200) {
//         return TripDetails.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Failed to load trip');
//       }
//     } catch (e) {
//       throw Exception('Error: $e');
//     }
//   }
// }

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:logistics/config/model/truck_details_model.dart';

class ApiSearchService {
  // static const String baseUrl = 'http://localhost:5000/logistics';

  Future<TripDetails?> searchUserById(String id) async {
    print("$id");
    try {
      final response = await http.get(
        Uri.parse('http://shreelalchand.com/logistics/api/trip/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      print(TripDetails.fromJson(json.decode(response.body)));
      print("Response status code: ${response.statusCode}"); // Debug log
      print("Response body: ${response.body}"); // Debug log

      if (response.contentLength!=0) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final Map<String, dynamic> tripData = decodedData["TripData"];
        return TripDetails.fromJson(tripData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to search user: $e');
    }
  }
}
