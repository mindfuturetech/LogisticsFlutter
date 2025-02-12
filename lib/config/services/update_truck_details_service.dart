// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:logistics/config/model/truck_details_model.dart';
//
// class TruckService {
//   // static const String baseUrl = 'http://10.0.2.2:5000/logistics';
//
//   // Function to update truck details
//   Future<bool> updateTruckDetails(TripDetails details) async {
//     try {
//       Map<String, dynamic> updateData = details.toJson();
//
//       final response = await http.post(
//         Uri.parse('http://10.0.2.2:5000/logistics/api/trip'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(updateData), // Convert map to JSON string
//       );
//
//       print("Response Status Code: ${response.statusCode}");
//       print("Request Data: $updateData");
//
//       if (response.statusCode == 200) {
//         print('Truck details updated successfully');
//         return true;
//       } else {
//         print('Failed to update truck details: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       print('Failed to submit truck details: $e');
//       return false;
//     }
//   }
// }


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logistics/config/model/truck_details_model.dart';

class TruckService {
  static const String baseUrl = 'http://13.61.234.145/logistics';

  Future<bool> updateTruckDetails(TripDetails details) async {
    try {
      Map<String, dynamic> updateData = {
        'TripID': details.tripId != null ? int.tryParse(details.tripId.toString()) : null, // Ensure tripId is an integer
        'TruckNumber': details.truckNumber,
        'username': details.username,
        'userProfile': details.profile,
        'DONumber': details.doNumber!= null ? int.tryParse(details.doNumber.toString()) : null, // Ensure tripId is an integer
        'TransactionStatus': details.transactionStatus,
        'DriverName': details.driverName,
        'Vendor': details.vendor,
        'DestinationFrom': details.destinationFrom,
        'DestinationTo': details.destinationTo,
        'TruckType': details.truckType,
        'Weight': details.weight,
        'Freight': details.freight,
        'Diesel': details.diesel,
        'DieselAmount': details.dieselAmount,
        'DieselSlipNumber': details.dieselSlipNumber,
        'TDS_Rate': details.tdsRate,
        'Advance': details.advance,
        'Toll': details.toll,
        'Adblue': details.adblue,
        'Greasing': details.greasing,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/trip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Request Data: $updateData");

      if (response.statusCode == 200) {
        print('Truck details updated successfully');
        return true;
      } else {
        print('Failed to update truck details: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Failed to submit truck details: $e');
      return false;
    }
  }
}
