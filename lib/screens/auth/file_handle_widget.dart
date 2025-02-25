// file_field_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class FileFieldWidget extends StatefulWidget {
  final String label;
  final String field;
  final Map<String, dynamic>? fileData;
  final bool isEditing;
  final Map<String, File?> selectedFiles;  // Changed to nullable File
  final Function(String) onPickFile;
  final Function(String, String, Map<String, dynamic>) onDownload;

  const FileFieldWidget({
    Key? key,
    required this.label,
    required this.field,
    required this.fileData,
    required this.isEditing,
    required this.selectedFiles,
    required this.onPickFile,
    required this.onDownload,
  }) : super(key: key);

  @override
  State<FileFieldWidget> createState() => _FileFieldWidgetState();
}

class _FileFieldWidgetState extends State<FileFieldWidget> {
  bool isDownloading = false;

  Future<void> _handleDownload() async {
    setState(() {
      isDownloading = true;
    });

    try {
      await widget.onDownload(
          widget.field,
          widget.fileData!['filepath'],
          widget.fileData!
      );
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
          Expanded(
            child: widget.isEditing
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => widget.onPickFile(widget.field),
                  child: Text(
                      widget.selectedFiles[widget.field] != null
                          ? 'Change File'
                          : 'Select File'
                  ),
                ),
                if (widget.selectedFiles[widget.field] != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: Text(
                      path.basename(widget.selectedFiles[widget.field]!.path),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            )
                : widget.fileData != null && widget.fileData!['filepath'] != null
                ? TextButton.icon(
              onPressed: isDownloading
                  ? null
                  : _handleDownload,
              icon: isDownloading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.file_download),
              label: Text(
                isDownloading
                    ? 'Downloading...'
                    : widget.fileData!['originalname'] ?? 'Download',
                softWrap: true,
              ),
            )
                : const Text(
                'No file',
                style: TextStyle(color: Colors.red)
            ),
          ),
        ],
      ),
    );
  }
}
