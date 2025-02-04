import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';

class ReportCard extends StatefulWidget {
  final TripDetails report;
  final Function()? onRefresh;

  const ReportCard({
    Key? key,
    required this.report,
    this.onRefresh,
  }) : super(key: key);

  @override
  _ReportCardState createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  final ReportsService _reportsService = ReportsService();
  bool isEditing = false;
  bool isLoading = false;
  Map<String, File?> selectedFiles = {};
  double weight = 0.00;
  late TextEditingController actualWeightController;
  String? transactionStatus;

  @override
  void initState() {
    super.initState();
    actualWeightController = TextEditingController(
      text: widget.report.actualWeight?.toString() ?? '',
    );
    transactionStatus = widget.report.transactionStatus ?? 'Open';
  }

  Future<void> _pickFile(String field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          selectedFiles[field] = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _downloadFile(String id, String field, String? originalName) async {
    try {
      await _reportsService.downloadFile(id, field, originalName);
      _showSuccess('File downloaded successfully');
    } catch (e) {
      _showError('Error downloading file: $e');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);
    try {
      await _reportsService.updateReport(
        widget.report.id!,
        weight,
        double.tryParse(actualWeightController.text) ?? 0.0, // ✅ Convert String to Double
        transactionStatus!,
        selectedFiles,
      );

      setState(() {
        isEditing = false;
        selectedFiles.clear();
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }

      _showSuccess('Changes saved successfully');
    } catch (e) {
      _showError('Error saving changes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }


  Widget _buildTransactionStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 120,
            child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? DropdownButton<String>(
              value: transactionStatus,
              isExpanded: true,
              hint: const Text('Select Status'),
              items: const [
                DropdownMenuItem(value: 'Open', child: Text('Open')),
                DropdownMenuItem(value: 'Acknowledged', child: Text('Acknowledged')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    transactionStatus = newValue;
                  });
                }
              },
            )
                : Text(widget.report.transactionStatus ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFileField(String label, String field, Map<String, dynamic>? fileData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? Row(
              children: [
                ElevatedButton(
                  onPressed: () => _pickFile(field),
                  child: Text(selectedFiles[field] != null ? 'Change File' : 'Select File'),
                ),
                if (selectedFiles[field] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(selectedFiles[field]!.path.split('/').last),
                  ),
              ],
            )
                : fileData != null && fileData['filepath'] != null
                ? TextButton.icon(
              onPressed: () => _downloadFile(widget.report.id!, field, fileData['originalname']),
              icon: const Icon(Icons.file_download),
              label: Text(fileData['originalname'] ?? 'Download'),
            )
                : const Text('No file', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert UTC DateTime to local
    final localDateTime = widget.report.createdAt!.toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${widget.report.truckNumber} - ${widget.report.doNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Format date in DD MMM YYYY format
              DateFormat('dd MMM yyyy').format(localDateTime),
            ),
            Text(
              // Format time in 12-hour format
              DateFormat('hh:mm a').format(localDateTime),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Trip ID', widget.report.tripId),
                _buildInfoRow('Driver', widget.report.driverName),
                _buildInfoRow('Vendor', widget.report.vendor),
                _buildInfoRow('From', widget.report.destinationFrom),
                _buildInfoRow('To', widget.report.destinationTo),
                _buildActualWeightField(),
                _buildTransactionStatusDropdown(),
                _buildFileField('Diesel Slip', 'dieselSlipImage', widget.report.dieselSlipImage),
                _buildFileField('Loading Advice', 'loadingAdvice', widget.report.loadingAdvice),
                _buildFileField('Invoice', 'invoiceCompany', widget.report.invoiceCompany),
                _buildFileField('Weightment Slip', 'weightmentSlip', widget.report.weightmentSlip),
                _buildActionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActualWeightField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 120,
            child: Text('Actual Weight', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? TextField(
              controller: actualWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )
                : Text(widget.report.actualWeight?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () {
            if (isEditing) {
              _saveChanges();
            } else {
              setState(() => isEditing = true);
            }
          },
          child: Text(isEditing ? 'Save' : 'Edit'),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
