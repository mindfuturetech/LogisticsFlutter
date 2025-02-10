import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileHandlingWidget extends StatefulWidget {
  final String label;
  final String field;
  final Map<String, dynamic>? fileData;
  final String tripId;
  final bool isEditing;
  final Function(String)? onFilePick;
  final String baseUrl;

  const FileHandlingWidget({
    Key? key,
    required this.label,
    required this.field,
    required this.fileData,
    required this.tripId,
    required this.isEditing,
    this.onFilePick,
    this.baseUrl = 'https://mindfuturetechsupport.com/logistics',
  }) : super(key: key);

  @override
  State<FileHandlingWidget> createState() => _FileHandlingWidgetState();
}

class _FileHandlingWidgetState extends State<FileHandlingWidget> {
  bool isLoading = false;
  final dio = Dio();

  Future<void> downloadFile() async {
    if (!mounted) return;

    // Check if file data exists
    if (widget.fileData == null ||
        widget.fileData!['originalname'] == null ||
        widget.tripId.isEmpty) {
      _showError(context, 'File information is missing');
      return;
    }

    setState(() => isLoading = true);

    try {
      final fileName = widget.fileData!['originalname'];
      final downloadDir = await _getDownloadPath();
      final savePath = '$downloadDir/$fileName';

      print('Downloading file from: ${widget.baseUrl}/api/download/${widget.tripId}/${widget.field}/$fileName');
      print('Saving to: $savePath');

      await dio.download(
        '${widget.baseUrl}/api/download/${widget.tripId}/${widget.field}/$fileName',
        savePath,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download Progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      if (mounted) {
        _showSuccess(context, 'File downloaded to Downloads folder');
        try {
          await OpenFile.open(savePath);
        } catch (e) {
          print('Error opening file: $e');
          _showSuccess(context, 'File downloaded to Downloads folder. Please check your Downloads folder.');
        }
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        _showError(context, 'Error downloading file. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<String> _getDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Download';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      }
    } catch (e) {
      print('Error getting download path: $e');
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFile = widget.fileData != null &&
        widget.fileData!['originalname'] != null &&
        widget.fileData!['originalname'].toString().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: widget.isEditing
                ? ElevatedButton(
              onPressed: () => widget.onFilePick?.call(widget.field),
              child: const Text('Select File'),
            )
                : hasFile
                ? TextButton.icon(
              onPressed: isLoading ? null : downloadFile,
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
                    : widget.fileData!['originalname'],
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
                : const Text('No file', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}