import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FreightScreen extends StatefulWidget {
  @override
  _FreightScreenState createState() => _FreightScreenState();
}

class _FreightScreenState extends State<FreightScreen> {
  final String getFreightDataUrl = "http://192.168.130.219:5000/logistics/list-freight";
  final String insertFreightDataUrl = "http://192.168.130.219:5000/logistics/add-freight";
  final String updateFreightDataUrl = "http://192.168.130.219:5000/logistics/update-freight";

  List<Map<String, dynamic>> _freightList = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  String _message = "";
  int? _editingId;

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

  Future<void> _updateFreightData(int id) async {
    final oldData = _freightList.firstWhere((item) => item["id"] == id);
    final payload = {
      "old": {
        "from": oldData["from"],
        "to": oldData["to"],
        "rate": oldData["rate"],
      },
      "new": {
        "from": _fromController.text,
        "to": _toController.text,
        "rate": double.parse(_rateController.text),
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
            if (item["id"] == id) {
              return {
                "id": id,
                "from": payload["new"]?["from"],
                "to": payload["new"]?["to"],
                "rate": payload["new"]?["rate"],
              };
            }
            return item;
          }).toList();
          _message = "Freight data updated successfully!";
          _editingId = null;
        });
        _clearForm();
      } else {
        setState(() {
          _message = "Failed to update freight data.";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error updating data: $e";
      });
    }
  }

  void _clearForm() {
    _fromController.clear();
    _toController.clear();
    _rateController.clear();
  }

  void _startEditing(int id) {
    final data = _freightList.firstWhere((item) => item["id"] == id);
    _fromController.text = data["from"];
    _toController.text = data["to"];
    _rateController.text = data["rate"].toString();
    setState(() {
      _editingId = id;
    });
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
                    decoration: InputDecoration(labelText: "From Destination"),
                    validator: (value) => value!.isEmpty ? "Enter a source" : null,
                  ),
                  TextFormField(
                    controller: _toController,
                    decoration: InputDecoration(labelText: "To Destination"),
                    validator: (value) => value!.isEmpty ? "Enter a destination" : null,
                  ),
                  TextFormField(
                    controller: _rateController,
                    decoration: InputDecoration(labelText: "Rate"),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? "Enter a rate" : null,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _editingId == null
                        ? _addFreightData
                        : () => _updateFreightData(_editingId!),
                    child: Text(_editingId == null ? "Add Freight" : "Update Freight"),
                  ),
                  if (_message.isNotEmpty) Text(_message, style: TextStyle(color: Colors.green)),
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
                      subtitle: Text("Rate: \$${item['rate']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _startEditing(item["id"]),
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
