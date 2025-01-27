import 'package:dio/dio.dart';

import '../model/truck_details_model.dart';

class LogisticsService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.130.219:5000/logistics',
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
      await _dio.post('/reports', data: details.toJson());
    } catch (e) {
      throw Exception('Failed to submit truck details');
    }
  }
}