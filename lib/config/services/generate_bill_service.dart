import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/model/truck_details_model.dart';

class BillService {
  static const String baseUrl = 'http://10.0.2.2:5000/logistics';

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

  // Function to generate PDF and update transaction status
  Future<void> generatePDF(List<Map<String, dynamic>> selectedTrucks) async {
    if (selectedTrucks.isEmpty) {
      throw Exception('No trucks selected to generate the PDF.');
    }

    final Uri url = Uri.parse('$baseUrl/generate-pdf-bill');

    try {
      // Prepare the payload similar to Node.js implementation
      final payload = selectedTrucks.map((truck) => {
        'id': truck['id'],
        'transaction_status': 'Billed'
      }).toList();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'GeneratedBill_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory.path}/$fileName';

        // Write PDF to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the generated PDF
        await OpenFile.open(filePath);

        return;
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  // Function to get current bill ID
  Future<int> getCurrentBillId() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/current-bill-id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['currentBillId'] ?? 1;
      } else {
        throw Exception('Failed to get current bill ID');
      }
    } catch (e) {
      throw Exception('Error fetching current bill ID: $e');
    }
  }

  // Function to format bill data
  Map<String, dynamic> formatBillData(TripDetails trip) {
    final now = DateTime.now();
    return {
      'date': DateFormat('yyyy-MM-dd').format(now),
      'time': DateFormat('hh:mm a').format(now),
      'vendor': trip.vendor,
      'destinationTo': trip.destinationTo,
      'truckNumber': trip.truckNumber?.replaceAll(' ', ''),
      'weight': trip.weight,
      'actualWeight': trip.actualWeight,
      'rate': calculateRate(trip.freight, trip.weight),
      'freight': trip.freight,
      'dieselAmount': trip.dieselAmount,
      'advance': trip.advance ?? 0,
      'toll': trip.toll ?? 0,
      'tdsRate': trip.tdsRate ?? 0,
      'amount': calculateAmount(trip),
    };
  }

  // Helper function to calculate rate
  double calculateRate(double? freight, double? weight) {
    if (freight == null || weight == null || weight == 0) return 0;
    return (freight / weight).ceil().toDouble();
  }

  // Helper function to calculate final amount
  double calculateAmount(TripDetails trip) {
    if (trip.freight == null) return 0;

    final freight = trip.freight!;
    final dieselAmount = trip.dieselAmount ?? 0;
    final advance = trip.advance ?? 0;
    final toll = trip.toll ?? 0;
    final tdsRate = trip.tdsRate ?? 0;

    final tdsAmount = freight * (tdsRate / 100);
    final totalDeductions = dieselAmount + advance + toll + tdsAmount;

    return (freight - totalDeductions);
  }
}
