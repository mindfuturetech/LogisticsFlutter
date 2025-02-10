import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/model/freight_model.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import '../../config/services/search_service.dart';
import '../../widget/custom_drawer.dart';
import 'home_screen.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final ReportsService _reportsService = ReportsService();
  final TextEditingController _truckController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  List<TripDetails> reports = [];
  List<String> trucks = [];
  bool isLoading = false;
  double grandTotal = 0.0;
  String baseUrl = 'http://10.0.2.2:5000/logistics';
  List<Freight> destinations = [];
  List<Freight> report = [];
  // final SearchService _searchService = SearchService();


  final dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchTrucks();
    _fetchDestinations();


  }
  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedReports = await _reportsService.getReports();  // Replace with your actual API call
      setState(() {
        reports = loadedReports;
        _calculateGrandTotal();
      });
    } catch (e) {
      _showErrorDialog('Error loading reports: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateGrandTotal() {
    grandTotal = reports.fold(0.0, (sum, report) => sum + calculateTripTotal(report));
  }
  Future<void> _fetchDestinations() async {
    try {
      final response = await dio.get('$baseUrl/api/destination');
      if (response.data['destinationData'] != null) {
        setState(() {
          destinations = (response.data['destinationData'] as List)
              .map((item) => Freight.fromJson(item))
              .toList();
        });
      }
    } catch (error) {
      print('Error fetching destination data: $error');
      _showErrorDialog('Error fetching destination rates');
    }
  }

  Future<void> _fetchTrucks() async {
    try {
      final trucksList = await _reportsService.getTrucks();
      setState(() {
        trucks = trucksList;
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch trucks: $e');
    }
  }

  double? findDestinationRate(String from, String to) {
    try {
      return destinations.firstWhere(
            (dest) =>
        dest.from.toLowerCase() == from.toLowerCase() &&
            dest.to.toLowerCase() == to.toLowerCase(),
        orElse: () => Freight(from: '', to: '', rate: 0),
      ).rate;
    } catch (e) {
      return 0.0;
    }
  }

  double calculateTripTotal(TripDetails report) {
    final rate = findDestinationRate(
      report.destinationFrom ?? '',
      report.destinationTo ?? '',
    );

    final freight = report.freight ?? 0.0;
    final differenceInWeight = report.differenceInWeight ?? 0.0;
    final dieselAmount = report.dieselAmount ?? 0.0;
    final advance = report.advance ?? 0.0;
    final toll = report.toll ?? 0.0;
    final adblue = report.adblue ?? 0.0;
    final greasing = report.greasing ?? 0.0;

    return freight -
        (differenceInWeight * (rate ?? 0.0)) -
        dieselAmount -
        advance -
        toll -
        adblue -
        greasing;
  }

  Future<void> _fetchReports() async {
    if ((startDate == null || endDate == null) && _truckController.text.isEmpty) {
      _showErrorDialog('Please select at least one filter');
      return;
    }

    if ((startDate != null && endDate != null) && _truckController.text.isEmpty) {
      _showErrorDialog('Please select a truck number');
      return;
    }

    setState(() {
      isLoading = true;
      grandTotal = 0.0;
    });

    try {
      final results = await _reportsService.getReports(
        startDate: startDate,
        endDate: endDate,
        truckNumber: _truckController.text,
      );

      if (results.isEmpty) {
        _showErrorDialog('No records available');
      }

      setState(() {
        reports = results;
        // Calculate grand total
        grandTotal = results.fold(
            0.0,
                (total, report) => total + calculateTripTotal(report)
        );
      });
    } catch (e) {
      _showErrorDialog('Error fetching reports: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      controller: TextEditingController(
        text: value != null ? DateFormat('yyyy-MM-dd').format(value) : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
    );
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  Future<void> _downloadExcel() async {
    if (reports.isEmpty) {
      _showErrorDialog('No data available to download');
      return;
    }

    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          _showErrorDialog('Storage permission is required to download the file');
          return;
        }
      }

      setState(() {
        isLoading = true;
      });

      // Create Excel document
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Reports'];

      // Add headers
      final headers = [
        'DO Number',
        'Date',
        'Truck Number',
        'Driver Name',
        'Vendor',
        'From',
        'To',
        'Status',
        'Weight',
        'Actual Weight',
        'Difference',
        'Rate',
        'Freight',
        'Diesel Amount',
        'Advance',
        'Toll',
        'AdBlue',
        'Greasing',
        'Total'
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = headers[i]
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            backgroundColorHex: '#CCCCCC',
          );
      }

      // Add data
      for (var i = 0; i < reports.length; i++) {
        final report = reports[i];
        final rate = findDestinationRate(
          report.destinationFrom ?? '',
          report.destinationTo ?? '',
        );
        final total = calculateTripTotal(report);

        final rowData = [
          report.doNumber ?? 'N/A',
          DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt ?? DateTime.now()),
          report.truckNumber ?? 'N/A',
          report.driverName ?? 'N/A',
          report.vendor ?? 'N/A',
          report.destinationFrom ?? 'N/A',
          report.destinationTo ?? 'N/A',
          report.transactionStatus ?? 'N/A',
          report.weight?.toString() ?? '0',
          report.actualWeight?.toString() ?? '0',
          report.differenceInWeight?.toString() ?? '0',
          rate?.toString() ?? '0',
          report.freight?.toString() ?? '0',
          report.dieselAmount?.toString() ?? '0',
          report.advance?.toString() ?? '0',
          report.toll?.toString() ?? '0',
          report.adblue?.toString() ?? '0',
          report.greasing?.toString() ?? '0',
          total.toStringAsFixed(2),
        ];

        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
            ..value = rowData[j]
            ..cellStyle = dataStyle;
        }
      }

      // Add grand total row
      final totalRowIndex = reports.length + 1;
      final totalStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        backgroundColorHex: '#E8E8E8',
      );

      sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: headers.length - 1,
        rowIndex: totalRowIndex,
      ))
        ..value = grandTotal.toStringAsFixed(2)
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );

      // Set column widths
      for (var i = 0; i < headers.length; i++) {
        sheet.setColWidth(i, 15.0); // Using correct method name
      }

      // Generate file name with timestamp
      final now = DateTime.now();
      final fileName = 'business_report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

      // Get download directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      // Save file
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      setState(() {
        isLoading = false;
      });

      // Show success message with file path
      _showSuccessDialog('File downloaded successfully!\nLocation: ${file.path}');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error downloading file: ${e.toString()}');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
