import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import '../../widget/custom_drawer.dart';


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

  @override
  void initState() {
    super.initState();
    _fetchTrucks();
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
        grandTotal = results.fold(0.0, (total, report) =>
        total + _calculateTotal(report));
      });
    } catch (e) {
      _showErrorDialog('Error fetching reports: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateTotal(TripDetails report) {
    return (report.freight ?? 0) -
        ((report.differenceInWeight ?? 0) * (report.tdsRate ?? 0)) -
        (report.dieselAmount ?? 0) -
        (report.advance ?? 0) -
        (report.toll ?? 0) -
        (report.adblue ?? 0) -
        (report.greasing ?? 0);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
      ),
      drawer: const CustomDrawer(), // Add drawer here
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
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(startDate!)
                                  : 'Select Start Date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(endDate!)
                                  : 'Select End Date',
                            ),
                          ),
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
                                  _buildInfoRow('Driver', report.driverName),
                                  _buildInfoRow('Vendor', report.vendor),
                                  _buildInfoRow('From', report.destinationFrom),
                                  _buildInfoRow('To', report.destinationTo),
                                  _buildInfoRow('Status', report.transactionStatus),
                                  _buildInfoRow('Weight', '${report.weight ?? 0}'),
                                  _buildInfoRow('Actual Weight', '${report.actualWeight ?? 0}'),
                                  _buildInfoRow('Difference', '${report.differenceInWeight ?? 0}'),
                                  _buildInfoRow('Freight', '₹${report.freight ?? 0}'),
                                  _buildInfoRow('Diesel Amount', '₹${report.dieselAmount ?? 0}'),
                                  _buildInfoRow('Advance', '₹${report.advance ?? 0}'),
                                  _buildInfoRow('Total', '₹${_calculateTotal(report)}'),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
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