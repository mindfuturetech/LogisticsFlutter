import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/model/freight_model.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import '../../config/services/search_service.dart';
import '../../widget/custom_drawer.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


class BusinessScreen extends StatefulWidget {
  final TripDetails? tripDetails;
  final Freight? freight;
  const BusinessScreen({
    Key? key,
    this.tripDetails, this.freight, this.selectedFreight,  // Add this parameter
  }) : super(key: key);


  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
   final Freight? selectedFreight;
}

class _BusinessScreenState extends State<BusinessScreen> {
  final ReportsService _reportsService = ReportsService();
  final TextEditingController _truckController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  List<TripDetails> reports = [];
  List<TripDetails> _reports = [];
  List<String> trucks = [];
  bool isLoading = false;
  double grandTotal = 0.0;
  String baseUrl = 'http://13.61.234.145/logistics';
  List<Freight> destinations = [];
  List<Freight> model = [];
  // final SearchService _searchService = SearchService();
  bool _isExporting = false;
  Map<String, File?> selectedFiles = {};
  final dio = Dio();
  bool isEditing = false;
  bool isDownloading = false;
  final Map<String, bool> downloadingFiles = {};


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
    grandTotal = reports.fold(
        0.0,
            (sum, report) => sum + calculateTripTotal(report, destinations)
    );
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

  double calculateTripTotal(TripDetails report, List<Freight> freightList) {
    try {
      // Find the matching freight rate based on from and to locations
      final matchingFreight = freightList.firstWhere(
            (freight) =>
        freight.from.toLowerCase() == report.destinationFrom?.toLowerCase() &&
            freight.to.toLowerCase() == report.destinationTo?.toLowerCase(),
        orElse: () => Freight(from: '', to: '', rate: 0),
      );

      // Get rate from the matching freight
      final rate = matchingFreight.rate;

      // Safely handle all nullable values
      final freight = report.freight ?? 0.0;
      final tdsRate = report.tdsRate ?? 0.0;
      final dieselAmount = report.dieselAmount ?? 0.0;
      final advance = report.advance ?? 0.0;
      final toll = report.toll ?? 0.0;
      final adblue = report.adblue ?? 0.0;
      final greasing = report.greasing ?? 0.0;

      // Calculate TDS amount
      final tdsAmount = (freight * tdsRate) / 100;

      // Calculate final total using rate from matching freight
      final total = freight - tdsAmount - rate - dieselAmount -
          advance - toll - adblue - greasing;

      return total;
    } catch (e) {
      print('Error calculating trip total: $e');
      return 0.0;
    }
  }

