// todays_list_screen.dart
import 'package:flutter/material.dart';
import 'package:logistics/screens/auth/report_card_screen.dart';
import 'package:open_file/open_file.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class TodaysListScreen extends StatefulWidget {
  const TodaysListScreen({Key? key}) : super(key: key);

  @override
  _TodaysListScreenState createState() => _TodaysListScreenState();
}

class _TodaysListScreenState extends State<TodaysListScreen> {
  final ReportsService _reportsService = ReportsService();
  List<TripDetails> _reports = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchTodayReports();
  }
  Future<String> _getDownloadPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  Future<void> downloadExcel() async {
    try {
      setState(() => _isExporting = true);

      // Get download path
      final downloadPath = await _getDownloadPath();

      // Create Excel workbook
      var excel = Excel.createExcel();
      var sheet = excel['Sheet1'];

      // Add headers
      final headers = [
        'Date',
        'Time',
        'Trip ID',
        'Username',
        'Profile',
        'Truck Number',
        'DO Number',
        'Driver Name',
        'Vendor',
        'From',
        'To',
        'Truck Type',
        'Transaction Status',
        'Weight',
        'Actual Weight',
        'Difference in Weight',
        'Freight',
        'Diesel Amount',
        'Diesel Slip Number',
        'TDS Rate',
        'Advance',
        'Toll',
        'AdBlue',
        'Greasing',
      ];

      // Add headers to excel
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = headers[i];
      }

      // Add data
      for (var i = 0; i < _reports.length; i++) {
        var report = _reports[i];

        // Format date to a readable string
        String formattedDate = '';
        String formattedTime = '';

        if (report.createdAt != null) {
          formattedDate = DateFormat('dd/MM/yyyy').format(report.createdAt!.toLocal()); // Date only
          formattedTime = DateFormat('HH:mm').format(report.createdAt!.toLocal()); // Time only
        }


        // Row data in same order as headers
        final rowData = [
          formattedDate,
          formattedTime,
          report.tripId ?? '',                    // From json: 'TripID'
          report.username ?? '',                  // From json: 'username'
          report.profile ?? '',                   // From json: 'profile'
          report.truckNumber ?? '',               // From json: 'TruckNumber'
          report.doNumber ?? '',                  // From json: 'DONumber'
          report.driverName ?? '',                // From json: 'DriverName'
          report.vendor ?? '',                    // From json: 'Vendor'
          report.destinationFrom ?? '',           // From json: 'DestinationFrom'
          report.destinationTo ?? '',             // From json: 'DestinationTo'
          report.truckType ?? '',                 // From json: 'TruckType'
          report.transactionStatus ?? '',         // From json: 'TransactionStatus'
          report.weight?.toStringAsFixed(2) ?? '', // From json: 'Weight'
          report.actualWeight?.toStringAsFixed(2) ?? '', // From json: 'ActualWeight'
          report.differenceInWeight?.toStringAsFixed(2) ?? '', // From json: 'DifferenceInWeight'
          report.freight?.toStringAsFixed(2) ?? '', // From json: 'Freight'
          report.dieselAmount?.toStringAsFixed(2) ?? '', // From json: 'DieselAmount'
          report.dieselSlipNumber ?? '',          // From json: 'DieselSlipNumber'
          report.tdsRate?.toStringAsFixed(2) ?? '', // From json: 'TDS_Rate'
          report.advance?.toStringAsFixed(2) ?? '', // From json: 'Advance'
          report.toll?.toStringAsFixed(2) ?? '',   // From json: 'Toll'
          report.adblue?.toStringAsFixed(2) ?? '', // From json: 'Adblue'
          report.greasing?.toStringAsFixed(2) ?? '', // From json: 'Greasing'
                            // From json: 'BillId'
        ];

        // Add row data to excel
        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = rowData[j];
        }
      }

      final dateStr = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      final fileName = 'trip_reports_$dateStr.xlsx';
      final filePath = '$downloadPath/$fileName';

      // Save the file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Try to open the file
        await _openExcelFile(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File saved: $fileName'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving file. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
  Future<void> _openExcelFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      // Silently handle opening errors
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> _fetchTodayReports() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reports = await _reportsService.getReports(
        startDate: today,
        endDate: today,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch today\'s reports');
      setState(() => _isLoading = false);
    }
  }


  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Reports'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text(
                    'Download Today\'s List',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isExporting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.download),
                    onPressed: _isExporting ? null : downloadExcel,
                    tooltip: 'Download Excel',
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchTodayReports();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports found for today'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return ReportCard(report: report);
      },
    );
  }
}