import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _truckController = TextEditingController();

  List<TripDetails> _reports = [];
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _vendors = [];
  List<String> _trucks = [];
  bool _showVendorSuggestions = false;
  bool _showTruckSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
    _fetchTodayReports();
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _truckController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final vendors = await _reportsService.getVendors();
      final trucks = await _reportsService.getTrucks();
      setState(() {
        _vendors = vendors;
        _trucks = trucks;
      });
    } catch (e) {
      _showError('Failed to load dropdown data');
    }
  }

  Future<void> _fetchTodayReports() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reports = await _reportsService.getReports(
        startDate: today,
        endDate: today,
      );
      setState(() => _reports = reports);
    } catch (e) {
      _showError('Failed to fetch today\'s reports');
    } finally {
      setState(() => _isLoading = false);
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
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }

  List<String> _getFilteredVendors() {
    if (_vendorController.text.isEmpty) return _vendors;
    return _vendors.where((vendor) =>
        vendor.toLowerCase().contains(_vendorController.text.toLowerCase())).toList();
  }

  List<String> _getFilteredTrucks() {
    if (_truckController.text.isEmpty) return _trucks;
    return _trucks.where((truck) =>
        truck.toLowerCase().contains(_truckController.text.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showVendorSuggestions = false;
            _showTruckSuggestions = false;
          });
        },
        child: Column(
          children: [
            _buildFilters(),
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
                ElevatedButton(
                  onPressed: _fetchTodayReports,
                  child: const Text('Today\'s List'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInput() {
    return Stack(
      children: [
        TextField(
          controller: _vendorController,
          decoration: const InputDecoration(
            labelText: 'Vendor',
            border: OutlineInputBorder(),
          ),
          onTap: () {
            setState(() {
              _showVendorSuggestions = true;
              _showTruckSuggestions = false;
            });
          },
          onChanged: (value) {
            setState(() {
              _showVendorSuggestions = true;
            });
          },
        ),
        if (_showVendorSuggestions)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Card(
              elevation: 4,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: _getFilteredVendors()
                      .map((vendor) => ListTile(
                    title: Text(vendor),
                    onTap: () {
                      setState(() {
                        _vendorController.text = vendor;
                        _showVendorSuggestions = false;
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTruckInput() {
    return Stack(
      children: [
        TextField(
          controller: _truckController,
          decoration: const InputDecoration(
            labelText: 'Truck Number',
            border: OutlineInputBorder(),
          ),
          onTap: () {
            setState(() {
              _showTruckSuggestions = true;
              _showVendorSuggestions = false;
            });
          },
          onChanged: (value) {
            setState(() {
              _showTruckSuggestions = true;
            });
          },
        ),
        if (_showTruckSuggestions)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Card(
              elevation: 4,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: _getFilteredTrucks()
                      .map((truck) => ListTile(
                    title: Text(truck),
                    onTap: () {
                      setState(() {
                        _truckController.text = truck;
                        _showTruckSuggestions = false;
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
      ],
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
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(TripDetails report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${report.truckNumber} - ${report.doNumber}'),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt!),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Driver', report.driverName),
                _buildInfoRow('Vendor', report.vendor),
                _buildInfoRow('From', report.destinationFrom),
                _buildInfoRow('To', report.destinationTo),
                _buildInfoRow('Status', report.transactionStatus),
                _buildInfoRow('Weight', '${report.weight} kg'),
                _buildInfoRow('Actual Weight', '${report.actualWeight} kg'),
                _buildInfoRow('Difference', '${report.differenceInWeight} kg'),
                _buildInfoRow('Freight', '₹${report.freight}'),
                _buildInfoRow('Diesel', '${report.diesel} L'),
                _buildInfoRow('Diesel Amount', '₹${report.dieselAmount}'),
                _buildInfoRow('TDS Rate', '${report.tdsRate}%'),
                _buildInfoRow('Advance', '₹${report.advance}'),
                if (report.dieselSlipImage?.isNotEmpty ?? false)
                  _buildDocumentRow('Diesel Slip', report.dieselSlipImage!),
                if (report.loadingAdvice?.isNotEmpty ?? false)
                  _buildDocumentRow('Loading Advice', report.loadingAdvice!),
                if (report.invoiceCompany?.isNotEmpty ?? false)
                  _buildDocumentRow('Invoice', report.invoiceCompany!),
                if (report.weightmentSlip?.isNotEmpty ?? false)
                  _buildDocumentRow('Weightment Slip', report.weightmentSlip!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, Map<String, String?> document) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // Implement document download/view logic here
            },
            icon: const Icon(Icons.file_download),
            label: Text(document['originalname'] ?? 'Download'),
          ),
        ],
      ),
    );
  }
}