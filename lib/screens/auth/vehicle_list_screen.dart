import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import '../../config/model/vehicle_model.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/services/api_service.dart';
import '../../config/services/vehicle_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add this for date formatting
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ApiService {
  static const String baseUrl = 'https://shreelalchand.com/logistics';

  // You can add other API-related methods here if needed
  static String getDownloadUrl(String truckNo, String documentType) {
    return '$baseUrl/download/$truckNo/$documentType';
  }

  // static String getUploadUrl(String truckNo, String documentType) {
  //   return '$baseUrl/upload/$truckNo/$documentType';
  // }
}


class VehicleScreen extends StatefulWidget {
  const VehicleScreen({Key? key}) : super(key: key);

  @override
  _VehicleScreenState createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  final TextEditingController _truckNoController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _companyOwnerController = TextEditingController();
  // Add search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Vehicle> vehicles = [];
  List<Vehicle> filteredVehicles = []; // Add this for filtered results
  bool isLoading = true;
  bool isSubmitting = false;

  Map<String, Map<String, dynamic>> documents = {
    'registration': {'startDate': '', 'endDate': '', 'filePath': ''},
    'insurance': {'startDate': '', 'endDate': '', 'filePath': ''},
    'fitness': {'startDate': '', 'endDate': '', 'filePath': ''},
    'mv_tax': {'startDate': '', 'endDate': '', 'filePath': ''},
    'puc': {'startDate': '', 'endDate': '', 'filePath': ''},
    'ka_tax': {'startDate': '', 'endDate': '', 'filePath': ''},
    'basic_and_KA_permit': {'startDate': '', 'endDate': '', 'filePath': ''},
  };

  Map<String, String> displayNames = {
    'registration': 'Registration',
    'insurance': 'Insurance',
    'fitness': 'Fitness',
    'mv_tax': 'MV Tax',
    'puc': 'PUC',
    'ka_tax': 'KA Tax',
    'basic_and_KA_permit': 'Basic & KA Permit',
  };

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().replaceAll(' ', '');
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Add this method to filter vehicles
  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        return vehicle.truckNo.toLowerCase().contains(query) ||
            vehicle.make.toLowerCase().contains(query) ||
            vehicle.companyOwner.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/list-vehicle'));
      print('Raw API Response: ${response.body}');  // Add this line

