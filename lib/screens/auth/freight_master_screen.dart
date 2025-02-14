import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FreightScreen extends StatefulWidget {
  @override
  _FreightScreenState createState() => _FreightScreenState();
}

class _FreightScreenState extends State<FreightScreen> {
  final String getFreightDataUrl = "https://shreelalchand.com/logistics/list-freight";
  final String insertFreightDataUrl = "https://shreelalchand.com/logistics/add-freight";
  final String updateFreightDataUrl = "https://shreelalchand.com/logistics/update-freight";

  List<Map<String, dynamic>> _freightList = [];
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _editRateController = TextEditingController();
  String _message = "";

  @override
  void initState() {
    super.initState();
    _fetchFreightData();
  }

  Future<void> _fetchFreightData() async {
    try {
      final response = await http.get(Uri.parse(getFreightDataUrl));
      if (response.statusCode == 200) {
        setState(() {
          _freightList = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        setState(() {
          _message = "Failed to fetch data.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error fetching data: $e";
      });
    }
  }

  Future<void> _addFreightData() async {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "from_destination": _fromController.text,
        "to_destination": _toController.text,
        "rate": double.parse(_rateController.text),
      };
      try {
        final response = await http.post(
          Uri.parse(insertFreightDataUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(payload),
        );
        if (response.statusCode == 200) {
          setState(() {
            _freightList.add({
              "id": _freightList.length + 1,
              "from": payload["from_destination"],
              "to": payload["to_destination"],
              "rate": payload["rate"],
            });
            _message = "Freight data added successfully!";
          });
          _clearForm();
        } else {
          setState(() {
            _message = "Failed to add freight data.";
          });
        }
      } catch (e) {
        setState(() {
          _message = "Error adding data: $e";
        });
      }
    }
  }

  Future<void> _updateFreightData(Map<String, dynamic> oldData) async {
    if (_editFormKey.currentState!.validate()) {
      final payload = {
        "old": {
          "from": oldData["from"],
          "to": oldData["to"],
          "rate": oldData["rate"],
        },
        "new": {
          "from": oldData["from"],  // Keep the original from
          "to": oldData["to"],      // Keep the original to
          "rate": double.parse(_editRateController.text),
        },
      };

      try {
        final response = await http.post(
          Uri.parse(updateFreightDataUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(payload),
        );
        if (response.statusCode == 200) {
          setState(() {
            _freightList = _freightList.map((item) {
              if (item["id"] == oldData["id"]) {
                return {
                  ...item,
                  "rate": double.parse(_editRateController.text),
                };
              }
              return item;
            }).toList();
            _message = "Freight rate updated successfully!";
          });
          Navigator.of(context).pop(); // Close the dialog
        } else {
          setState(() {
            _message = "Failed to update freight rate.";
          });
        }
      } catch (e) {
        setState(() {
          _message = "Error updating rate: $e";
        });
      }
    }
  }

  void _clearForm() {
    _fromController.clear();
    _toController.clear();
    _rateController.clear();
  }

  void _showEditDialog(Map<String, dynamic> item) {
    _editRateController.text = item["rate"].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Freight Rate"),
          content: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "From: ${item['from']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "To: ${item['to']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _editRateController,
                  decoration: InputDecoration(
                    labelText: "Rate",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a rate";
                    }
                    if (double.tryParse(value) == null) {
                      return "Please enter a valid number";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => _updateFreightData(item),
              child: Text("Update Rate"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Freight Management")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fromController,
                    decoration: InputDecoration(
                      labelText: "From Destination",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter a source" : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _toController,
                    decoration: InputDecoration(
                      labelText: "To Destination",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter a destination" : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _rateController,
                    decoration: InputDecoration(
                      labelText: "Rate",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? "Enter a rate" : null,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addFreightData,
                    child: Text("Add Freight"),
                  ),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_message, style: TextStyle(color: Colors.green)),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _freightList.length,
                itemBuilder: (context, index) {
                  final item = _freightList[index];
                  return Card(
                    child: ListTile(
                      title: Text("${item['from']} to ${item['to']}"),
                      subtitle: Text("Rate: ₹${item['rate']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditDialog(item),
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
}