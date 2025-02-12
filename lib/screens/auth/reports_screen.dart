import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistics/screens/auth/report_card_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import '../../config/services/search_service.dart';
import 'home_screen.dart';

class ReportsScreen extends StatefulWidget {
  final Function()? onRefresh;

  const ReportsScreen({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}




class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  bool isEditing = false;
  bool isLoading = false;
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _truckController = TextEditingController();
  final FocusNode _vendorFocusNode = FocusNode();
  final FocusNode _truckFocusNode = FocusNode();

  List<TripDetails> _reports = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _vendors = [];
  List<String> _trucks = [];
  bool _showVendorSuggestions = false;
  bool _showTruckSuggestions = false;
  double weight = 0.00;
  late TextEditingController weightController;
  late TextEditingController actualWeightController;
  String? transactionStatus;
  String? selectedStatus;
  TripDetails? selectedReport;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController();
    actualWeightController = TextEditingController();
    _loadDropdownData();
    // Add listeners to controllers
    _vendorController.addListener(() {
      setState(() {}); // This will rebuild the widget when text changes
    });

    _truckController.addListener(() {
      setState(() {}); // This will rebuild the widget when text changes
    });
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _truckController.dispose();
    _vendorFocusNode.dispose();
    _truckFocusNode.dispose();
    super.dispose();
  }
  void _setupListeners() {
    _vendorFocusNode.addListener(() {
      if (_vendorFocusNode.hasFocus) {
        setState(() {
          _showVendorSuggestions = true;
          _showTruckSuggestions = false;
        });
      }
    });

    _truckFocusNode.addListener(() {
      if (_truckFocusNode.hasFocus) {
        setState(() {
          _showTruckSuggestions = true;
          _showVendorSuggestions = false;
        });
      }
    });

    _vendorController.addListener(() {
      if (_vendorFocusNode.hasFocus) {
        setState(() {
          _showVendorSuggestions = true;
        });
      }
    });

    _truckController.addListener(() {
      if (_truckFocusNode.hasFocus) {
        setState(() {
          _showTruckSuggestions = true;
        });
      }
    });
  }
  // Future<void> _loadDropdownData() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final vendors = await _reportsService.getVendors();
  //     final trucks = await _reportsService.getTrucks();
  //     setState(() {
  //       _vendors = vendors;
  //       _trucks = trucks;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     _showError('Failed to load dropdown data: ${e.toString()}');
  //   }
  // }
  Future<String> _getDownloadPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }



