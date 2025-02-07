import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logistics/screens/auth/report_card_screen.dart';
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
  bool _isLoadingDropdowns = false;
  String? _loadingError;
  String? _errorMessage;

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
                        const SizedBox(width: 16),
                        Expanded(child: _buildTruckInput()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchReports,
                      child: const Text('Search'),
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
  Widget _buildFilters() {
    return Card(
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
                Expanded(
                  child: _buildVendorInput(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTruckInput(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _fetchReports,
                  child: const Text('Search'),
                ),
                // ElevatedButton(
                //   onPressed: _fetchTodayReports,
                //   child: const Text('Today\'s List'),
                // ),
              ],
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





