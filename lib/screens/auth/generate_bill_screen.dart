import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/model/truck_details_model.dart';
import '../../config/services/generate_bill_service.dart';
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
  Set<String> selectedTripIds = Set<String>();
  bool hasSelectedItems = false;

  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _truckController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _loadTrucks();
    _fetchCurrentBillId();
  }
  final String generatePDFTransactionUrl ="https://shreelalchand.com/logistics/generate-pdf-bill";
  Future<void> _fetchCurrentBillId() async {
    try {
      final response = await http.get(
        Uri.parse('https://shreelalchand.com/logistics/current-bill-id'),
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
        Uri.parse('https://shreelalchand.com/logistics/list-vendor'),
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
        Uri.parse('https://shreelalchand.com/logistics/list-vehicle'),
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
  Future<void> handleGeneratePDF() async {
    if (selectedTripIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one transaction')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final billService = BillService();

      // Format selected trips for the API
      final selectedTrips = bills
          .where((bill) => selectedTripIds.contains(bill.tripId))
          .map((bill) => {
        'id': bill.id,
        'transaction_status': 'Billed',
      })
          .toList();

      await billService.generatePDF(selectedTrips);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully')),
        );
      }

      // Clear selections and refresh
      setState(() {
        selectedTripIds.clear();
        selectedBills.clear();
        hasSelectedItems = false;
      });

      // Refresh the bills list
      await _searchBills();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bill: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }




  Future<void> _searchBills() async {
    // Input validation
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

    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date should be greater than or equal to Start Date')),
        );
      }
      return;
    }

    setState(() {
      isLoading = true;
      bills.clear();
      selectedBills.clear();
    });

    try {
      final requestBody = {
        'startDate': startDate != null ? DateFormat("yyyy-MM-dd").format(startDate!) : null,
        'endDate': endDate != null ? DateFormat("yyyy-MM-dd").format(endDate!) : null,
        'vendor': selectedVendor,
        'truckNumber': selectedTruck,
      };

      final response = await http.post(
        Uri.parse('https://shreelalchand.com/logistics/list-billing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Check if there's an error message from backend
        if (data.containsKey('error')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['error'])),
            );
          }
          setState(() {
            bills = [];
          });
          return;
        }

        // Check for resultData
        if (!data.containsKey('resultData') || data['resultData'] == null) {
          setState(() {
            bills = [];
          });
          return;
        }

        setState(() {
          bills = List<TripDetails>.from(
            data['resultData'].map((x) => TripDetails(
              tripId: x['trip_id']?.toString() ?? '',
              id: x['_id']?.toString() ?? '',
              username: x['username']?.toString() ?? '',
              profile: x['profile']?.toString() ?? '',
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
              createdAt: x['date'] != null ? DateTime.parse(x['date']) : null,
            )),
          );
        });
      } else {
        // Show backend error message if available, otherwise show generic message
        final errorMessage = data['error'] ?? 'No records found';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
        setState(() {
          bills = [];
        });
      }
    } catch (e) {
      // Only show generic error for network/parsing issues
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No records found')),
        );
      }
      setState(() {
        bills = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Helper function to safely parse doubles
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
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
  Widget _buildLoadingOverlay({required Widget child}) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildBillCard(TripDetails bill) {
    final isSelected = selectedTripIds.contains(bill.tripId);

    // If createdAt is null, use a default date (or handle as needed)
    DateTime localDateTime;
    if (bill.createdAt != null) {
      // Convert to IST (UTC+5:30)
      localDateTime = bill.createdAt!.toUtc().add(const Duration(hours: 5, minutes: 30));
    } else {
      localDateTime = DateTime.now();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedTripIds.add(bill.tripId ?? '');
                      selectedBills.add(bill.truckNumber ?? '');
                    } else {
                      selectedTripIds.remove(bill.tripId ?? '');
                      selectedBills.remove(bill.truckNumber ?? '');
                    }
                    hasSelectedItems = selectedBills.isNotEmpty;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truck Number: ${bill.truckNumber ?? 'N/A'}',
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
                          DateFormat('h:mm a').format(localDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  _buildTripInformation(bill),
                  const Divider(height: 32),
                  _buildFinancialInformation(bill),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInformation(TripDetails bill) {
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
            _buildInfoRow('Trip ID', bill.tripId, isTripId: true),
            _buildInfoRow('Username', bill.username),
            _buildInfoRow('Profile', bill.profile),
            _buildInfoRow('Driver', bill.driverName),
            _buildInfoRow('Vendor', bill.vendor),
            _buildInfoRow('From', bill.destinationFrom),
            _buildInfoRow('To', bill.destinationTo),
            _buildInfoRow('Status', bill.transactionStatus),
            _buildInfoRow('DO Number', bill.doNumber),
            _buildInfoRow('Truck Type', bill.truckType),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialInformation(TripDetails bill) {
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
            _buildInfoRow('Weight', '${(bill.weight ?? 0.0).toStringAsFixed(2)} tons'),
            _buildInfoRow('Actual Weight', '${(bill.actualWeight ?? 0.0).toStringAsFixed(2)} tons'),
            _buildInfoRow('Weight Difference', '${(bill.differenceInWeight ?? 0.0).toStringAsFixed(2)} tons'),
            _buildInfoRow('Freight', '₹${(bill.freight ?? 0.0).toStringAsFixed(2)}'),
            _buildInfoRow('Diesel Amount', '₹${(bill.dieselAmount ?? 0.0).toStringAsFixed(2)}'),
            _buildInfoRow('Advance', '₹${(bill.advance ?? 0.0).toStringAsFixed(2)}'),
            _buildInfoRow('Diesel Slip Number', bill.dieselSlipNumber)
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill'),
        actions: [
          if (selectedTripIds.isNotEmpty)
            isLoading
                ? const Padding(
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
              onPressed: handleGeneratePDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
        ],
      ),
      body: _buildLoadingOverlay(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchForm(),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length,
                itemBuilder: (context, index) => _buildBillCard(bills[index]),
              ),
              if (bills.isNotEmpty) _buildFooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${selectedBills.length}/${bills.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (selectedBills.length == bills.length) {
                      selectedBills.clear();
                      selectedTripIds.clear();
                    } else {
                      selectedBills = bills
                          .where((bill) => bill.truckNumber != null)
                          .map((bill) => bill.truckNumber!)
                          .toSet();
                      selectedTripIds = bills
                          .where((bill) => bill.tripId != null)
                          .map((bill) => bill.tripId!)
                          .toSet();
                    }
                    hasSelectedItems = selectedBills.isNotEmpty;
                  });
                },
                child: Text(
                  selectedBills.length == bills.length ? 'Deselect All' : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: hasSelectedItems ? handleGeneratePDF : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: hasSelectedItems ? Theme.of(context).primaryColor : Colors.grey,
            ),
            child: Text(
              'Generate PDF',
              style: TextStyle(
                color: hasSelectedItems ? Colors.white : Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Widget _buildResultsList() {
  //   if (isLoading) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //
  //   return Column(
  //     children: [
  //       ListView.builder(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: bills.length,
  //         itemBuilder: (context, index) {
  //           final bill = bills[index];
  //           final isSelected = selectedTripIds.contains(bill.tripId);
  //
  //           final localDateTime = DateTime.now().toLocal();
  //
  //           return Card(
  //             margin: const EdgeInsets.symmetric(vertical: 8),
  //             child: ExpansionTile(
  //               title: Row(
  //                 children: [
  //                   Checkbox(
  //                     value: isSelected,
  //                     onChanged: (bool? value) {
  //                       setState(() {
  //                         if (value == true) {
  //                           selectedTripIds.add(bill.tripId ?? '');
  //                           selectedBills.add(bill.truckNumber ?? '');
  //                         } else {
  //                           selectedTripIds.remove(bill.tripId ?? '');
  //                           selectedBills.remove(bill.truckNumber ?? '');
  //                         }
  //                         hasSelectedItems = selectedBills.isNotEmpty;
  //                       });
  //                     },
  //                   ),
  //                   const Text(
  //                     'Truck Number: ',
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                   Text(
  //                     bill.truckNumber ?? 'N/A',
  //                     style: const TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               subtitle: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       const Text(
  //                         'Date: ',
  //                         style: TextStyle(fontSize: 14),
  //                       ),
  //                       Text(
  //                         DateFormat('dd MMM yyyy').format(localDateTime),
  //                         style: const TextStyle(fontSize: 14),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Row(
  //                     children: [
  //                       const Text(
  //                         'Time: ',
  //                         style: TextStyle(fontSize: 14),
  //                       ),
  //                       Text(
  //                         DateFormat('hh:mm a').format(localDateTime),
  //                         style: const TextStyle(fontSize: 14),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           // Left Column
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 _buildInfoRow('Trip ID', bill.tripId, isTripId: true),
  //                                 _buildInfoRow('DO Number', bill.doNumber?.toString()),
  //                                 _buildInfoRow('Profile', bill.profile),
  //                                 _buildInfoRow('Username', bill.username),
  //                                 _buildInfoRow('From', bill.destinationFrom),
  //                                 _buildInfoRow('Vendor', bill.vendor),
  //                                 _buildInfoRow('To', bill.destinationTo),
  //                                 _buildInfoRow('Driver', bill.driverName),
  //                                 _buildInfoRow('Status', bill.transactionStatus),
  //                                 _buildInfoRow('From', bill.destinationFrom),
  //                                 _buildInfoRow('To', bill.destinationTo),
  //                                 _buildInfoRow('Status', bill.transactionStatus),
  //                                 _buildInfoRow('Truck Type', bill.truckType),
  //                                 _buildInfoRow('Diesel Slip Number', bill.dieselSlipNumber),
  //                               ],
  //                             ),
  //                           ),
  //                           const SizedBox(width: 16),
  //                           // Right Column
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 _buildInfoRow('Weight', bill.weight?.toString()),
  //                                 _buildInfoRow('Advance', bill.advance?.toString()),
  //                                 _buildInfoRow('Weight', '${(bill.weight ?? 0.0).toStringAsFixed(2)} tons'),
  //                                 if ((bill.actualWeight ?? 0.0) > 0)
  //                                   _buildInfoRow('Actual Weight', '${(bill.actualWeight ?? 0.0).toStringAsFixed(2)} tons'),
  //                                 if ((bill.differenceInWeight ?? 0.0) != 0)
  //                                   _buildInfoRow('Weight Difference', '${(bill.differenceInWeight ?? 0.0).toStringAsFixed(2)} tons'),
  //                                 _buildInfoRow('Freight', '₹${(bill.freight ?? 0.0).toStringAsFixed(2)}'),
  //                                 _buildInfoRow('Diesel Amount', bill.dieselAmount?.toString()),
  //                                 _buildInfoRow('Diesel Slip Number', bill.dieselSlipNumber?.toString()),
  //                                 if ((bill.advance ?? 0.0) > 0)
  //                                   _buildInfoRow('Advance', '₹${(bill.advance ?? 0.0).toStringAsFixed(2)}'),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 16),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       ),
  //       // Footer Section
  //       if (bills.isNotEmpty)
  //         Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //           child: Column(
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'Selected: ${selectedBills.length}/${bills.length}',
  //                     style: const TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                   TextButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         if (selectedBills.length == bills.length) {
  //                           // Deselect all
  //                           selectedBills.clear();
  //                           selectedTripIds.clear();
  //                         } else {
  //                           // Select all
  //                           selectedBills = bills
  //                               .where((bill) => bill.truckNumber != null)
  //                               .map((bill) => bill.truckNumber!)
  //                               .toSet();
  //                           selectedTripIds = bills
  //                               .where((bill) => bill.tripId != null)
  //                               .map((bill) => bill.tripId!)
  //                               .toSet();
  //                         }
  //                         hasSelectedItems = selectedBills.isNotEmpty;
  //                       });
  //                     },
  //                     child: Text(
  //                       selectedBills.length == bills.length
  //                           ? 'Deselect All'
  //                           : 'Select All',
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 onPressed: hasSelectedItems ? handleGeneratePDF : null,
  //                 style: ElevatedButton.styleFrom(
  //                   minimumSize: const Size(double.infinity, 50),
  //                   backgroundColor: hasSelectedItems
  //                       ? Theme.of(context).primaryColor
  //                       : Colors.grey,
  //                 ),
  //                 child: Text(
  //                   'Generate PDF',
  //                   style: TextStyle(
  //                     color: hasSelectedItems ? Colors.white : Colors.grey[300],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _buildInfoRow(String label, String? value, {bool isTripId = false}) {
    if (isTripId) {
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
          InkWell(
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
          ),
        ],
      );
    }

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
        Text(
          value ?? 'N/A',
          style: const TextStyle(
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildInfoRow(String label, String? value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 4),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           '$label: ',
  //           style: const TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value ?? 'N/A',
  //             style: const TextStyle(fontSize: 14),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Generate Bill'),
  //       actions: [
  //         if (selectedTripIds.isNotEmpty)
  //           isLoading
  //               ? Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 16.0),
  //             child: Center(
  //               child: SizedBox(
  //                 width: 20,
  //                 height: 20,
  //                 child: CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   color: Colors.white,
  //                 ),
  //               ),
  //             ),
  //           )
  //               : ElevatedButton.icon(
  //             onPressed: handleGeneratePDF,
  //             icon: Icon(Icons.picture_as_pdf),
  //             label: Text('Generate Bill'),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.transparent,
  //               elevation: 0,
  //             ),
  //           ),
  //       ], // <-- Closing bracket for actions
  //     ),
  //     body: SingleChildScrollView(
  //       padding: EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           _buildSearchForm(),
  //           SizedBox(height: 24),
  //           _buildResultsList(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //

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

  @override
  void dispose() {
    _vendorController.dispose();
    _truckController.dispose();
    super.dispose();
  }
}