import 'package:flutter/material.dart';

class TruckDetailsScreen extends StatefulWidget {
  const TruckDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TruckDetailsScreen> createState() => _TruckDetailsScreenState();
}

class _TruckDetailsScreenState extends State<TruckDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _truckNumberController = TextEditingController();
  final _doNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _driverNameController = TextEditingController();
  // Add other controllers as needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // Custom AppBar with black strip
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.black,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle Button
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Image.asset(
                      'assets/logo.png', // Make sure to add your logo in assets
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Navigation Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Upload Truck Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Freight Master'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/freight'); // Navigates to the '/freight' route
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Vehicle Master'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vehicle');
              },
            ),
            ListTile(
              leading: const Icon(Icons.man),
              title: const Text('Vendor Master'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vendor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_outlined),
              title: const Text('Billing'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/generate-bill');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Transaction'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transaction');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_sharp),
              title: const Text('business'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/business');
              },
            ),
            // Add other menu items
          ],
        ),
      ),
      // Main Content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildImageUploadButton('Upload Truck Image'),
                    const SizedBox(height: 16),
                    _buildImageUploadButton('Loading Advice'),
                    const SizedBox(height: 16),
                    _buildImageUploadButton('Invoice-Company'),
                    const SizedBox(height: 16),
                    _buildImageUploadButton('Enlightenment Slip'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Form Fields
              _buildTextFormField(
                controller: _truckNumberController,
                label: 'Truck Number',
                keyboardType: TextInputType.text,
              ),
              _buildTextFormField(
                controller: _doNumberController,
                label: 'DO Number',
                keyboardType: TextInputType.number,
              ),
              _buildDatePicker(context),
              _buildTextFormField(
                controller: _driverNameController,
                label: 'Driver Name',
                keyboardType: TextInputType.text,
              ),
              _buildDropdownField('Vendor', ['Vendor 1', 'Vendor 2', 'Vendor 3']),
              _buildDropdownField('Destination From', ['Location 1', 'Location 2', 'Location 3']),
              _buildDropdownField('Destination To', ['Location 1', 'Location 2', 'Location 3']),
              _buildDropdownField('Truck Type', ['Type 1', 'Type 2', 'Type 3']),
              // Add other form fields
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle form submission
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadButton(String label) {
    return InkWell(
      onTap: () {
        // Handle image upload
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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
          // Handle dropdown change
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
      ),
    );
  }
}