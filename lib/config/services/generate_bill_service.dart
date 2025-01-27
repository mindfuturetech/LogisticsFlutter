import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/model/truck_details_model.dart';

class BillService {
  static const String baseUrl = 'http://192.168.130.219:5000/logistics';

  Future<List<TripDetails>> getBillList({
    DateTime? startDate,
    DateTime? endDate,
    String? vendor,
    String? truckNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/list-billing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'vendor': vendor,
          'truckNumber': truckNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<TripDetails>.from(
          data['resultData'].map((x) =>
              TripDetails(
                truckNumber: x['TruckNumber'],
                doNumber: x['DONumber'],
                driverName: x['DriverName'],
                vendor: x['Vendor'],
                destinationFrom: x['DestinationFrom'],
                destinationTo: x['DestinationTo'],
                truckType: x['TruckType'],
                transactionStatus: x['TransactionStatus'],
                weight: x['Weight'].toDouble(),
                freight: x['Freight'].toDouble(),
                diesel: x['Diesel'].toDouble(),
                dieselAmount: x['DieselAmount'].toDouble(),
                dieselSlipNumber: x['DieselSlipNumber'],
                tdsRate: x['TDS_Rate'].toDouble(),
                advance: x['Advance'].toDouble(),
                toll: x['Toll'].toDouble(),
                adblue: x['Adblue'].toDouble(),
                greasing: x['Greasing'].toDouble(),
              )),
        );
      } else {
        throw Exception('Failed to load bill data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<String>> getVendorList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vendor'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(
          data['resultData'].map((vendor) => vendor['companyName']),
        );
      } else {
        throw Exception('Failed to load vendors');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<String>> getTruckList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list-vehicle'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(
          data['resultData'].map((truck) => truck['truck_no']),
        );
      } else {
        throw Exception('Failed to load trucks');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}