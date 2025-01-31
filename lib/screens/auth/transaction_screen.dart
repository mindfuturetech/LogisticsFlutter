import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
  bool isLoading = false;
  String errorMessage = '';
  String noDataMessage = '';

  final String baseUrl = 'http://localhost:5000/logistics/list-all-transactions';

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
    });

    try {
      final service = TripDetailsService();

      // Format dates as YYYY-MM-DD for the API
      final formattedStartDate = startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate!)
          : null;
      final formattedEndDate = endDate != null
          ? DateFormat('yyyy-MM-dd').format(endDate!)
          : null;

      print('Fetching transactions with dates: $formattedStartDate to $formattedEndDate');

      // Pass the formatted dates to the service
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
      print('Error in fetchTransactions: $e');
      setState(() {
        errorMessage = 'Error fetching transactions: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime lastValidDate = DateTime(2025);

    final DateTime initialDate = now.isAfter(lastValidDate) ? lastValidDate : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: lastValidDate,
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


  double calculateAmount(TripDetails trip) {
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    double amount = 0;
    amount += _parseDouble(trip.freight);
    amount -= _parseDouble(trip.advance);
    amount -= _parseDouble(trip.diesel);
    amount -= _parseDouble(trip.toll);
    return amount;
  }
  void handleSearch() {
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
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
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
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _selectDate(context, true),
              icon: Icon(Icons.calendar_today),
              label: Text(
                startDate == null
                    ? 'Start Date'
                    : DateFormat('yyyy-MM-dd').format(startDate!),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextButton.icon(
              onPressed: () => _selectDate(context, false),
              icon: Icon(Icons.calendar_today),
              label: Text(
                endDate == null
                    ? 'End Date'
                    : DateFormat('yyyy-MM-dd').format(endDate!),
              ),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: handleSearch,
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
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(trip.createdAt ?? DateTime.now()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Amount: ₹${calculateAmount(trip).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
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
                            Expanded(
                              child: _buildInfoRow(
                                'Rate',
                                trip.freight != null && trip.weight != null
                                    ? '₹${(trip.freight! / trip.weight!).toStringAsFixed(2)}'
                                    : '-',
                              ),
                            ),
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
                        _buildInfoRow('Trip ID', '${trip.tripId ?? '-'}'),
                        _buildInfoRow('Username', trip.username ?? '-'),
                        _buildInfoRow('Profile', trip.profile ?? '-'),
                        _buildInfoRow('Short Weight', '${trip.differenceInWeight ?? '-'}'),
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