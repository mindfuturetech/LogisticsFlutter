import 'package:flutter/material.dart';
import '../../config/model/vehicle_model.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/services/vehicle_service.dart';


class VehicleScreen extends StatefulWidget {
  const VehicleScreen({Key? key}) : super(key: key);

  @override
  _VehicleScreenState createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final TextEditingController _truckNoController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _companyOwnerController = TextEditingController();

  List<Vehicle> vehicles = [];
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
  }

  Future<void> _loadVehicles() async {
    try {
      final data = await _apiService.getVehicles();
      setState(() {
        vehicles = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicles: $e')),
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

        await _apiService.addVehicle(
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
            const SnackBar(content: Text('Vehicle added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding vehicle: $e')),
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

  Widget _buildVehicleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Registered Vehicles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return VehicleCard(
                vehicle: vehicles[index],
                apiService: _apiService,
                displayNames: displayNames,
              );
            },
          ),
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final ApiService apiService;
  final Map<String, String> displayNames;

  const VehicleCard({
    Key? key,
    required this.vehicle,
    required this.apiService,
    required this.displayNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleDetails(),
            const Divider(height: 32),
            _buildDocuments(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Truck Number:', vehicle.truckNo),
        _buildDetailRow('Make:', vehicle.make),
        _buildDetailRow('Company Owner:', vehicle.companyOwner),
      ],
    );
  }

  Widget _buildDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: vehicle.documents.entries.map((entry) {
        if (entry.value != null) {
          final bool isExpiring = (entry.value.daysLeft ?? 0) <= 5;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNames[entry.key] ?? entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpiring ? Colors.red : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Valid: ${entry.value.startDate} to ${entry.value.endDate}'),
                if (isExpiring)
                  Text(
                    '${entry.value.daysLeft} days left',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        // Update the document data with the new file path
        onChanged(
          data['startDate'],
          data['endDate'],
          file.path ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
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
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Upload Document'),
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
                  'File selected: ${data['filePath'].split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: isStartDate
          ? DateTime.now().subtract(const Duration(days: 365))
          : DateTime.parse(data['startDate'] != '' ? data['startDate'] : DateTime.now().toIso8601String()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      onChanged(
        isStartDate ? date.toIso8601String() : data['startDate'],
        isStartDate ? data['endDate'] : date.toIso8601String(),
        data['filePath'],
      );
    }
  }
}