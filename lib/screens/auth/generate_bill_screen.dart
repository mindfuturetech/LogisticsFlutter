import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/model/truck_details_model.dart';
import '../../config/services/search_service.dart';
import 'home_screen.dart';


class GenerateBillScreen extends StatefulWidget {
  @override
  _GenerateBillScreenState createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends State<GenerateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  String? selectedVendor;
  String? selectedTruck;
  List<TripDetails> bills = [];
  bool isLoading = false;
  Set<String> selectedBills = {};
  List<String> vendors = [];
  List<String> trucks = [];
  int? currentBillId;

  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _truckController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _loadTrucks();
    _fetchCurrentBillId();
  }

  Future<void> _fetchCurrentBillId() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/logistics/current-bill-id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentBillId = (data['currentBillId'] as int?) ?? 1;
        });
      }
    } catch (e) {
      print('Error fetching current bill ID: $e');
    }
  }
  Future<void> _loadVendors() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/logistics/list-vendor'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vendors = List<String>.from(
            data['resultData'].map((vendor) => vendor['companyName']),
          );
        });
      }
    } catch (e) {
      print('Error loading vendors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vendors')),
      );
    }
  }

  Future<void> _loadTrucks() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/logistics/list-vehicle'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trucks = List<String>.from(
            data['resultData'].map((truck) => truck['truck_no']),
          );
        });
      }
    } catch (e) {
      print('Error loading trucks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trucks')),
      );
    }
  }

  Future<void> _searchBills() async {
    if ((startDate == null || endDate == null) &&
        selectedVendor == null &&
        selectedTruck == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide search criteria')),
        );
      }
      return;
    }

    if (startDate != null && endDate != null) {
      if (startDate!.isAfter(endDate!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End date should be greater than or equal to Start Date')),
          );
        }
        return;
      }
    }

    setState(() {
      isLoading = true;
      bills.clear();
      selectedBills.clear();
    });

    try {
      print("Sending startDate: ${startDate?.toIso8601String()}");
      print("Sending endDate: ${endDate?.toIso8601String()}");

      // Print request details for debugging
      final requestBody = {
        'startDate': startDate != null ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(startDate!) : null,
        'endDate': endDate != null ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(endDate!) : null,
        'vendor': selectedVendor,
        'truckNumber': selectedTruck,
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/logistics/list-billing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Print response details for debugging
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if response has the expected structure
        if (!data.containsKey('resultData')) {
          throw Exception('Response missing resultData field');
        }

        if (data['resultData'] == null) {
          setState(() {
            bills = [];
          });
          return;
        }

        if (data['resultData'] is! List) {
          throw Exception('resultData is not a list');
        }

        setState(() {
          bills = List<TripDetails>.from(
            data['resultData'].map((x) {
              // Print individual record for debugging
              print('Processing record: $x');

              return TripDetails(
                tripId: x['trip_id']?.toString() ?? '',
                id: x['_id']?.toString() ?? '',
                truckNumber: x['truck_no']?.toString() ?? '',
                weight: _parseDouble(x['weight']),
                actualWeight: _parseDouble(x['actual_weight']),
                differenceInWeight: _parseDouble(x['difference_weight']),
                freight: _parseDouble(x['freight']),
                dieselAmount: _parseDouble(x['diesel_amount']),
                advance: _parseDouble(x['advance']),
                driverName: x['driver_name']?.toString() ?? '',
                destinationFrom: x['destination_from']?.toString() ?? '',
                destinationTo: x['destination_to']?.toString() ?? '',
                doNumber: x['do_number']?.toString() ?? '',
                vendor: x['vendor']?.toString() ?? '',
                truckType: x['truck_type']?.toString() ?? '',
                transactionStatus: x['transaction_status']?.toString() ?? '',
                dieselSlipNumber: x['diesel_slip_number']?.toString() ?? '',
              );
            }).toList(),
          );
        });
      } else {
        // Print error response details
        print('Error response: ${response.body}');
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      // Print detailed error information
      print('Error in _searchBills: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bills: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Update the _parseDouble helper method to be more robust
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }
  Future<void> _generateBill() async {
    if (selectedBills.isEmpty) {
      if (mounted) {  // Add mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one bill')),
        );
      }
      return;
    }


    try {
      final selectedBillsData = bills
          .where((bill) => selectedBills.contains(bill.truckNumber))
          .map((bill) => {
        'id': bill.id ?? '',
        'transaction_status': bill.transactionStatus ?? 'Open',
        'bill_id': currentBillId, // Include the current bill ID
      })
          .toList();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/logistics/generate-pdf-bill'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(selectedBillsData),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Increment the bill ID after successful generation
        setState(() {
          currentBillId = (currentBillId ?? 0) + 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully')),
        );
        await _searchBills(); // Refresh the list
      } else {
        throw Exception('Failed to generate bill');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bill: ${e.toString()}')),
        );
      }
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

  Widget _buildVendorAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return vendors;
        }
        return vendors.where((vendor) =>
            vendor.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String value) {
        setState(() {
          selectedVendor = value;
          _vendorController.text = value;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Vendor',
            border: OutlineInputBorder(),
            hintText: 'Select vendor',
          ),
          onChanged: (value) {
            setState(() {
              selectedVendor = value;
            });
          },
        );
      },
    );
  }

  Widget _buildTruckAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return trucks;
        }
        return trucks.where((truck) =>
            truck.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String value) {
        setState(() {
          selectedTruck = value;
          _truckController.text = value;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Truck Number',
            border: OutlineInputBorder(),
            hintText: 'Select or type truck number',
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && !trucks.contains(value)) {
              return 'Please select a valid truck number';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildResultsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (bills.isEmpty) {
      return Center(child: Text('No bills found'));
    }

    return Column(
      children: [
        // Display current bill ID
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Bill ID:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '#${DateTime.now().year}-${(bills.length + 1).toString().padLeft(4, '0')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: CheckboxListTile(
                value: selectedBills.contains(bill.truckNumber),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedBills.add(bill.truckNumber ?? '');
                    } else {
                      selectedBills.remove(bill.truckNumber ?? '');
                    }
                  });
                },
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('DO Number: ${bill.doNumber ?? 'N/A'}'),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${bill.transactionStatus ?? 'N/A'}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('TripId: ', style: TextStyle(color: Colors.black)),
                        InkWell(
                          onTap: () async {
                            try {
                              final searchService = ApiSearchService();
                              final tripDetails = await searchService.searchUserById(bill.tripId ?? '');

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
                                    content: Text('No trip details found for ID: ${bill.tripId}'),
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
                            '${bill.tripId ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.blue,
                              // decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ), // Regular text

                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Truck: ${bill.truckNumber ?? 'N/A'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          'Driver: ${bill.driverName ?? 'N/A'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'From: ${bill.destinationFrom ?? 'N/A'} → To: ${bill.destinationTo ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[100],
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Weight Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Weight: ${(bill.weight ?? 0.0).toStringAsFixed(2)} tons',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  if ((bill.actualWeight ?? 0.0) > 0)
                                    Text(
                                      'Actual: ${(bill.actualWeight ?? 0.0).toStringAsFixed(2)} tons',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  if ((bill.differenceInWeight ?? 0.0) != 0)
                                    Text(
                                      'Diff: ${(bill.differenceInWeight ?? 0.0).toStringAsFixed(2)} tons',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: Colors.grey[100],
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Freight: ₹${(bill.freight ?? 0.0).toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Diesel: ${(bill.diesel ?? 0.0).toStringAsFixed(2)}L (₹${(bill.dieselAmount ?? 0.0).toStringAsFixed(2)})',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  if ((bill.advance ?? 0.0) > 0)
                                    Text(
                                      'Advance: ₹${(bill.advance ?? 0.0).toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
        if (bills.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected: ${selectedBills.length}/${bills.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (selectedBills.length == bills.length) {
                            selectedBills.clear();
                          } else {
                            selectedBills = bills
                                .map((bill) => bill.truckNumber ?? '')
                                .toSet();
                          }
                        });
                      },
                      child: Text(
                        selectedBills.length == bills.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: selectedBills.isNotEmpty ? _generateBill : null,
                  child: Text('Generate Bill'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Bill'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchForm(),
            SizedBox(height: 24),
            _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
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
          _buildVendorAutocomplete(),
          SizedBox(height: 16),
          _buildTruckAutocomplete(),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchBills,
            child: Text('Search'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _truckController.dispose();
    super.dispose();
  }
}