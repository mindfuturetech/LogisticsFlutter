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

  List<VendorModel> vendorList = [];
  bool isLoading = false;
  String? error;
  String? submitMessage;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyOwnerController = TextEditingController();
  final TextEditingController _tdsRateController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _vendorService.getVendorList();
      print('Fetched vendor data: $data');  // Debugging statement

      if (data.isNotEmpty) {
        setState(() {
          vendorList = data;
          isLoading = false;
        });
      } else {
        setState(() {
          vendorList = [];
          isLoading = false;
        });
      }
    } catch (e) {
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
        await _loadVendorData();

        _clearForm();
        setState(() {
          submitMessage = 'Vendor added successfully';
          isLoading = false;
        });
      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Management'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Form Fields
                  TextFormField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      labelText: 'Vendor Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter vendor name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _companyOwnerController,
                    decoration: InputDecoration(
                      labelText: 'Vendor Owner',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter vendor owner';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _tdsRateController,
                    decoration: InputDecoration(
                      labelText: 'TDS Rate (%)',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter TDS rate';
                      }
                      if (double.tryParse(value!) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _panController,
                    decoration: InputDecoration(
                      labelText: 'PAN',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter PAN';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _gstController,
                    decoration: InputDecoration(
                      labelText: 'GST',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter GST';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  if (submitMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
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
            SizedBox(height: 24),
            Text(
              'Vendor List',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (error != null)
              Text('Error: $error', style: TextStyle(color: Colors.red))
            else if (vendorList.isEmpty)
                Text('No vendor data available')
              else
              // Wrap ListView.builder with Expanded widget
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: vendorList.length,
                    itemBuilder: (context, index) {
                      final vendor = vendorList[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.companyName),
                              Text(vendor.companyOwner),
                              Text('₹ ${vendor.tdsRate.toStringAsFixed(2)}%'),
                              Text('PAN: ${vendor.pan}'),
                              Text('GST: ${vendor.gst}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
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
}
