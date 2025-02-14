// file_field_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';

class FileFieldWidget extends StatelessWidget {
  final String label;
  final String field;
  final Map<String, dynamic>? fileData;
  final bool isEditing;
  final bool isLoading;
  final File? selectedFile;
  final Function(String field) onFilePick;
  final Function(String id, String field, Map<String, dynamic> fileData) onDownload;

  const FileFieldWidget({
    Key? key,
    required this.label,
    required this.field,
    required this.fileData,
    required this.isEditing,
    required this.isLoading,
    required this.selectedFile,
    required this.onFilePick,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isEditing
                ? Row(
              children: [
                ElevatedButton(
                  onPressed: () => onFilePick(field),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    selectedFile != null ? 'Change File' : 'Select File',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      selectedFile!.path.split('/').last,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            )
                : fileData != null && fileData!['filepath'] != null
                ? TextButton.icon(
              onPressed: isLoading
                  ? null
                  : () => onDownload(
                fileData!['id'] ?? '',
                field,
                fileData!,
              ),
              icon: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue,
                  ),
                ),
              )
                  : const Icon(Icons.file_download, color: Colors.blue),
              label: Text(
                isLoading
                    ? 'Downloading...'
                    : fileData!['originalname'] ?? 'Download',
                style: TextStyle(
                  color: isLoading ? Colors.grey : Colors.blue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: Colors.grey[100],
              ),
            )
                : const Text(
              'No file',
              style: TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}