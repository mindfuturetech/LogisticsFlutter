import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
    // Make sure it's one of the valid options
    transactionStatus = widget.report.transactionStatus ?? 'Open';
    if (!['Open', 'Acknowledged'].contains(transactionStatus)) {
      transactionStatus = 'Open';
    }
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

  Future<void> _downloadFile(String id, String field,
      Map<String, dynamic>? fileData) async {
    if (!mounted) return;

    // Check if we have valid file data
    if (fileData == null || fileData['originalname'] == null) {
      _showError('File information is missing');
      return;
    }

    setState(() => isLoading = true);

    try {
      print(
          'Starting download - ID: $id, Field: $field, File: ${fileData['originalname']}');

      await _reportsService.downloadFile(
        id,
        field,
        fileData['originalname'],
      );

      if (mounted) {
        _showSuccess('File downloaded successfully');
      }
    } catch (e) {
      print('Download failed: $e');
      if (mounted) {
        _showError(e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  Future<void> _saveChanges() async {
    setState(() => isLoading = true);
    try {
      await _reportsService.updateReport(
        widget.report.id!,
        weight,
        double.tryParse(actualWeightController.text) ?? 0.0,
        // ✅ Convert String to Double
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
    final List<String> statusOptions = ['Open', 'Acknowledged'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 120,
            child: Text(
                'Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? DropdownButton<String>(
              value: transactionStatus,
              isExpanded: true,
              hint: const Text('Select Status'),
              items: statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
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

  // Update your _buildFileField method to handle download state
  Widget _buildFileField(String label, String field,
      Map<String, dynamic>? fileData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
                label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? Row(
              children: [
                ElevatedButton(
                  onPressed: () => _pickFile(field),
                  child: Text(selectedFiles[field] != null
                      ? 'Change File'
                      : 'Select File'),
                ),
                if (selectedFiles[field] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(selectedFiles[field]!
                        .path
                        .split('/')
                        .last),
                  ),
              ],
            )
                : fileData != null && fileData['filepath'] != null
                ? TextButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _downloadFile(widget.report.id!, field, fileData),
              icon: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.file_download),
              label: Text(
                  isLoading
                      ? 'Downloading...'
                      : fileData['originalname'] ?? 'Download'
              ),
            )
                : const Text('No file', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localDateTime = widget.report.createdAt!.toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text('${widget.report.truckNumber} - ${widget.report.doNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(localDateTime),
            ),
            Text(
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
                _buildInfoRow('User Name', widget.report.username),
                _buildInfoRow('Profile', widget.report.profile),
                _buildInfoRow('Driver', widget.report.driverName),
                _buildInfoRow('Vendor', widget.report.vendor),
                _buildInfoRow('From', widget.report.destinationFrom),
                _buildInfoRow('To', widget.report.destinationTo),
                _buildInfoRow('Bill ID', widget.report.billingId),
                _buildActualWeightField(),
                _buildTransactionStatusDropdown(),
                _buildFileField('Diesel Slip', 'DieselSlipImage',
                    widget.report.DieselSlipImage),
                _buildFileField('Loading Advice', 'LoadingAdvice',
                    widget.report.LoadingAdvice),
                _buildFileField(
                    'Invoice', 'InvoiceCompany', widget.report.InvoiceCompany),
                _buildFileField('Weightment Slip', 'WeightmentSlip',
                    widget.report.WeightmentSlip),
                _buildActionButton(),
                // Added download button here
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
            child: Text(
                'Actual Weight', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SizedBox(width: 120,
              child: Text(
                  label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
