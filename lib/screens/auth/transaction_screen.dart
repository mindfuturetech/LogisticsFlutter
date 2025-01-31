import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/transaction_service.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<TripDetails> tripDetails = [];
  Set<String> selectedTripIds = Set<String>();  // Properly initialized Set
  bool isLoading = false;
  String errorMessage = '';
  String noDataMessage = '';


  final String baseUrl = 'http://10.0.2.2:5000/logistics/list-all-transactions';
  final String updateUrl = 'http://10.0.2.2:5000/logistics/update-transactions';
  final String generatePDFTransactionUrl = "http://10.0.2.2:5000/logistics/generate-pdf-transaction";

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      noDataMessage = '';
      tripDetails = [];
      selectedTripIds.clear();  // Clear selections when fetching new data
    });

    try {
      final service = TripDetailsService();
      final formattedStartDate = startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate!)
          : null;
      final formattedEndDate = endDate != null
          ? DateFormat('yyyy-MM-dd').format(endDate!)
          : null;

      final results = await service.fetchTripDetails(
        startDate: formattedStartDate,
        endDate: formattedEndDate,
      );

      setState(() {
        if (results.isEmpty) {
          noDataMessage = 'No data found for this date range.';
        } else {
          tripDetails = results;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching transactions: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> updateTransaction(TripDetails trip) async {
    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          '_id': trip.id,
          'destination_to': trip.destinationTo,
          'weight': trip.weight,
          'actual_weight': trip.actualWeight,
          'freight': trip.freight,
          'diesel_amount': trip.dieselAmount,
          'advance': trip.advance,
          'toll': trip.toll,
          'tds_rate': trip.tdsRate,
          'amount': trip.amount,
          'transaction_status': trip.transactionStatus,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction updated successfully')),
        );
        fetchTransactions();
      } else {
        throw Exception('Failed to update transaction');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating transaction: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleGeneratePDF() async {
    if (selectedTripIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one transaction')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Format the payload as expected by your existing backend
      final payload = selectedTripIds.map((id) => {
        'id': id,
        'transaction_status': 'Billed'
      }).toList();

      print("Sending payload: $payload"); // Debug print

      final response = await http.post(
          Uri.parse(generatePDFTransactionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/pdf',
          },
          body: json.encode(payload)
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Get the temporary directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'GeneratedTransactionBill.pdf';
        final filePath = '${directory.path}/$fileName';

        // Write the PDF data to a file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Open the PDF file
        await OpenFile.open(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generated successfully')),
        );

        // Clear selections and refresh the list
        setState(() {
          selectedTripIds.clear();
        });
        fetchTransactions();
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating PDF: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _showEditDialog(TripDetails trip) async {
    final formKey = GlobalKey<FormState>();
    final editedTrip = TripDetails.fromJson(trip.toJson());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Transaction'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField(
                  label: 'Destination',
                  initialValue: editedTrip.destinationTo ?? '',
                  onSaved: (value) => editedTrip.destinationTo = value,
                ),
                _buildEditField(
                  label: 'Weight',
                  initialValue: editedTrip.weight?.toString() ?? '',
                  onSaved: (value) => editedTrip.weight = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Actual Weight',
                  initialValue: editedTrip.actualWeight?.toString() ?? '',
                  onSaved: (value) => editedTrip.actualWeight = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Freight',
                  initialValue: editedTrip.freight?.toString() ?? '',
                  onSaved: (value) => editedTrip.freight = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Rate',
                  initialValue: editedTrip.rate?.toString() ?? '',
                  onSaved: (value) => editedTrip.rate = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Diesel Amount',
                  initialValue: editedTrip.dieselAmount?.toString() ?? '',
                  onSaved: (value) => editedTrip.dieselAmount = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Advance',
                  initialValue: editedTrip.advance?.toString() ?? '',
                  onSaved: (value) => editedTrip.advance = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'Toll',
                  initialValue: editedTrip.toll?.toString() ?? '',
                  onSaved: (value) => editedTrip.toll = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                _buildEditField(
                  label: 'TDS Rate',
                  initialValue: editedTrip.tdsRate?.toString() ?? '',
                  onSaved: (value) => editedTrip.tdsRate = double.tryParse(value ?? ''),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Transaction Status',
                    border: OutlineInputBorder(),
                  ),
                  value: editedTrip.transactionStatus,
                  items: ['Acknowledged', 'Billed'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    editedTrip.transactionStatus = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                try {
                  final service = TripDetailsService();
                  await service.updateTransaction(editedTrip,trip.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Transaction updated successfully')),
                  );
                  Navigator.pop(context);
                  fetchTransactions(); // Refresh the list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating transaction: $e')),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required String initialValue,
    required Function(String?) onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        initialValue: initialValue,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          if (keyboardType == TextInputType.number) {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Map<String, List<TripDetails>> groupByDate() {
    final groups = <String, List<TripDetails>>{};
    for (var trip in tripDetails) {
      final date = DateFormat('yyyy-MM-dd').format(trip.createdAt ?? DateTime.now());
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(trip);
    }
    return Map.fromEntries(
      groups.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      controller: TextEditingController(
        text: value != null ? DateFormat('yyyy-MM-dd').format(value) : '',
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          if (selectedTripIds.isNotEmpty)
            isLoading
                ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _handleGeneratePDF,
              icon: Icon(Icons.picture_as_pdf),
              label: Text('Generate Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelectionSection(),
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionSection() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (startDate == null || endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select both start and end dates.')),
                );
                return;
              }

              if (startDate!.isAfter(endDate!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('End date should be greater than start date.')),
                );
                return;
              }

              fetchTransactions();
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }


  Widget _buildTransactionsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (noDataMessage.isNotEmpty) {
      return Center(child: Text(noDataMessage));
    }

    final groupedTransactions = groupByDate();

    return ListView.builder(
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final dayTrips = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                DateFormat('MMMM d, yyyy').format(dayTrips[0].createdAt ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dayTrips.length,
              itemBuilder: (context, tripIndex) {
                final trip = dayTrips[tripIndex];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Checkbox and Time
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: selectedTripIds.contains(trip.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true && trip.id != null) {
                                        print('Adding ID: ${trip.id}'); // Debug print
                                        selectedTripIds.add(trip.id!);
                                      } else if (trip.id != null) {
                                        selectedTripIds.remove(trip.id!);
                                      }
                                    });
                                  },
                                ),
                                // Time
                                Text(
                                  DateFormat('HH:mm').format(trip.createdAt ?? DateTime.now()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            // Right side: Edit icon and Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Edit icon
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _showEditDialog(trip),
                                ),
                                // Amount
                                Text(
                                  'Amount: ₹${trip.amount ?? '0.00'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(),
                        _buildInfoRow('Trip ID', trip.tripId ?? '-'),
                        _buildInfoRow('UserName', trip.username ?? '-'),
                        _buildInfoRow('Profile', trip.profile ?? '-'),
                        _buildInfoRow('Vendor', trip.vendor ?? '-'),
                        _buildInfoRow('Truck No.', trip.truckNumber ?? '-'),
                        _buildInfoRow('Destination', trip.destinationTo ?? '-'),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Weight', '${trip.weight ?? '-'}')),
                            Expanded(child: _buildInfoRow('Actual Wt.', '${trip.actualWeight ?? '-'}')),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Freight', '₹${trip.freight ?? '-'}')),
                            Expanded(child: _buildInfoRow('Rate', '₹${trip.rate ?? '-'}')),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Diesel', '₹${trip.dieselAmount ?? '-'}')),
                            Expanded(child: _buildInfoRow('Advance', '₹${trip.advance ?? '-'}')),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildInfoRow('Toll', '₹${trip.toll ?? '-'}')),
                            Expanded(child: _buildInfoRow('TDS', '${trip.tdsRate ?? '-'}%')),
                          ],
                        ),
                        _buildInfoRow('Bill ID', trip.billingId ?? '-'),
                        _buildInfoRow('Transaction Status', trip.transactionStatus ?? '-'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}