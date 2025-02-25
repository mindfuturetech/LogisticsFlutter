import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../config/model/truck_details_model.dart';
import '../../config/services/reports_service.dart';
import '../../config/services/search_service.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ReportCard extends StatefulWidget {
  final TripDetails report;
  final Function()? onRefresh;
  // Added this new parameter
  final Function(TripDetails?)? onTripFound;


  const ReportCard({
    Key? key,
    required this.report,
    this.onRefresh,
    this.onTripFound,  // Add this
  }) : super(key: key);

  @override
  _ReportCardState createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  final ReportsService _reportsService = ReportsService();

  // Add this line
  final ApiSearchService _searchService = ApiSearchService();
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
  // Remove the compression method and add file size check method
  Future<bool> _checkFileSize(File file) async {
    final fileSize = await file.length();
    // 1 MB = 1048576 bytes
    final oneMB = 1048576;
    return fileSize <= oneMB;
  }

// Update your _pickFile method with size validation
  Future _pickFile(String field) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File originalFile = File(result.files.single.path!);

        // Check file size
        bool isValidSize = await _checkFileSize(originalFile);

        if (!isValidSize) {
          _showError('File size exceeds 1MB limit. Please upload a smaller file.');
          return;
        }

        setState(() {
          selectedFiles[field] = originalFile;
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

// Update your _saveChanges method (without compression)
  Future _saveChanges() async {
    setState(() => isLoading = true);
    try {
      // Create a map to store upload results
      Map<String, dynamic> uploadedFiles = {};

      // Upload each file
      for (var entry in selectedFiles.entries) {
        if (entry.value != null) {
          try {
            print('Preparing to upload file for field: ${entry.key}');

            // Upload the file and get the response
            var uploadResult = await _reportsService.uploadFile(
              entry.value!,
              entry.key,
            );

            print('Upload result for ${entry.key}: $uploadResult');

            if (uploadResult != null) {
              // Store the result
              uploadedFiles[entry.key] = uploadResult;
            }
          } catch (e) {
            print('Error uploading ${entry.key}: $e');
            // Continue with other files even if one fails
            _showError('Error uploading ${entry.key}: $e');
          }
        }
      }

      print('All uploads finished. uploadedFiles: $uploadedFiles');

      // Check if any files were uploaded successfully
      if (uploadedFiles.isEmpty && selectedFiles.isNotEmpty) {
        _showError('No files were uploaded successfully.');
        setState(() => isLoading = false);
        return;
      }

      print('Preparing to update report...');

      // Update report with file information
      await _reportsService.updateReport(
        widget.report.id!,
        weight,
        double.tryParse(actualWeightController.text) ?? 0.0,
        transactionStatus!,
        uploadedFiles,
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
      print('Error in _saveChanges: $e');
      _showError('Error saving changes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }


  Future<void> _downloadFile(String id, String field, Map<String, dynamic>? fileData) async {
    if (!mounted) return;

    if (fileData == null || fileData['originalname'] == null) {
      _showError('File information is missing');
      return;
    }

    setState(() => isLoading = true);

    try {
      print('Starting download - ID: $id, Field: $field, File: ${fileData['originalname']}');

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

  // Future<void> _saveChanges() async {
  //   setState(() => isLoading = true);
  //   try {
  //     // Create a map to store upload results
  //     Map<String, dynamic> uploadedFiles = {}; // Change this to Map<String, dynamic>
  //
  //     // Upload and compress each file
  //     for (var entry in selectedFiles.entries) {
  //       if (entry.value != null) {
  //         try {
  //           // Upload the file and get the response
  //           var uploadResult = await _reportsService.uploadFile(
  //             entry.value!,
  //             entry.key,
  //           );
  //
  //           if (uploadResult != null) {
  //             uploadedFiles[entry.key] = uploadResult; // Now this should work
  //           }
  //         } catch (e) {
  //           print('Error uploading ${entry.key}: $e');
  //         }
  //       }
  //     }
  //
  //     // Update report with file information
  //     await _reportsService.updateReport(
  //       widget.report.id!,
  //       weight,
  //       double.tryParse(actualWeightController.text) ?? 0.0,
  //       transactionStatus!,
  //       selectedFiles,
  //       uploadedFiles: uploadedFiles, // Pass the uploaded files information
  //     );
  //
  //     setState(() {
  //       isEditing = false;
  //       selectedFiles.clear();
  //     });
  //
  //     if (widget.onRefresh != null) {
  //       widget.onRefresh!();
  //     }
  //
  //     _showSuccess('Changes saved successfully');
  //   } catch (e) {
  //     _showError('Error saving changes: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
  // Future<void> _pickFile(String field) async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['jpg', 'jpeg', 'png',],
  //     );
  //
  //     if (result != null) {
  //       setState(() {
  //         selectedFiles[field] = File(result.files.single.path!);
  //       });
  //     }
  //   } catch (e) {
  //     _showError('Error picking file: $e');
  //   }
  // }
  //
  // Future<void> _downloadFile(String id, String field,
  //     Map<String, dynamic>? fileData) async {
  //   if (!mounted) return;
  //
  //   // Check if we have valid file data
  //   if (fileData == null || fileData['originalname'] == null) {
  //     _showError('File information is missing');
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     print(
  //         'Starting download - ID: $id, Field: $field, File: ${fileData['originalname']}');
  //
  //     await _reportsService.downloadFile(
  //       id,
  //       field,
  //       fileData['originalname'],
  //     );
  //
  //     if (mounted) {
  //       _showSuccess('File downloaded successfully');
  //     }
  //   } catch (e) {
  //     print('Download failed: $e');
  //     if (mounted) {
  //       _showError(e.toString().replaceAll('Exception:', '').trim());
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => isLoading = false);
  //     }
  //   }
  // }
  //
  //
  // Future<void> _saveChanges() async {
  //   setState(() => isLoading = true);
  //   try {
  //     await _reportsService.updateReport(
  //       widget.report.id!,
  //       weight,
  //       double.tryParse(actualWeightController.text) ?? 0.0,
  //       // ✅ Convert String to Double
  //       transactionStatus!,
  //       selectedFiles,
  //     );
  //
  //     setState(() {
  //       isEditing = false;
  //       selectedFiles.clear();
  //     });
  //
  //     if (widget.onRefresh != null) {
  //       widget.onRefresh!();
  //     }
  //
  //     _showSuccess('Changes saved successfully');
  //   } catch (e) {
  //     _showError('Error saving changes: $e');
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

  // Add this new method
  Future<void> _handleTripSearch(String tripId) async {
    setState(() => isLoading = true);
    try {
      final tripDetails = await _searchService.searchUserById(tripId);
      if (tripDetails != null) {
        if (widget.onTripFound != null && widget.onTripFound != null) {
          widget.onTripFound!(tripDetails);
        }
      } else {
        _showError('Trip details not found');
      }
    } catch (e) {
      _showError('Error searching trip: $e');
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
                'Transaction Status',
                style: TextStyle(fontWeight: FontWeight.bold)),
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



  Widget _buildFileField(String label, String field, Map<String, dynamic>? fileData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: isEditing
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _pickFile(field),
                  child: Text(selectedFiles[field] != null ? 'Change File' : 'Select File'),
                ),
                if (selectedFiles[field] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: Text(
                      path.basename(selectedFiles[field]!.path),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (selectedFiles[field] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      'File size must be under 1MB',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
                    : fileData['originalname'] ?? 'Download',
                softWrap: true,
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
    // Add selection logic if needed

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truck Number: ${widget.report.truckNumber ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(localDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a').format(localDateTime),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  _buildTripInformation(),
                  const Divider(height: 32),
                  _buildFinancialInformation(),
                  const SizedBox(height: 16),
                  _buildActualWeightField(),
                  _buildTransactionStatusDropdown(),
                  _buildDocumentSection(),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          children: [
            _buildInfoRow('Trip ID', widget.report.tripId, isTripId: true),
            _buildInfoRow('DO Number', widget.report.doNumber?.toString()),
            _buildInfoRow('User Name', widget.report.username),
            _buildInfoRow('Profile', widget.report.profile),
            _buildInfoRow('Driver', widget.report.driverName),
            _buildInfoRow('Vendor', widget.report.vendor),
            _buildInfoRow('From', widget.report.destinationFrom),
            _buildInfoRow('To', widget.report.destinationTo),
            _buildInfoRow('Bill ID', widget.report.billingId),
            _buildInfoRow('Truck Type', widget.report.truckType),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3,
          children: [
            _buildInfoRow('Diesel Amount',
                widget.report.dieselAmount != null
                    ? '₹${widget.report.dieselAmount?.toStringAsFixed(2)}'
                    : null),
            _buildInfoRow('Weight',
                widget.report.weight != null
                    ? '${widget.report.weight?.toStringAsFixed(2)} tons'
                    : null),
            _buildInfoRow('Difference',
                widget.report.differenceInWeight != null
                    ? '${widget.report.differenceInWeight?.toStringAsFixed(
                    2)} tons'
                    : null),
            _buildInfoRow('Freight',
                widget.report.freight != null
                    ? '₹${widget.report.freight?.toStringAsFixed(2)}'
                    : null),
            _buildInfoRow('Diesel Slip Number',
                widget.report.dieselSlipNumber?.toString()),
            _buildInfoRow('TDS Rate', widget.report.tdsRate?.toString()),
            _buildInfoRow('Advance',
                widget.report.advance != null
                    ? '₹${widget.report.advance?.toStringAsFixed(2)}'
                    : null),
            _buildInfoRow('Toll',
                widget.report.toll != null
                    ? '₹${widget.report.toll?.toStringAsFixed(2)}'
                    : null),
            _buildInfoRow('Adblue',
                widget.report.adblue != null
                    ? '₹${widget.report.adblue?.toStringAsFixed(2)}'
                    : null),
            _buildInfoRow('Greasing',
                widget.report.greasing != null
                    ? '₹${widget.report.greasing?.toStringAsFixed(2)}'
                    : null),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        _buildFileField(
            'Diesel Slip', 'DieselSlipImage', widget.report.DieselSlipImage),
        _buildFileField(
            'Loading Advice', 'LoadingAdvice', widget.report.LoadingAdvice),
        _buildFileField(
            'Invoice', 'InvoiceCompany', widget.report.InvoiceCompany),
        _buildFileField(
            'Weightment Slip', 'WeightmentSlip', widget.report.WeightmentSlip),
      ],
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


  Widget _buildInfoRow(String label, String? value, {bool isTripId = false}) {
    if (isTripId) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (value != null) {
                _handleTripSearch(value);
              }
            },
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }
}
