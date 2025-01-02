import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/utils/ocr_file.dart';

import '../service/service.dart';

class AddCollectionItemSheet extends StatefulWidget {
  final String listId;

  const AddCollectionItemSheet({
    super.key,
    required this.listId,
  });

  @override
  State<AddCollectionItemSheet> createState() => _AddCollectionItemSheetState();
}

class _AddCollectionItemSheetState extends State<AddCollectionItemSheet>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  late TabController _tabController;
  PlatformFile? _selectedFile;
  String? _fileType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single;
          _fileType = result.files.single.extension;
          _titleController.text = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  bool _isLoading = false;

  Future<void> _saveItem() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await CollectionService.addItem(
        listId: widget.listId,
        name: _titleController.text,
        type: "file",
        file: _selectedFile!,
        content: (await ocrFiles([_selectedFile!])).first,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: _isLoading ? const Text("Uploading...") : const Text("Upload"),
        icon: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(),
              )
            : const Icon(Icons.upload_file),
        onPressed: _isLoading ? null : _saveItem,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFileUploadTab(),
        ],
      ),
    );
  }

  Widget _buildFileUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedFile != null)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 24),
          _selectedFile == null
              ? Center(
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.add),
                        label: const Text('Select File'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Supported formats: PDF, JPG, PNG',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _fileType == 'pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile!.path?.split('/').last ?? "",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _selectedFile = null;
                                _fileType = null;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'File type: ${_fileType?.toUpperCase()}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
