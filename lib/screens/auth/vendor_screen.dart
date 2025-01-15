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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              vendor.companyName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner: ${vendor.companyOwner}'),
                Text('TDS Rate: ${vendor.tdsRate}%'),
                Text('PAN: ${vendor.pan}'),
                Text('GST: ${vendor.gst}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Vendor Name',
                border: OutlineInputBorder(),
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
                prefixText: '₹ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter GST' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Submit'),
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
      body: Column(
        children: [
          _buildForm(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadVendorData,
              child: _buildVendorList(),
            ),
          ),
        ],
      ),
    );
  }
}