      final data = await _vehicleService.getVehicles();
      setState(() {
        vehicles = data;
        filteredVehicles = data; // Initialize filtered list with all vehicles
        isLoading = false;
      });
    } catch (e) {
      print('Error details: $e');  // Add this line
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error in fetching vehicles data')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);
      try {
        Map<String, String> files = {};
        documents.forEach((key, value) {
          if (value['filePath'] != null && value['filePath'].isNotEmpty) {
            files[key] = value['filePath'];
          }
        });

        await _vehicleService.addVehicle(
          _truckNoController.text,
          _makeController.text,
          _companyOwnerController.text,
          documents,
          files,
        );

        _clearForm();
        await _loadVehicles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle details added Successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Adding vehicle details is Failed')),
          );
        }
      } finally {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _truckNoController.clear();
    _makeController.clear();
    _companyOwnerController.clear();
    setState(() {
      documents.forEach((key, value) {
        documents[key] = {'startDate': '', 'endDate': '', 'filePath': ''};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugShowCheckedModeBanner: false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAddVehicleForm(),
              const SizedBox(height: 24),
              _buildSearchBar(), // Add search bar
              const SizedBox(height: 16),
              _buildVehicleList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddVehicleForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Vehicle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _truckNoController,
                decoration: const InputDecoration(
                  labelText: 'Truck Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyOwnerController,
                decoration: const InputDecoration(
                  labelText: 'Company Owner',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Documents',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...documents.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DocumentField(
                  title: displayNames[entry.key] ?? entry.key,
                  data: entry.value,
                  onChanged: (startDate, endDate, filePath) {
                    setState(() {
                      documents[entry.key] = {
                        'startDate': startDate,
                        'endDate': endDate,
                        'filePath': filePath,
                      };
                    });
                  },
                ),
              )).toList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitForm,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF5C2F95), // Purple background
                   foregroundColor: Colors.white, // White text and icon color
                   disabledBackgroundColor: Colors.grey, // Grey background when disabled
                   disabledForegroundColor: Colors.white70, // Light white text/icon when disabled
                 ),
                child: isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Add Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this new widget for search bar
  // Widget _buildSearchBar() {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: TextField(
  //         controller: _searchController,
  //         decoration: InputDecoration(
  //           hintText: 'Search by truck number, make, or company owner',
  //           prefixIcon: const Icon(Icons.search),
  //           suffixIcon: _searchController.text.isNotEmpty
  //               ? IconButton(
  //             icon: const Icon(Icons.clear),
  //             onPressed: () {
  //               _searchController.clear();
  //               _filterVehicles();
  //             },
  //           )
  //               : null,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8.0),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by truck number (e.g., MH12AA8888, 8888, MH12)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().replaceAll(' ', '');
          });
        },
      ),
    );
  }


  Widget _buildVehicleList() {
    // Filter vehicles based on truck number search
    final filteredVehicles = _searchQuery.isEmpty
        ? vehicles
        : vehicles.where((vehicle) {
      final truckNo = vehicle.truckNo.toLowerCase().replaceAll(' ', '');
      // Check if the search query matches any part of the truck number
      return truckNo.contains(_searchQuery);
    }).toList();
    // return Column(
    //   crossAxisAlignment: CrossAxisAlignment.stretch,
    //   children: [
    //     Text(
    //       'Registered Vehicles',
    //       style: Theme.of(context).textTheme.titleLarge,
    //     ),
    //     const SizedBox(height: 16),
    //     if (isLoading)
    //       const Center(child: CircularProgressIndicator())
    //     else if (filteredVehicles.isEmpty)
    //       const Center(
    //         child: Padding(
    //           padding: EdgeInsets.all(16.0),
    //           child: Text(
    //             'No vehicles found matching your search criteria',
    //             style: TextStyle(fontSize: 16, color: Colors.grey),
    //           ),
    //         ),
    //       )
    //     else
    //       ListView.builder(
    //         shrinkWrap: true,
    //         physics: const NeverScrollableScrollPhysics(),
    //         itemCount: vehicles.length,
    //         itemBuilder: (context, index) {
    //           return VehicleCard(
    //             vehicle: vehicles[index],
    //             vehicleService: _vehicleService,
    //             displayNames: displayNames,
    //             onDocumentUpdated: () {
    //               // Reload the vehicles list when a document is updated
    //               _loadVehicles();
    //             },
    //           );
    //         },
    //       ),
    //   ],
    // );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Vehicles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                'Found ${filteredVehicles.length} vehicles',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filteredVehicles.isEmpty && _searchQuery.isNotEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No vehicles found with number "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try searching with full or partial truck number',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = filteredVehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                vehicleService: _vehicleService,
                displayNames: displayNames,
                onDocumentUpdated: () {
                  _loadVehicles();
                },
              );
            },
          ),
      ],
    );
  }
}

