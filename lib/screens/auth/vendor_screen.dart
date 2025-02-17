import 'package:flutter/material.dart';

import '../../config/model/vendor_model.dart';
import '../../config/services/vendor_service.dart';

class VendorScreen extends StatefulWidget {
  @override
  _VendorScreenState createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  final VendorService _vendorService = VendorService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyOwnerController = TextEditingController();
  final TextEditingController _tdsRateController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  // State variables
  List<VendorModel> vendorList = [];
  bool isLoading = false;
  String? error;
  String? submitMessage;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyOwnerController.dispose();
    _tdsRateController.dispose();
    _panController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  // Data loading methods
  Future<void> _loadVendorData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _vendorService.getVendorList();
      if (!mounted) return;

      setState(() {
        vendorList = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        submitMessage = null;
      });

      try {
        final vendor = VendorModel(
          companyName: _companyNameController.text.trim(),
          companyOwner: _companyOwnerController.text.trim(),
          tdsRate: double.parse(_tdsRateController.text.trim()),
          pan: _panController.text.trim().toUpperCase(),
          gst: _gstController.text.trim().toUpperCase(),
        );

        await _vendorService.addVendor(vendor);
        _clearForm();
        await _loadVendorData();

        if (!mounted) return;
        setState(() {
          submitMessage = 'Vendor added successfully';
          isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          submitMessage = 'Error: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _companyNameController.clear();
    _companyOwnerController.clear();
    _tdsRateController.clear();
    _panController.clear();
    _gstController.clear();
  }

  // UI Building methods
  Widget _buildVendorList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Text('Error: $error', style: const TextStyle(color: Colors.red));
    }

    if (vendorList.isEmpty) {
      return const Center(child: Text('No vendors found'));
    }

    return ListView.builder(
      itemCount: vendorList.length,
      itemBuilder: (context, index) {
        final vendor = vendorList[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Owner: ${vendor.companyOwner}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
                      _buildSection('Company Details', [
                        _buildInfoRow('Company Name', vendor.companyName),
                        _buildInfoRow('Owner Name', vendor.companyOwner),
                      ]),
                      const Divider(height: 32),
                      _buildSection('Financial Information', [
                        _buildInfoRow('TDS Rate', '${vendor.tdsRate}%'),
                        _buildInfoRow('PAN', vendor.pan),
                        _buildInfoRow('GST', vendor.gst),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter vendor name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyOwnerController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Owner',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter vendor owner' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tdsRateController,
                decoration: const InputDecoration(
                  labelText: 'TDS Rate (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter TDS rate';
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter PAN' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter GST' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C2F95),
                    // Purple background
                    foregroundColor: Colors.white,
                    // White text and icon color
                    disabledBackgroundColor: Colors.grey,
                    // Grey background when disabled
                    disabledForegroundColor: Colors
                        .white70, // Light white text/icon when disabled
                  ),
                  icon: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.add_business),
                  label: const Text(
                    'Add Vendor',
                    style: TextStyle(
                        color: Colors.white), // Ensure text is white
                  ),
                ),
              ),

              if (submitMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    submitMessage!,
                    style: TextStyle(
                      color: submitMessage!.startsWith('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVendorData,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate remaining height after form and header
          final listHeight = constraints.maxHeight -
              (MediaQuery
                  .of(context)
                  .size
                  .height * 0.45); // Adjust this factor as needed

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildForm(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.business, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Vendor List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${vendorList.length} vendors',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: listHeight,
                  child: RefreshIndicator(
                    onRefresh: _loadVendorData,
                    child: _buildVendorList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}