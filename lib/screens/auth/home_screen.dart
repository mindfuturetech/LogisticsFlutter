
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:logistics/widget/custom_appbar.dart';

import '../../config/model/truck_details_model.dart';
import '../../config/services/truck_details_service.dart';
import '../../widget/custom_drawer.dart';

class TruckDetailsScreen extends StatefulWidget {
  const TruckDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TruckDetailsScreen> createState() => _TruckDetailsScreenState();
}

class _TruckDetailsScreenState extends State<TruckDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final _logisticsService = LogisticsService();
  // final _truckDetails = TripDetails();
  TripDetails? _truckData;



  String baseUrl = 'http://10.0.2.2:5000/logistics';
  List<Map<String, dynamic>> destinationList = [];
  List<Map<String, dynamic>> vendorsList = [];
  List<Map<String, dynamic>> truckNumbersList = [];

  // Initialize all controllers

  final userNameController = TextEditingController();
  TextEditingController truckNumberController = TextEditingController();
  final _doNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _driverNameController = TextEditingController();
  TextEditingController vendorController = TextEditingController();
  TextEditingController destinationFromController = TextEditingController();
  TextEditingController destinationToController = TextEditingController();
  final _freightController = TextEditingController();
  final _dieselController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  final _dieselAmountController = TextEditingController();
  final _dieselSlipNumberController = TextEditingController();
  final _tdsRateController = TextEditingController();
  final _advanceController = TextEditingController();
  final _tollController = TextEditingController();
  final _adblueController = TextEditingController();
  final _greasingController = TextEditingController();

  double freight = 0;
  double tdsRate = 0;
  List<Map<String, dynamic>> filteredDestinationFrom = [];
  List<Map<String, dynamic>> filteredDestinationTo = [];

  String selectedTruckType = '';
  String selectedTransactionStatus = '';
  String userName = 'admin';

  //
  // get truckDetails => null;

  @override
  void initState() {
    super.initState();
    fetchDestinationData();
    weightController.addListener(_onWeightChanged);
    _freightController.text = '0.00';
  }

  Future<void> fetchDestinationData() async {
    try {
      final response = await dio.get('$baseUrl/api/destination');
      setState(() {
        destinationList = List<Map<String, dynamic>>.from(response.data['destinationData']);
      });
    } catch (error) {
      print('Error fetching destination data: $error');
    }
  }


  @override
  void dispose() {
    // Dispose all controllers
    truckNumberController.dispose();
    _doNumberController.dispose();
    _dateController.dispose();
    _driverNameController.dispose();
    vendorController.dispose();
    destinationFromController.dispose();
    destinationToController.dispose();
    _freightController.dispose();
    _dieselController.dispose();
    weightController.dispose();
    _dieselAmountController.dispose();
    _dieselSlipNumberController.dispose();
    _tdsRateController.dispose();
    _advanceController.dispose();
    _tollController.dispose();
    _adblueController.dispose();
    _greasingController.dispose();
    super.dispose();
    weightController.removeListener(_onWeightChanged);
  }
  void _onWeightChanged() {
    if (weightController.text.isNotEmpty) {
      calculateRate();
    } else {
      setState(() {
        freight = 0.0;
      });
    }
  }
  void calculateRate() {
    final validFrom = destinationList.any((dest) =>
    dest['from'].toLowerCase() == destinationFromController.text.toLowerCase());
    final validTo = destinationList.any((dest) =>
    dest['to'].toLowerCase() == destinationToController.text.toLowerCase());

    if (validFrom && validTo) {
      final matchingRoutes = destinationList.where((dest) =>
      dest['from'].toLowerCase() == destinationFromController.text.toLowerCase() &&
          dest['to'].toLowerCase() == destinationToController.text.toLowerCase()
      ).toList();

      if (matchingRoutes.isNotEmpty && weightController.text.isNotEmpty) {
        setState(() {
          try {
            freight = matchingRoutes[0]['rate'] * double.parse(weightController.text);
            // Update both the freight variable and the controller text
            _freightController.text = freight.toStringAsFixed(2);
          } catch (e) {
            freight = 0.0;
            _freightController.text = '0.00';
          }
        });
      } else {
        setState(() {
          freight = 0.0;
          _freightController.text = '0.00';
        });
      }
    }
  }
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void handleDestinationFrom(String value) {
    List<Map<String, dynamic>> filtered = [];

    if (destinationToController.text.isNotEmpty) {
      filtered = destinationList.where((dest) =>
      dest['from'].toLowerCase().startsWith(value.toLowerCase()) &&
          dest['to'].toLowerCase() == destinationToController.text.toLowerCase()
      ).toList();
    } else {
      filtered = destinationList.where((dest) =>
          dest['from'].toLowerCase().startsWith(value.toLowerCase())
      ).toList();
    }

    final uniqueFromLocations = filtered
        .map((dest) => dest['from'].toLowerCase())
        .toSet()
        .map((from) => {
      '_id': from,
      'from': capitalizeFirstLetter(from),
    })
        .toList();

    setState(() {
      filteredDestinationFrom = uniqueFromLocations;
    });
  }

  void handleDestinationTo(String value) {
    List<Map<String, dynamic>> filtered = [];

    if (destinationFromController.text.isNotEmpty) {
      filtered = destinationList.where((dest) =>
      dest['to'].toLowerCase().startsWith(value.toLowerCase()) &&
          dest['from'].toLowerCase() == destinationFromController.text.toLowerCase()
      ).toList();
    } else {
      filtered = destinationList.where((dest) =>
          dest['to'].toLowerCase().startsWith(value.toLowerCase())
      ).toList();
    }

    final uniqueToLocations = filtered
        .map((dest) => dest['to'].toLowerCase())
        .toSet()
        .map((to) => {
      '_id': to,
      'to': capitalizeFirstLetter(to),
    })
        .toList();

    setState(() {
      filteredDestinationTo = uniqueToLocations;
    });
  }
  // Add other controllers as needed

  //Added Search Functionality
  void _updateFormWithTruck(TripDetails? truck) {
    setState(() {
      _truckData = truck;
      print("Response body");
      if (truck != null) {
        truckNumberController.text = truck.truckNumber ?? '';
        _doNumberController.text = truck.doNumber ?? '';
        _driverNameController.text = truck.driverName ?? '';
        vendorController.text = truck.vendor ?? '';
        destinationFromController.text = truck.destinationFrom ?? '';
        destinationToController.text = truck.destinationTo ?? '';
        weightController.text = truck.weight?.toString() ?? '';
        _freightController.text = truck.freight?.toString() ?? '';
        _dieselController.text = truck.diesel?.toString() ?? '';
        _dieselAmountController.text = truck.dieselAmount?.toString() ?? '';
        _dieselSlipNumberController.text = truck.dieselSlipNumber ?? '';
        _tdsRateController.text = truck.tdsRate?.toString() ?? '';
        _advanceController.text = truck.advance?.toString() ?? '';
        _tollController.text = truck.toll?.toString() ?? '';
        _adblueController.text = truck.adblue?.toString() ?? '';
        _greasingController.text = truck.greasing?.toString() ?? '';
      } else {
        _clearForm();
      }
    });
  }

  void _clearForm() {
    truckNumberController.clear();
    _doNumberController.clear();
    _driverNameController.clear();
    vendorController.clear();
    destinationFromController.clear();
    destinationToController.clear();
    weightController.clear();    //**
    _freightController.clear();    //**
    _dieselController.clear();
    _dieselAmountController.clear();
    _dieselSlipNumberController.clear();
    _tdsRateController.clear();
    _advanceController.clear();
    _tollController.clear();
    _adblueController.clear();
    _greasingController.clear();
    _truckData = null;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      // Custom AppBar with black strip
      // appBar: PreferredSize(
      //   preferredSize: const Size.fromHeight(100),
      //   child: Container(
      //     color: Colors.black,
      //     child: SafeArea(
      //       child: Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 16),
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             // // Logo
      //             // Padding(
      //             //   padding: const EdgeInsets.only(right: 16),
      //             //   child: Image.asset(
      //             //     'assets/logo.png', // Make sure to add your logo in assets
      //             //     height: 40,
      //             //   ),
      //             // ),
      //
      //             // Toggle Button
      //             IconButton(
      //               icon: const Icon(Icons.menu, color: Colors.white,size: 30,),
      //               onPressed: () {
      //                 _scaffoldKey.currentState?.openDrawer();
      //               },
      //             ),
      //
      //             // search bar
      //             Expanded(
      //               child: Container(
      //                 height: 40,
      //                 width: 50,
      //                 decoration: BoxDecoration(
      //                   color: Colors.grey[100],
      //                   borderRadius: BorderRadius.circular(10),
      //                 ),
      //                 child: TextField(
      //                   // controller: searchController,
      //                   decoration: InputDecoration(
      //                     hintText: 'Truck Id',
      //                     hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      //                     border: InputBorder.none,
      //                     contentPadding: const EdgeInsets.symmetric(
      //                       horizontal: 16,
      //                       vertical: 8,
      //                     ),
      //                     isDense: true,
      //                     prefixIcon: Icon(
      //                       Icons.search,
      //                       color: Colors.grey[600],
      //                       size: 30,
      //                     )
      //                   ),
      //                   // onSubmitted: onSearch,
      //                 ),
      //               ),
      //             ),
      //
      //             //Notification Button
      //             IconButton(
      //                 onPressed: (){
      //                    Navigator.push(
      //                      context,
      //                      MaterialPageRoute(
      //                        builder: (context) => const NotificationPage(),
      //                      ),
      //                    );
      //                 },
      //                 icon: Icon(
      //                   Icons.notifications_active,
      //                   size: 30,
      //                   color: Colors.yellow,
      //                 )
      //             ),
      //
      //             IconButton(
      //                 onPressed: (){},
      //                 icon: Icon(
      //                   Icons.logout,
      //                   size: 30,
      //                   color: Colors.red,
      //                 )
      //             )
      //           ],
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      // Navigation Drawer


      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       Container(
      //         height: 150,  // Set the height to a smaller value, e.g., 100
      //         child: const DrawerHeader(
      //           decoration: BoxDecoration(color: Colors.black),
      //           child: Text(
      //             'Menu',
      //             style: TextStyle(color: Colors.white, fontSize: 24),
      //           ),
      //         ),
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.home),
      //         title: const Text('Upload Truck Details'),
      //         onTap: () {
      //           Navigator.pop(context);
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.local_shipping),
      //         title: const Text('Freight Master'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/freight'); // Navigates to the '/freight' route
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.directions_car),
      //         title: const Text('Vehicle Master'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/vehicle');
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.man),
      //         title: const Text('Vendor Master'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/vendor');
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.book),
      //         title: const Text('Reports'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/reports');
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.money_outlined),
      //         title: const Text('Billing'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/generate-bill');
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.report),
      //         title: const Text('Transaction'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/transaction');
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.add_shopping_cart_sharp),
      //         title: const Text('business'),
      //         onTap: () {
      //           Navigator.pop(context);
      //           Navigator.pushNamed(context, '/business');
      //         },
      //       ),
      //       // Add other menu items
      //     ],
      //   ),
      // ),

      // appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          scaffoldKey: _scaffoldKey,
          onTruckFound: _updateFormWithTruck,
        ),
      ),
      drawer: const CustomDrawer(),

      // Main Content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAutocompleteField(
                controller: truckNumberController,
                label: 'Truck Number',
                getSuggestions: _logisticsService.fetchTrucks,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _doNumberController,
                label: 'DO Number',
                keyboardType: TextInputType.number,
              ),

              _buildTextFormField(
                controller: _driverNameController,
                label: 'Driver Name',
                keyboardType: TextInputType.text,
              ),
              _buildDropdownField(
                'Truck Type',
                ['Type 1', 'Type 2', 'Type 3'],
              ),
              const SizedBox(height: 16),
              _buildAutocompleteField(
                controller: vendorController,
                label: 'Vendor',
                getSuggestions: _logisticsService.fetchVendors,
                onSelected: (value) async {
                  double tdsRate = await _logisticsService.fetchTdsRate(value);
                  setState(() {
                    _tdsRateController.text = tdsRate.toString();
                  });
                },
              ),
              _buildDropdownField(
                'Transaction Status',
                ['Open'],
              ),

              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  handleDestinationFrom(textEditingValue.text);
                  return filteredDestinationFrom;
                },
                displayStringForOption: (option) => option['from'],
                onSelected: (selection) {
                  destinationFromController.text = selection['from'];
                  calculateRate();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  destinationFromController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Destination From',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  handleDestinationTo(textEditingValue.text);
                  return filteredDestinationTo;
                },
                displayStringForOption: (option) => option['to'],
                onSelected: (selection) {
                  destinationToController.text = selection['to'];
                  calculateRate();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  destinationToController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Destination To',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
          SizedBox(height: 16),
              _buildTextFormField(
                controller: weightController,
                label: 'Weight',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _freightController,
                // Use the controller's text to display the value
                label: 'Freight: ₹${_freightController.text}',
                keyboardType: TextInputType.number,
                readOnly: true,
          ),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _dieselController,
                label: 'Diesel',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _dieselAmountController,
                label: 'Diesel Amount',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _dieselSlipNumberController,
                label: 'Diesel Slip Number',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _tdsRateController,
                label: 'tds Rate',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _advanceController,
                label: 'Advance',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _tollController,
                label: 'Toll',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _adblueController,
                label: 'Adblue',
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                controller: _greasingController,
                label: 'Greasing',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required Future<List<String>> Function(String) getSuggestions,
    void Function(String)? onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<List<String>>(
        future: getSuggestions(''),
        builder: (context, snapshot) {
          return Autocomplete<String>(
            initialValue: TextEditingValue(text: controller.text),
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return await getSuggestions(textEditingValue.text);
            },
            onSelected: (String selection) {
              controller.text = selection;
              if (onSelected != null) {
                onSelected(selection);
              }
            },
            fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted
                ) {
              // Sync the external controller with the field controller
              fieldController.text = controller.text;

              return TextFormField(
                controller: fieldController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // Keep the external controller in sync
                  controller.text = value;
                },
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter $label' : null,
              );
            },
            optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options
                ) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          // Keep the label always visible
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildDropdownField(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (label == 'Truck Type') {
              selectedTruckType = value ?? '';
            } else if (label == 'Transaction Status') {
              selectedTransactionStatus = value ?? '';
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _dateController,
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              _dateController.text = picked.toString().split(' ')[0];
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a date';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    print("Entry is done");
    if (_formKey.currentState!.validate()) {
      try {
        // Update truck details object with form values

        // _truckDetails
        //   ..truckNumber = truckNumberController.text
        //   ..doNumber = _doNumberController.text
        //   ..driverName = _driverNameController.text
        //   ..vendor = vendorController.text
        //   ..destinationFrom = destinationFromController.text
        //   ..destinationTo = destinationToController.text
        //   ..truckType = selectedTruckType
        //   ..transactionStatus = selectedTransactionStatus
        //   ..freight = double.tryParse(_freightController.text) ?? 0.0
        //   ..weight = double.tryParse(weightController.text) ?? 0.0
        //   ..diesel = double.tryParse(_dieselController.text) ?? 0.0
        //   ..dieselAmount = double.tryParse(_dieselAmountController.text) ?? 0.0
        //   ..dieselSlipNumber = _dieselSlipNumberController.text
        //   ..tdsRate = double.tryParse(_tdsRateController.text) ?? 0.0
        //   ..advance = double.tryParse(_advanceController.text) ?? 0.0
        //   ..toll = double.tryParse(_tollController.text) ?? 0.0
        //   ..adblue = double.tryParse(_adblueController.text) ?? 0.0
        //   ..greasing = double.tryParse(_greasingController.text) ?? 0.0;

        // await _logisticsService.submitTruckDetails(_truckDetails);

        //new code
        TripDetails details = TripDetails(
          truckNumber: truckNumberController.text,
          username:'admin',
          profile:'admin',
          doNumber: _doNumberController.text,
          transactionStatus:'Open',
          driverName: _driverNameController.text,
          vendor: vendorController.text,
          destinationFrom: destinationFromController.text,
          destinationTo: destinationToController.text,
          truckType:selectedTruckType,
          weight: double.tryParse(weightController.text) ?? 0,
          freight: double.tryParse(_freightController.text) ?? 0,
          diesel: double.tryParse(_dieselController.text) ?? 0,
          dieselAmount: double.tryParse(_dieselAmountController.text) ?? 0,
          dieselSlipNumber: _dieselSlipNumberController.text,
          tdsRate: double.tryParse(_tdsRateController.text) ?? 0,
          advance: double.tryParse(_advanceController.text) ?? 0,
          toll: double.tryParse(_tollController.text) ?? 0,
          adblue: double.tryParse(_adblueController.text) ?? 0,
          greasing: double.tryParse(_greasingController.text) ?? 0,
        );

        await _logisticsService.submitTruckDetails(details);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details submitted successfully')),
        );

        // Clear form
        _formKey.currentState!.reset();
        // Clear all controllers
        truckNumberController.clear();
        _doNumberController.clear();
        _dateController.clear();
        // ... clear other controllers
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit details')),
        );
      }
    }
  }
}



