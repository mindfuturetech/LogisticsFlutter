
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:logistics/widget/custom_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/model/truck_details_model.dart';
import '../../config/services/truck_details_service.dart';
import '../../config/services/update_truck_details_service.dart';
import '../../widget/custom_drawer.dart';

class TruckDetailsScreen extends StatefulWidget {
  final dynamic username;
  final String? profile;  // Add profile parameter
  final TripDetails? initialTripDetails;

  const TruckDetailsScreen({
    Key? key,
    this.username,
    this.initialTripDetails,
    this.profile,  // Add to constructor
  }) : super(key: key);

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
  bool searchCalled=false;
  late String username;
  String? profile;  // Add profile variable



  String baseUrl = 'https://shreelalchand.com/logistics';
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
  // final _dieselController = TextEditingController();
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

  // String selectedTruckType = '';
  // String selectedTransactionStatus = '';
  String? _editingId;
  String? selectedTruckType;
  List<String> truckTypes = ['Bulker', 'Bag', 'Others'];
  String? selectedTransactionStatus;
  List<String> transactionStatuses = ['Open','Acknowledged','Billed'];



  //
  // get truckDetails => null;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final args = ModalRoute.of(context)?.settings.arguments as String?;
    //   if (args != null) {
    //     setState(() {
    //       _username = args;
    //     });
    //   }
    //   print("Received username: $_username");
    // });

