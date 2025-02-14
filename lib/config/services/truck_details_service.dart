import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/truck_details_model.dart';
import 'package:http/http.dart' as http;

class LogisticsService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://shreelalchand.com/logistics',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));


  Future<List<String>> fetchTrucks(String query) async {
    try {
      final response = await _dio.get('/api/trucks');
      final List trucks = response.data['truckData'];
      return trucks
          .where((truck) => truck['truck_no']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .map((truck) => truck['truck_no'].toString())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trucks');
    }
  }

  Future<List<String>> fetchVendors(String query) async {
    try {
      final response = await _dio.get('/api/vendors');
      final List vendors = response.data['vendorData'];
      return vendors
          .where((vendor) => vendor['company_name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .map((vendor) => vendor['company_name'].toString())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors');
    }
  }

  Future<List<Map<String, dynamic>>> fetchDestinations(String query) async {
    try {
      final response = await _dio.get('/api/destination');
      final List destinations = response.data['destinationData'];
      return destinations
          .where((dest) =>
      dest['from'].toString().toLowerCase().contains(query.toLowerCase()) ||
          dest['to'].toString().toLowerCase().contains(query.toLowerCase()))
          .map((dest) => {
        'from': dest['from'].toString(),
        'to': dest['to'].toString(),
        'rate': dest['rate'],
      })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch destinations');
    }
  }

  Future<double> fetchTdsRate(String vendor) async {
    try {
      final response = await _dio.get('/api/vendors');
      final List vendors = response.data['vendorData'];
      final vendorData = vendors.firstWhere(
              (v) => v['company_name'].toString().toLowerCase() == vendor.toLowerCase(),
          orElse: () => null);
      return vendorData != null ? vendorData['tds_rate'].toDouble() : 0.0;
    } catch (e) {
      throw Exception('Failed to fetch TDS rate');
    }
  }

  Future<void> submitTruckDetails(TripDetails details) async {
    try {
      Response response= await _dio.post(
          'https://shreelalchand.com/logistics/reports',
          data: details.toJson()
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Truck details submitted successfully');
      } else {
        throw Exception('Failed to submit truck details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to submit truck details');
    }
  }



  //add changes here
  // Future<void> updateTruckDetails(TripDetails details) async {
  //   try {
  //     Map<String, dynamic> updateData = details.toJson();
  //     Response response = await _dio.post(
  //         'http://10.0.2.2:5000/logistics/api/trip',
  //         data: updateData,
  //         options: Options(
  //           headers: {'Content-Type': 'application/json'},
  //         ),
  //     );
  //     if (response.statusCode == 200) {
  //       print('Truck details updated successfully');
  //     } else {
  //       throw Exception(
  //           'Failed to update truck details: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to submit truck details');
  //   }
  // }

  // static Future<void> updateTruckDetails(TripDetails details) async {
  //   final response = await http.post(
  //     Uri.parse('http://10.0.2.2:5000/logistics/api/trip'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode(details.toJson()),
  //   );
  //   if (response.statusCode != 201) {
  //     throw Exception('Failed to add freight data');
  //   }
  // }
}