// class VehicleCard extends StatelessWidget {
//   final Vehicle vehicle;
//   final VehicleService vehicleService;
//   final Map<String, String> displayNames;
//
//   const VehicleCard({
//     Key? key,
//     required this.vehicle,
//     required this.vehicleService,
//     required this.displayNames,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildVehicleDetails(),
//             const Divider(height: 32),
//
//           ],
//         ),
//       ),
//     );
//   }


  //new code start

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VehicleService vehicleService;
  final Map<String, String> displayNames;
  final Function() onDocumentUpdated;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.vehicleService,
    required this.displayNames,
    required this.onDocumentUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  vehicle.truckNo,
                  // style: Theme.of(context).textTheme.titleLarge,
                  style: TextStyle(
                      fontSize: 18
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  vehicle.make,
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                children: [
                  _buildTableHeader('Field'),
                  _buildTableHeader('Validity (days left)'),
                  _buildTableHeader('Action'),
                ],
              ),
              ...vehicle.documents.entries.map((entry) {
                final String documentType = entry.key;
                final document = entry.value;

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    _buildTableCell(displayNames[documentType] ?? documentType),
                    _buildTableCell(
                      _getValidityText(document),
                      textColor: _getValidityColor(document),
                    ),
                    _buildActionCell(context, documentType, document),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  String _getValidityText(DocumentInfo document) {
    // if (document.endDate.isEmpty) return 'Not uploaded';
    // try {
    //   final endDate = DateTime.parse(document.endDate);
    //   final daysLeft = endDate.difference(DateTime.now()).inDays;
    //
    //   // Format the date in a readable format
    //   final formattedDate = DateFormat('yyyy-MM-dd').format(endDate);
    //
    //   if (daysLeft < 0) {
    //     return '$formattedDate (Expired)';
    //   } else {
    //     return '$formattedDate ($daysLeft days left)';
    //   }
    // } catch (e) {
    //   return 'Invalid date';
    // }

    if (document.daysLeft == null) return 'Not uploaded';

    // print('Document: ${document.filePath}, Days Left: ${document.daysLeft}');

    final int daysLeft = document.daysLeft!;

    if (daysLeft < 0) {
      return '${document.endDate} \n(Expired)';
    } else {
      return '${document.endDate} \n($daysLeft days left)';
    }
  }

  Color _getValidityColor(DocumentInfo document) {
    if (document.endDate.isEmpty) return Colors.grey;
    final endDate = DateTime.parse(document.endDate);
    final daysLeft = endDate
        .difference(DateTime.now())
        .inDays;
    if (daysLeft <= 5) return Colors.red;
    // if (daysLeft <= 30) return Colors.orange;
    return Colors.black;
  }


  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildActionCell(BuildContext context, String documentType,
      DocumentInfo document) {
    final bool needsUpload = document.endDate.isEmpty ||
        DateTime.parse(document.endDate).isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(
          needsUpload ? Icons.upload_file : Icons.download,
          color: needsUpload ? Colors.red : Colors.green,
        ),
        onPressed: () =>
        needsUpload
            ? _showUploadDialog(context, documentType)
            : _handleDownload(context, documentType),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, String documentType) {
    showDialog(
      context: context,
      builder: (context) =>
          DocumentUploadDialog(
            documentType: documentType,
            displayName: displayNames[documentType] ?? documentType,
            truckNo: vehicle.truckNo,
            // onUpload: (String filePath, DateTime startDate, DateTime endDate) async {
            //   try {
            //     await vehicleService.uploadDocument(
            //       vehicle.truckNo,
            //       documentType,
            //       filePath,
            //       startDate.toIso8601String(),
            //       endDate.toIso8601String(),
            //     );
            //     if (context.mounted) {
            //       Navigator.of(context).pop();
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //             content: Text('Document uploaded successfully')),
            //       );
            //       onDocumentUpdated();
            //     }
            //   } catch (e) {
            //     if (context.mounted) {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(content: Text('Error uploading document: $e')),
            //       );
            //     }
            //   }
            // },
            onSuccess: () {
              // Refresh the vehicle list
              onDocumentUpdated();
            },
          ),
    );
  }

  Future<void> _handleDownload(BuildContext context, String documentType) async {
    try {
      final String downloadUrl =
          '${ApiService.baseUrl}/download/${vehicle.truckNo}/$documentType';
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode == 200) {
        // Get the directory to save the file
        final Directory directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/$documentType.pdf';

        // Save the file
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Notify the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document downloaded successfully: $filePath')),
        );

        // Open the file
        OpenFile.open(filePath);
      } else {
        throw Exception('Failed to download document');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document: $e')),
        );
      }
    }
  }

}