// Then update your downloadExcel method:
  Future<void> downloadExcel() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Get download path
      final downloadPath = await _getDownloadPath();

      // Create Excel workbook
      var excelWorkbook = excel.Excel.createExcel();
      var sheet = excelWorkbook['Sheet1'];

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
        sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = headers[i];
      }

      // Add data
      for (var i = 0; i < _reports.length; i++) {
        var report = _reports[i];

        // Format date to a readable string
        String formattedDate = '';
        String formattedTime = '';

        if (report.createdAt != null) {
          formattedDate = DateFormat('dd/MM/yyyy').format(report.createdAt!.toLocal());
          formattedTime = DateFormat('HH:mm').format(report.createdAt!.toLocal());
        }

        // Row data in same order as headers
        final rowData = [
          formattedDate,
          formattedTime,
          report.tripId ?? '',
          report.username ?? '',
          report.profile ?? '',
          report.truckNumber ?? '',
          report.doNumber ?? '',
          report.driverName ?? '',
          report.vendor ?? '',
          report.destinationFrom ?? '',
          report.destinationTo ?? '',
          report.truckType ?? '',
          report.transactionStatus ?? '',
          report.weight?.toStringAsFixed(2) ?? '',
          report.actualWeight?.toStringAsFixed(2) ?? '',
          report.differenceInWeight?.toStringAsFixed(2) ?? '',
          report.freight?.toStringAsFixed(2) ?? '',
          report.dieselAmount?.toStringAsFixed(2) ?? '',
          report.dieselSlipNumber ?? '',
          report.tdsRate?.toStringAsFixed(2) ?? '',
          report.advance?.toStringAsFixed(2) ?? '',
          report.toll?.toStringAsFixed(2) ?? '',
          report.adblue?.toStringAsFixed(2) ?? '',
          report.greasing?.toStringAsFixed(2) ?? '',
        ];

        // Add row data to excel
        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = rowData[j];
        }
      }

      final dateStr = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
      final fileName = 'trip_reports_$dateStr.xlsx';
      final filePath = '$downloadPath/$fileName';

      // Save the file
      final fileBytes = excelWorkbook.save();
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
      setState(() {
        _isExporting = false;
      });
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
  Future<void> _loadDropdownData() async {
    setState(() => _isLoading = true);

    try {
      final vendors = await _reportsService.getVendors();
      final trucks = await _reportsService.getTrucks();

      if (mounted) {
        setState(() {
          _vendors = vendors;
          _trucks = trucks;
          _isLoading = false;
        });
        print('Loaded Vendors: $_vendors'); // Debug print
        print('Loaded Trucks: $_trucks'); // Debug print
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }



  Future<void> _fetchReports() async {
    if (_startDate == null && _endDate == null &&
        _vendorController.text.isEmpty && _truckController.text.isEmpty) {
      _showError('Please select at least one filter');
      return;
    }
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        _showError('End date cannot be before start date');
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      print('Fetching reports with filters:');
      print('Start Date: $_startDate');
      print('End Date: $_endDate');
      print('Vendor: ${_vendorController.text}');
      print('Truck: ${_truckController.text}');

      final reports = await _reportsService.getReports(
        startDate: _startDate,
        endDate: _endDate,
        vendor: _vendorController.text.trim(),
        truckNumber: _truckController.text.trim(),
      );

      setState(() {
        _reports = reports;
        _showVendorSuggestions = false;
        _showTruckSuggestions = false;
      });

      if (_reports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No reports found for the selected filters'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in _fetchReports: $e');
      _showError(e.toString().replaceAll('Exception:', ''));
    } finally {
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
          label: 'Retry',
          onPressed: _loadDropdownData,
          textColor: Colors.white,
        ),
      ),
    );
  }

  List<String> _getFilteredVendors() {
    final query = _vendorController.text.toLowerCase();
    return _vendors.where((vendor) =>
        vendor.toLowerCase().contains(query)
    ).toList();
  }

  List<String> _getFilteredTrucks() {
    final query = _truckController.text.toLowerCase();
    return _trucks.where((truck) =>
        truck.toLowerCase().contains(query)
    ).toList();
  }







  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        _vendorFocusNode.unfocus();
        _truckFocusNode.unfocus();
        setState(() {
          _showVendorSuggestions = false;
          _showTruckSuggestions = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Download',
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
                _fetchReports();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Start Date',
                            value: _startDate,
                            onChanged: (date) => setState(() => _startDate = date),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'End Date',
                            value: _endDate,
                            onChanged: (date) => setState(() => _endDate = date),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildVendorInput()),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTruckInput()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _fetchReports,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: const Color(0xFF5C2F95), // Purple shade
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReportsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInput() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _vendorController,
            decoration: InputDecoration(
              labelText: 'Vendor',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _vendorController.clear();
                    _showVendorSuggestions = false;
                  });
                },
              ),
            ),
            onTap: () {
              setState(() {
                _showVendorSuggestions = true;
                _showTruckSuggestions = false;
              });
            },
          ),
          if (_showVendorSuggestions && _getFilteredVendors().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _getFilteredVendors().length,
                itemBuilder: (context, index) {
                  final vendor = _getFilteredVendors()[index];
                  return ListTile(
                    title: Text(vendor),
                    onTap: () {
                      setState(() {
                        _vendorController.text = vendor;
                        _showVendorSuggestions = false;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTruckInput() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _truckController,
            decoration: InputDecoration(
              labelText: 'Truck Number',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _truckController.clear();
                    _showTruckSuggestions = false;
                  });
                },
              ),
            ),
            onTap: () {
              setState(() {
                _showTruckSuggestions = true;
                _showVendorSuggestions = false;
              });
            },
          ),
          if (_showTruckSuggestions && _getFilteredTrucks().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _getFilteredTrucks().length,
                itemBuilder: (context, index) {
                  final truck = _getFilteredTrucks()[index];
                  return ListTile(
                    title: Text(truck),
                    onTap: () {
                      setState(() {
                        _truckController.text = truck;
                        _showTruckSuggestions = false;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
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


  Widget _buildReportsList() {
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





