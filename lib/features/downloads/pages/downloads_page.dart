import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

import '../service/download_service.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _urlController = TextEditingController();
  final _filenameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _urlController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await DownloadService.instance.startDownload(
        _urlController.text,
        _filenameController.text,
      );

      if (mounted) {
        _urlController.clear();
        _filenameController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads"),
      ),
      body: Center(
        child: const Text("Not implemented") ??
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'URL is required';
                            if (!(Uri.tryParse(value!)?.hasAbsolutePath ??
                                true)) {
                              return 'Invalid URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _filenameController,
                          decoration: const InputDecoration(
                            labelText: 'Filename',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true)
                              return 'Filename is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _startDownload,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(),
                                  )
                                : const Text('Start Download'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  StreamBuilder<List<TaskRecord>>(
                    stream: DownloadService.instance.records,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final records = snapshot.data!;
                      if (records.isEmpty) {
                        return Center(
                          child: Text(
                            'No downloads yet',
                            style: theme.textTheme.bodyLarge,
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final progress =
                              (record.progress * 100).toStringAsFixed(1);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(record.task.filename),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (record.status == TaskStatus.running)
                                    LinearProgressIndicator(
                                        value: record.progress),
                                  const SizedBox(height: 4),
                                  Text('Status: ${record.status.name}'),
                                  if (record.status == TaskStatus.running)
                                    Text('Progress: $progress%'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (record.status == TaskStatus.running) ...[
                                    IconButton(
                                      icon: const Icon(Icons.pause),
                                      onPressed: () => DownloadService.instance
                                          .pauseDownload(record.taskId),
                                    ),
                                  ] else if (record.status ==
                                      TaskStatus.paused) ...[
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () => DownloadService.instance
                                          .resumeDownload(record.taskId),
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => DownloadService.instance
                                        .cancelDownload(record.taskId),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
