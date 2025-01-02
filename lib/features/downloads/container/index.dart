import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class DownloadDialog extends StatefulWidget {
  const DownloadDialog({super.key});

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isValidating = false;
  String? _validationError;
  Map<String, dynamic>? _fileInfo;

  Future<void> _startDownload() async {
    if (!_formKey.currentState!.validate()) return;

    final task = DownloadTask(
      url: _urlController.text,
      filename: '${_nameController.text}.mp4',
      directory: 'downloads',
      updates: Updates.statusAndProgress,
      allowPause: true,
      displayName: _nameController.text,
    );

    await FileDownloader().enqueue(task);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _validateUrl() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationError = null;
      _fileInfo = null;
    });

    try {
      final uri = Uri.parse(_urlController.text);
      if (!await canLaunchUrl(uri)) {
        throw Exception('Invalid URL');
      }

      // Make a HEAD request to get file information
      final response = await http.head(uri);

      if (response.statusCode != 200) {
        throw Exception('Could not access file');
      }

      // Get file size from headers
      final contentLength = response.headers['content-length'];
      final fileSize = contentLength != null
          ? _formatFileSize(int.parse(contentLength))
          : 'Unknown size';

      // Get content type from headers
      final contentType = response.headers['content-type'] ?? 'Unknown type';

      // Extract filename from URL or Content-Disposition header
      String fileName = '';
      final disposition = response.headers['content-disposition'];
      if (disposition != null && disposition.contains('filename=')) {
        fileName = disposition.split('filename=')[1].replaceAll('"', '');
      } else {
        fileName = path.basename(uri.path);
      }

      // Remove extension from filename for display name
      _nameController.text = path.basenameWithoutExtension(fileName);

      _fileInfo = {
        'size': fileSize,
        'type': contentType,
        'filename': fileName,
      };
    } catch (e) {
      _validationError = 'Invalid URL: ${e.toString()}';
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width < 600 ? double.infinity : 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 30,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add New Download',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // URL Input Field
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'URL',
                  hintText: 'Paste your download URL here',
                  filled: true,
                  prefixIcon: const Icon(Icons.link, color: Colors.grey),
                  suffixIcon: _isValidating
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          onPressed: _validateUrl,
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  return null;
                },
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() => _fileInfo = null),
              ),

              // Validation Error
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _validationError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              // File Information
              if (_fileInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.folder_outlined, 'File Size:',
                          _fileInfo?['size'] ?? ''),
                      const SizedBox(height: 12),
                      _infoRow(Icons.description_outlined, 'Type:',
                          _fileInfo?['type'] ?? ''),
                      const SizedBox(height: 12),
                      _infoRow(Icons.insert_drive_file_outlined, 'File:',
                          _fileInfo?['filename'] ?? ''),
                    ],
                  ),
                ),

                // Display Name Input
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'Enter a name for this download',
                    filled: true,
                    prefixIcon: Icon(Icons.edit, color: Colors.grey),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              ],

              // Action Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _fileInfo != null ? _startDownload : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey[700],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