  Future<void> _fetchReports() async {
    if ((startDate == null || endDate == null) && _truckController.text.isEmpty) {
      _showErrorDialog('Please select at least one filter');
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
        // Calculate grand total using the destinations list
        grandTotal = results.fold(
            0.0,
                (total, report) => total + calculateTripTotal(report, destinations)
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
  Future<void> _pickFile(String field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          selectedFiles[field] = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }





  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }


  // In _BusinessScreenState class, update the _buildFileField and _downloadFile methods:

  Widget _buildFileField(String label, String field, Map<String, dynamic>? fileData) {
    final bool isDownloadingThis = downloadingFiles[field] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: fileData != null && fileData['originalname'] != null
                ? TextButton.icon(
              onPressed: isDownloadingThis
                  ? null
                  : () => _downloadFile(
                field,
                fileData,
              ),
              icon: isDownloadingThis
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.file_download),
              label: Text(
                isDownloadingThis
                    ? 'Downloading...'
                    : fileData['originalname']?.toString() ?? 'Download',
              ),
            )
                : const Text('No file', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String field, Map<String, dynamic>? fileData) async {
    if (!mounted) return;

    // Check if we have valid file data
    if (fileData == null || fileData['originalname'] == null) {
      _showError('File information is missing');
      return;
    }

    // Get the current report's ID based on the context
    final reportId = reports.firstWhere(
          (report) => report.DieselSlipImage == fileData ||
          report.LoadingAdvice == fileData ||
          report.InvoiceCompany == fileData ||
          report.WeightmentSlip == fileData,
      orElse: () => TripDetails(),
    ).id;

    if (reportId == null) {
      _showError('Could not find report ID');
      return;
    }

    setState(() {
      downloadingFiles[field] = true;
    });

    try {
      print('Starting download - ID: $reportId, Field: $field, File: ${fileData['originalname']}');

      await _reportsService.downloadFile(
        reportId,
        field,
        fileData['originalname'],
      );

      if (mounted) {
        _showSuccess('File downloaded successfully');
      }
    } catch (e) {
      print('Download failed: $e');
      if (mounted) {
        _showError(e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() {
          downloadingFiles[field] = false;
        });
      }
    }
  }


  // Update your _buildFileField method to handle download state
  // Update your _buildFileField method to handle download stat
  // Widget _buildFileField(String label, String field, Map<String, dynamic>? fileData) {
  //   final bool isDownloadingThis = downloadingFiles[field] ?? false;
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4),
  //     child: Row(
  //       children: [
  //         SizedBox(
  //           width: 120,
  //           child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  //         ),
  //         Expanded(
  //           child: fileData != null && fileData['originalname'] != null
  //               ? TextButton.icon(
  //             onPressed: isDownloadingThis
  //                 ? null
  //                 : () => _downloadFile(
  //               widget.tripDetails?.id ?? '',
  //               field,
  //               fileData,
  //             ),
  //             icon: isDownloadingThis
  //                 ? const SizedBox(
  //               width: 20,
  //               height: 20,
  //               child: CircularProgressIndicator(strokeWidth: 2),
  //             )
  //                 : const Icon(Icons.file_download),
  //             label: Text(
  //               isDownloadingThis
  //                   ? 'Downloading...'
  //                   : fileData['originalname']?.toString() ?? 'Download',
  //             ),
  //           )
  //               : const Text('No file', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  // }





  // Future<void> _downloadFile(String id, String field,
  //     Map<String, dynamic>? fileData) async {
  //   if (!mounted) return;
  //
  //   // Check if we have valid file data
  //   if (fileData == null || fileData['originalname'] == null) {
  //     _showError('File information is missing');
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     print(
  //         'Starting download - ID: $id, Field: $field, File: ${fileData['originalname']}');
  //
  //     await _reportsService.downloadFile(
  //       id,
  //       field,
  //       fileData['originalname'],
  //     );
  //
  //     if (mounted) {
  //       _showSuccess('File downloaded successfully');
  //     }
  //   } catch (e) {
  //     print('Download failed: $e');
  //     if (mounted) {
  //       _showError(e.toString().replaceAll('Exception:', '').trim());
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => isLoading = false);
  //     }
  //   }
  // }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
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
              setState(() => isLoading = true);
              _fetchReports();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          _buildSearchFilters(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReportList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Card(
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
                const SizedBox(width: 16),
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
                return trucks.where((truck) => truck.toLowerCase().contains(textEditingValue.text.toLowerCase()));
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
    );
  }

  Widget _buildReportList() {
    if (reports.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final localDateTime = report.createdAt?.toLocal() ?? DateTime.now();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Truck Number: ${report.truckNumber ?? 'N/A'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(localDateTime),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('hh:mm a').format(localDateTime),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTripInformation(report),
                            const Divider(height: 32),
                            _buildFinancialInformation(report),
                            const SizedBox(height: 16),
                            _buildDocumentSection(report),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
    );
  }

  Widget _buildTripInformation(report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          children: [
            _buildInfoRow('Trip ID', report.tripId, isTripId: true),
            _buildInfoRow('DO Number', report.doNumber?.toString()),
            _buildInfoRow('User Name', report.username),
            _buildInfoRow('Profile', report.profile),
            _buildInfoRow('Driver', report.driverName),
            _buildInfoRow('Vendor', report.vendor),
            _buildInfoRow('From', report.destinationFrom),
            _buildInfoRow('To', report.destinationTo),
            _buildInfoRow('Bill ID', report.billingId),
            _buildInfoRow('Truck Type', report.truckType),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialInformation(report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          children: [
            _buildInfoRow('Diesel Amount', '₹${report.dieselAmount ?? 0}'),
            _buildInfoRow('Weight', report.weight?.toString()),
            _buildInfoRow('Difference', report.differenceInWeight?.toString()),
            _buildInfoRow('Freight', '₹${report.freight ?? 0}'),
            _buildInfoRow('Diesel Slip Number', report.dieselSlipNumber?.toString()),
            _buildInfoRow('TDS Rate', report.tdsRate?.toString()),
            _buildInfoRow('Advance', '₹${report.advance ?? 0}'),
            _buildInfoRow('Toll', '₹${report.toll ?? 0}'),
            _buildInfoRow('Adblue', '₹${report.adblue ?? 0}'),
            _buildInfoRow('Greasing', '₹${report.greasing ?? 0}'),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentSection(report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        _buildFileField('Diesel Slip', 'DieselSlipImage', report.DieselSlipImage),
        _buildFileField('Loading Advice', 'LoadingAdvice', report.LoadingAdvice),
        _buildFileField('Invoice', 'InvoiceCompany', report.InvoiceCompany),
        _buildFileField('Weightment Slip', 'WeightmentSlip', report.WeightmentSlip),
      ],
    );
  }



  // Widget _buildInfoRow(String label, String? value, {bool isTripId = false}) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontWeight: FontWeight.bold,
  //           color: Colors.grey,
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       isTripId
  //           ? GestureDetector(
  //         onTap: () async {
  //           try {
  //             final searchService = ApiSearchService();
  //             final tripDetails = await searchService.searchUserById(value ?? '');
  //
  //             if (!mounted) return;
  //
  //             if (tripDetails != null) {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => TruckDetailsScreen(
  //                     username: tripDetails.username ?? '',
  //                     initialTripDetails: tripDetails,
  //                   ),
  //                 ),
  //               );
  //             } else {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('No trip details found for ID: $value'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             }
  //           } catch (e) {
  //             if (!mounted) return;
  //
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(
  //                 content: Text('Error fetching trip details: $e'),
  //                 backgroundColor: Colors.red,
  //               ),
  //             );
  //           }
  //         },
  //         child: Text(
  //           value ?? 'N/A',
  //           style: const TextStyle(
  //             color: Colors.blue,
  //             fontSize: 16,
  //             fontWeight: FontWeight.w500,
  //           ),
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //       )
  //           : Text(
  //         value ?? 'N/A',
  //         style: const TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w500,
  //         ),
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //     ],
  //   );
  // }
  //
  Widget _buildInfoRow(String label, String? value, {bool isTripId = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        isTripId
            ? GestureDetector(
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
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        )
            : Text(
          value ?? 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }


  @override
  void dispose() {
    _truckController.dispose();
    super.dispose();
  }
}
