import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/search_service.dart';
import '../../config/services/transaction_service.dart';
import 'home_screen.dart';

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


  final String baseUrl = 'https://shreelalchand.com/logistics/list-all-transactions';
  final String updateUrl = 'https://shreelalchand.com/logistics/update-transactions';
  final String generatePDFTransactionUrl = "https://shreelalchand.com/logistics/generate-pdf-transaction";

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
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Truck Number: ${trip.truckNumber ?? "N/A"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      DateFormat('HH:mm').format(trip.createdAt ?? DateTime.now()),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Amount: ₹${trip.amount ?? "0.00"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showEditDialog(trip),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSection(
                                'Trip Information',
                                [
                                  _buildInfoRow('Trip ID', trip.tripId ?? '-', isTripId: true),
                                  _buildInfoRow('UserName', trip.username ?? '-'),
                                  _buildInfoRow('Profile', trip.profile ?? '-'),
                                  _buildInfoRow('Vendor', trip.vendor ?? '-'),
                                  _buildInfoRow('Destination', trip.destinationTo ?? '-'),
                                ],
                              ),
                              Divider(height: 32),
                              _buildSection(
                                'Financial Details',
                                [
                                  _buildFinancialRow('Weight', '${trip.weight ?? "-"}', 'Actual Wt.', '${trip.actualWeight ?? "-"}'),
                                  _buildFinancialRow('Freight', '₹${trip.freight ?? "-"}', 'Rate', '₹${trip.rate ?? "-"}'),
                                  _buildFinancialRow('Diesel', '₹${trip.dieselAmount ?? "-"}', 'Advance', '₹${trip.advance ?? "-"}'),
                                  _buildFinancialRow('Toll', '₹${trip.toll ?? "-"}', 'TDS', '${trip.tdsRate ?? "-"}%'),
                                ],
                              ),
                              Divider(height: 32),
                              _buildSection(
                                'Additional Information',
                                [
                                  _buildInfoRow('Bill ID', trip.billingId ?? '-'),
                                  _buildInfoRow('Transaction Status', trip.transactionStatus ?? '-'),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFinancialRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(child: _buildInfoRow(label1, value1)),
        Expanded(child: _buildInfoRow(label2, value2)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTripId = false}) {
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
            child: isTripId
                ? InkWell(
              onTap: () async {
                try {
                  final searchService = ApiSearchService();
                  final tripDetails = await searchService.searchUserById(value);

                  if (tripDetails != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TruckDetailsScreen(
                          username: tripDetails.username,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error fetching trip details: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            )
                : Text(
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