class DocumentUploadDialog extends StatefulWidget {
  final String documentType;
  final String displayName;
  final String truckNo;
  final Function() onSuccess;
  // final Function(String filePath, DateTime startDate, DateTime endDate) onUpload;

  const DocumentUploadDialog({
    Key? key,
    required this.documentType,
    required this.displayName,
    // required this.onUpload,
    required this.truckNo,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _DocumentUploadDialogState createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  DateTime? startDate;
  DateTime? endDate;
  String? filePath;
  bool isUploading = false;// added new
  String? fileError; // New state variable for file error

  // Future<void> _pickFile() async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf'],
  //       allowMultiple: false,
  //     );
  //
  //     if (result != null) {
  //       setState(() {
  //         filePath = result.files.first.path;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error picking file: $e')),
  //       );
  //     }
  //   }
  // }

  //new file picker with popup of pdf and less than 1 mb
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Restrict to PDF only
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;

        // Check file type
        if (!file.path!.toLowerCase().endsWith('.pdf')) {
          setState(() {
            fileError = 'Please select a PDF file only';
            filePath = null; // Clear the file path if invalid
          });
          return;
        }

        // Check file size (1MB = 1 * 1024 * 1024 bytes)
        if (file.size > 1 * 1024 * 1024) {
          setState(() {
            fileError = 'File size must be less than 1MB';
            filePath = null; // Clear the file path if invalid
          });
          return;
        }

        // If all validations pass, clear error and set file path
        setState(() {
          filePath = file.path;
          fileError = null; // Clear any previous errors
        });
      }
    } catch (e) {
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Error picking file: $e'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
      setState(() {
        fileError = 'Error picking file: $e';
        filePath = null;
      });

    }
  }

  //added for upload
  Future<void> _handleUploadSubmit() async {
    if (startDate == null || endDate == null || filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    var uri = Uri.parse('${ApiService.baseUrl}/upload');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['truck_no'] = widget.truckNo;
      request.fields['field_name'] = widget.documentType;
      request.fields['start_date'] = startDate!.toIso8601String();
      request.fields['end_date'] = endDate!.toIso8601String();

      // Add file
      var file = await http.MultipartFile.fromPath('file', filePath!,contentType: MediaType('application', 'pdf'),);
      request.files.add(file);

      // // Set headers
      // request.headers['Content-Type'] = 'multipart/form-data';

      // // Debug logs
      // print('Sending request to: ${request.url}');
      // print('Fields: ${request.fields}');
      // print('Files: ${request.files.map((f) => "${f.filename} (${f.length} bytes)").toList()}');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');


      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close dialog
          widget.onSuccess(); // Refresh data
        }
      } else {
        throw Exception('Failed to upload document. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file. Please try again.\nError: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error uploading document: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }


  //end here

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload ${widget.displayName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(startDate == null
                  ? 'Select Start Date'
                  : 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: Text(endDate == null
                  ? 'Select End Date'
                  : 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            ListTile(
              title: Text(filePath == null ? 'Select File' : 'File: ${filePath!.split('/').last}'),
              trailing: const Icon(Icons.attach_file),
              onTap: _pickFile,
            ),
            if (fileError != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16,
                        color: Colors.red[700]
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileError!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Note section with file requirements
            // Container(
            //   padding: const EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     color: Colors.grey[100],
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(
            //       color: Colors.grey[300]!,
            //       width: 1,
            //     ),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         children: [
            //           Icon(Icons.info_outline,
            //               size: 20,
            //               color: Colors.blue[700]
            //           ),
            //           const SizedBox(width: 8),
            //           Text(
            //             'Note:',
            //             style: TextStyle(
            //               fontWeight: FontWeight.bold,
            //               color: Colors.blue[700],
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 8),
            //       const Text(
            //         '• File type must be PDF only\n'
            //             '• Maximum file size: 1MB\n'
            //             '• Document should be clear and readable',
            //         style: TextStyle(
            //           fontSize: 13,
            //           height: 1.5,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isUploading)
          const CircularProgressIndicator()
        else
          TextButton(
            onPressed: (startDate != null && endDate != null && filePath != null)
                ? _handleUploadSubmit
                : null,
            child: const Text('Upload'),
          ),
      ],
    );
  }
}

  //new code end



class DocumentField extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  final Function(String, String, String) onChanged;

  const DocumentField({
    Key? key,
    required this.title,
    required this.data,
    required this.onChanged,
  }) : super(key: key);

  // Future<void> _pickFile() async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
  //       allowMultiple: false,
  //     );
  //
  //     if (result != null) {
  //       final file = result.files.first;
  //       if (file.size > 10 * 1024 * 1024) { // 10MB limit
  //         throw Exception('File size exceeds 10MB limit');
  //       }
  //       onChanged(
  //         data['startDate'],
  //         data['endDate'],
  //         file.path ?? '',
  //       );
  //     }
  //   } catch (e) {
  //     // Show error dialog or snackbar
  //     debugPrint('Error picking file: $e');
  //   }
  // }

  Future<void> _pickFile(BuildContext context) async {  // Added context parameter
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Restrict to PDF only
        allowMultiple: false,
      );

      if (result != null) {
        final file = result.files.first;

        // Check file type
        if (!file.path!.toLowerCase().endsWith('.pdf')) {
          throw Exception('Please select a PDF file only');
        }

        // Check file size (1MB = 1 * 1024 * 1024 bytes)
        if (file.size > 1 * 1024 * 1024) {
          throw Exception('File size must be less than 1MB');
        }

        onChanged(
          data['startDate'],
          data['endDate'],
          file.path ?? '',
        );
      }
    } catch (e) {
      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('File Upload Error'),
              content: Text(e.toString()),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      debugPrint('Error picking file: $e');
    }
  }

  // Optional: Add a method to format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Optional: Add a method to verify file extension
  bool _isValidPdfExtension(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme
                .of(context)
                .textTheme
                .titleSmall),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDate(context, true),
              readOnly: true,
              controller: TextEditingController(text: data['startDate']),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDate(context, false),
              readOnly: true,
              controller: TextEditingController(text: data['endDate']),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickFile(context),  // Pass context here
                    icon: const Icon(Icons.attach_file,),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                    //   backgroundColor: const Color(0xFFF8F8F8), // Off-white background
                    //   foregroundColor: Colors.black, // Black text & icon
                      side: const BorderSide(color: Colors.black45, width: 1), // Black border
                    //   padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding
                    //   textStyle: const TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(8), // Rounded corners
                    //   ),
                    ),
                  ),
                ),
                if (data['filePath']?.isNotEmpty ?? false) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Colors.green[600]),
                ],
              ],
            ),
            if (data['filePath']?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'File selected: ${data['filePath']
                      .split('/')
                      .last}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStartDate ? now :
    (data['startDate'] != '' ? DateTime.parse(data['startDate']) : now);

    try {
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365 * 2)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme
                  .of(context)
                  .colorScheme
                  .copyWith(
                primary: Theme
                    .of(context)
                    .primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (date != null) {
        if (!isStartDate && date.isBefore(DateTime.parse(data['startDate']))) {
          throw Exception('End date cannot be before start date');
        }
        onChanged(
          isStartDate ? date.toIso8601String() : data['startDate'],
          isStartDate ? data['endDate'] : date.toIso8601String(),
          data['filePath'],
        );
      }
    } catch (e) {
      // Show error dialog or snackbar
      debugPrint('Error selecting date: $e');
    }
  }
}