// Data cell style
  final dataStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  // // Add the handler method for trip ID clicks
  // Future<void> _handleTripIdClick(String tripId) async {
  //   if (tripId.isEmpty) return;
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     final tripDetails = await _searchService.searchByTripId(tripId);
  //
  //     // Navigate to home page with the trip details
  //     if (!mounted) return;
  //
  //     context.go('/', extra: tripDetails);
  //   } catch (e) {
  //     if (!mounted) return;
  //
  //     _showErrorDialog('Failed to fetch trip details: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        actions: [
          Visibility(
            visible: !isLoading && reports.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadExcel,
              tooltip: 'Download Excel',
            ),
          ),
        ],
      ),

      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Filters Section
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Start Date',
                          value: startDate,
                          onChanged: (date) => setState(() => startDate = date),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          label: 'End Date',
                          value: endDate,
                          onChanged: (date) => setState(() => endDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return trucks.where((truck) => truck.toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _truckController.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Truck Number',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchReports,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),

          // Reports Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                ? const Center(child: Text('No reports to display'))
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text('DO: ${report.doNumber ?? "N/A"}'),
                          subtitle: Text(
                            'Truck: ${report.truckNumber} - ${DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt ?? DateTime.now())}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('TripId', report.tripId,isTripId:true),
                                  _buildInfoRow('Driver', report.driverName),
                                  _buildInfoRow('Vendor', report.vendor),
                                  _buildInfoRow('From', report.destinationFrom),
                                  _buildInfoRow('To', report.destinationTo),
                                  _buildInfoRow('Status', report.transactionStatus),
                                  _buildInfoRow('Weight', '${report.weight ?? 0}'),
                                  _buildInfoRow('Actual Weight', '${report.actualWeight ?? 0}'),
                                  _buildInfoRow('Difference', '${report.differenceInWeight ?? 0}'),
                                  _buildInfoRow('Rate', '₹${findDestinationRate(report.destinationFrom ?? '', report.destinationTo ?? '')}'),
                                  _buildInfoRow('Freight', '₹${report.freight ?? 0}'),
                                  _buildInfoRow('Diesel Amount', '₹${report.dieselAmount ?? 0}'),
                                  _buildInfoRow('Advance', '₹${report.advance ?? 0}'),
                                  _buildInfoRow('Toll', '₹${report.toll ?? 0}'),
                                  _buildInfoRow('AdBlue', '₹${report.adblue ?? 0}'),
                                  _buildInfoRow('Greasing', '₹${report.greasing ?? 0}'),
                                  _buildInfoRow('Total', '₹${calculateTripTotal(report).toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Grand Total
                if (reports.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReportsList() {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(report.doNumber ?? 'N/A'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('yyyy-MM-dd HH:mm')
                    .format(report.createdAt ?? DateTime.now())),
                Text('Truck: ${report.truckNumber ?? 'N/A'}'),
                Text('Driver: ${report.driverName ?? 'N/A'}'),
              ],
            ),
            trailing: Text(
              '₹${calculateTripTotal(report).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value,{bool isTripId=false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: isTripId
                ? InkWell(
              onTap: () async {
                try {
                  final searchService = ApiSearchService();
                  final tripDetails = await searchService.searchUserById(value ?? '');

                  if (!mounted) return;

                  if (tripDetails != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TruckDetailsScreen(
                          username: tripDetails.username ?? '',
                          initialTripDetails: tripDetails,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No trip details found for ID: $value'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error fetching trip details: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                value ?? 'N/A',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            )
                : Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _truckController.dispose();
    super.dispose();
  }
}