    // Add this to populate form with initial trip details if provided
    if (widget.initialTripDetails != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateFormWithTruck(widget.initialTripDetails);
      });
    }

    username = widget.username?.toString() ?? "Guest";
    // profile = widget.profile;  // Initialize profile
    _loadProfile(); // Load profile from SharedPreferences
    fetchDestinationData();
    weightController.addListener(_onWeightChanged);
    _freightController.text = '0.00';
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profile = prefs.getString('profile');
      print('Drawer loaded profile: $profile'); // Debug print
    });
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
    // _dieselController.dispose();
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
      searchCalled=true;
      print("Response body");
      if (truck != null) {
        _editingId=truck.tripId;
        truckNumberController.text = truck.truckNumber ?? '';
        _doNumberController.text = truck.doNumber ?? '';
        _driverNameController.text = truck.driverName ?? '';
        // _buildDropdownField.text = truck.truckType ?? '';
        vendorController.text = truck.vendor ?? '';
        destinationFromController.text = truck.destinationFrom ?? '';
        destinationToController.text = truck.destinationTo ?? '';
        weightController.text = truck.weight?.toString() ?? '';
        _freightController.text = truck.freight?.toString() ?? '';
        // _dieselController.text = truck.diesel?.toString() ?? '';
        _dieselAmountController.text = truck.dieselAmount?.toString() ?? '';
        _dieselSlipNumberController.text = truck.dieselSlipNumber ?? '';
        _tdsRateController.text = truck.tdsRate?.toString() ?? '';
        _advanceController.text = truck.advance?.toString() ?? '';
        _tollController.text = truck.toll?.toString() ?? '';
        _adblueController.text = truck.adblue?.toString() ?? '';
        _greasingController.text = truck.greasing?.toString() ?? '';
        // selectedTruckType = truckTypes.contains(truck.truckType) ? truck.truckType : null;
        selectedTransactionStatus = transactionStatuses.contains(truck.transactionStatus) ? truck.transactionStatus : null;
        // Automatically match the backend value with the options (case-insensitive and space-insensitive)
        if (truck.truckType != null) {
          selectedTruckType = truckTypes.firstWhere(
                (type) =>
            type.toLowerCase().replaceAll(' ', '') ==
                truck.truckType!.toLowerCase().replaceAll(' ', ''),
          );
        } else {
          selectedTruckType = null; // Or some default value
        }

      } else {
        _clearForm();
      }
    });
  }

  // void _clearForm() {
  //   truckNumberController.clear();
  //   _doNumberController.clear();
  //   _driverNameController.clear();
  //   vendorController.clear();
  //   destinationFromController.clear();
  //   destinationToController.clear();
  //   weightController.clear();    //**
  //   _freightController.clear();    //**
  //   _dieselController.clear();
  //   _dieselAmountController.clear();
  //   _dieselSlipNumberController.clear();
  //   _tdsRateController.clear();
  //   _advanceController.clear();
  //   _tollController.clear();
  //   _adblueController.clear();
  //   _greasingController.clear();
  //   _truckData = null;
  //   selectedTransactionStatus = null;
  //   selectedTruckType=null;
  // }
  void _clearForm() {
    setState(() {
      // Clear all text controllers
      truckNumberController.clear();
      _doNumberController.clear();
      _dateController.clear();
      _driverNameController.clear();
      vendorController.clear();
      destinationFromController.clear();
      destinationToController.clear();
      weightController.clear();
      _freightController.clear();
      // _dieselController.clear();
      _dieselAmountController.clear();
      _dieselSlipNumberController.clear();
      _tdsRateController.clear();
      _advanceController.clear();
      _tollController.clear();
      _adblueController.clear();
      _greasingController.clear();

      // Reset dropdown selections
      selectedTruckType = null;
      selectedTransactionStatus = null;

      // Reset any stored data
      _truckData = null;
      _editingId = null;

      // Reset form key if needed
      if (_formKey.currentState != null) {
        _formKey.currentState!.reset();
      }

      // Reset any calculated values
      freight = 0;
      _freightController.text = '0.00';
    });
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> options,
    String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue, // Use the passed selectedValue
      onChanged: onChanged, // Use the passed onChanged callback
      items: options.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(  // Adding border here
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
          borderSide: BorderSide(
            color: Colors.grey, // Border color
            width: 1.0, // Border width
          ),
        ),
        // Optionally, you can add padding or other styles here
        contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // username = ModalRoute.of(context)?.settings.arguments as String?;
    // print("Received username in build: $username");

    return Scaffold(
      key: _scaffoldKey,
      // appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          scaffoldKey: _scaffoldKey,
          onTruckFound: _updateFormWithTruck,
          // profile: profile,  // Pass the profile here
        ),
      ),
      // drawer: const CustomDrawer(),
      drawer: CustomDrawer(),

      // Main Content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_editingId != null) ...[
                _buildTextFormField(
                  controller: TextEditingController(text: _editingId),
                  label: 'Trip ID',
                  readOnly: true,
                ),
                const SizedBox(height: 16),
              ],
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
              // _buildDropdownField(
              //   'Truck Type',
              //   ['Type 1', 'Type 2', 'Type 3'],
              // ),
              _buildDropdownField(
                label: 'Truck Type',
                options: truckTypes,
                selectedValue: selectedTruckType,
                onChanged: (value) {
                  setState(() {
                    selectedTruckType = value!;
                  });
                },
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
              // _buildDropdownField(
              //   'Transaction Status',
              //   ['Open'],
              // ),

              _buildDropdownField(
                label: 'Transaction Status',
                options: _editingId == null ? ['Open'] : transactionStatuses,
                selectedValue: selectedTransactionStatus ?? 'Open',
                onChanged: _editingId == null
                    ? (value) {} // Provide an empty function instead of null
                    : (value) {
                  setState(() {
                    selectedTransactionStatus =  value ?? 'Open';
                  });
                },
              ),


              const SizedBox(height: 16),
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
              // _buildTextFormField(
              //   controller: _dieselController,
              //   label: 'Diesel',
              //   keyboardType: TextInputType.number,
              // ),
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
                label: 'TDS Rate',
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


  // Widget _buildDropdownField(String label, List<String> items) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: DropdownButtonFormField<String>(
  //       decoration: InputDecoration(
  //         labelText: label,
  //         border: const OutlineInputBorder(),
  //       ),
  //       items: items.map((String value) {
  //         return DropdownMenuItem<String>(
  //           value: value,
  //           child: Text(value),
  //         );
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           if (label == 'Truck Type') {
  //             selectedTruckType = value ?? '';
  //           } else if (label == 'Transaction Status') {
  //             selectedTransactionStatus = value ?? '';
  //           }
  //         });
  //       },
  //       validator: (value) {
  //         if (value == null || value.isEmpty) {
  //           return 'Please select $label';
  //         }
  //         return null;
  //       },
  //     ),
  //   );
  // }

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
    if (_formKey.currentState!.validate()) {
      try {
        //new code
        final TripDetails details = TripDetails(
          tripId: _editingId,
          truckNumber: truckNumberController.text,
          username:username,
          profile:profile,
          doNumber: _doNumberController.text,
          // transactionStatus:selectedTransactionStatus,
          transactionStatus: selectedTransactionStatus ?? 'Open',
          driverName: _driverNameController.text,
          vendor: vendorController.text,
          destinationFrom: destinationFromController.text,
          destinationTo: destinationToController.text,
          truckType:selectedTruckType,
          weight: double.tryParse(weightController.text) ?? 0,
          freight: double.tryParse(_freightController.text) ?? 0,
          // diesel: double.tryParse(_dieselController.text) ?? 0,
          dieselAmount: double.tryParse(_dieselAmountController.text) ?? 0,
          dieselSlipNumber: _dieselSlipNumberController.text,
          tdsRate: double.tryParse(_tdsRateController.text) ?? 0,
          advance: double.tryParse(_advanceController.text) ?? 0,
          toll: double.tryParse(_tollController.text) ?? 0,
          adblue: double.tryParse(_adblueController.text) ?? 0,
          greasing: double.tryParse(_greasingController.text) ?? 0,
        );




        if (searchCalled) {
          // Call update method
          // await _logisticsService.updateTruckDetails(details);
          // Create an instance of the service
          print("editingId : $_editingId");
          final truckService = TruckService();
          bool success = await truckService.updateTruckDetails(details);

          if (success) {
            // Show success message for update
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Details updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // Show error message if update fails
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update details'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }

        } else {
          // Call create method
          await _logisticsService.submitTruckDetails(details);

           // Show success message for create
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details submitted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        searchCalled=false;
          // Clear form
        _clearForm();
        _formKey.currentState!.reset();
        // Clear all controllers
        truckNumberController.clear();
        _doNumberController.clear();
        _dateController.clear();
        // ... clear other controllers
        _driverNameController.clear();
        vendorController.clear();
        destinationFromController.clear();
        destinationToController.clear();
        weightController.clear();
        _freightController.clear();
        // _dieselController.clear();
        _dieselAmountController.clear();
        _dieselSlipNumberController.clear();
        _tdsRateController.clear();
        _advanceController.clear();
        _tollController.clear();
        _adblueController.clear();
        _greasingController.clear();
        selectedTruckType = null;
        selectedTransactionStatus = null;


      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit details')),
        );
      }
    }
  }
}




