import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';

import '../features/downloads/container/index.dart';
import '../features/downloads/service/service.dart';

class DownloadPage extends StatefulWidget {
  static String get routeName => "/downloads";

  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  List<TaskRecord> _downloads = [];
  bool _isLoading = true;
  final _downloadService = DownloadService.instance;

  StreamSubscription<TaskUpdate>? _cancel;

  @override
  void initState() {
    super.initState();
    _initializeDownloader();
  }

  @override
  dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _initializeDownloader() async {
    _cancel = _downloadService.updates.listen((update) {
      _handleTaskUpdate(update);
    });

    await _refreshDownloads();
  }

  void _handleTaskUpdate(TaskUpdate update) async {
    final index = _downloads.indexWhere((record) =>
        record.task is DownloadTask &&
        (record.task as DownloadTask).taskId == update.task.taskId);

    if (index != -1) {
      _refreshDownloads();
    }
  }

  Future<void> _refreshDownloads() async {
    final records = await _downloadService.getAllDownloads();
    setState(() {
      _downloads = records;
      _isLoading = false;
    });
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => const DownloadDialog(),
    ).then((_) => _refreshDownloads());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDownloadDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Download',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : Column(
              children: [
                const SizedBox(
                  height: 24,
                ),
                Expanded(
                  child: _downloads.isEmpty
                      ? _buildEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: ListView.builder(
                                  itemCount: _downloads.length,
                                  itemBuilder: (context, index) {
                                    return DownloadItem(
                                      item: _downloads[index],
                                      refreshDownloads: _refreshDownloads,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done_outlined, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadItem extends StatefulWidget {
  final TaskRecord item;
  final VoidCallback refreshDownloads;

  const DownloadItem({
    super.key,
    required this.item,
    required this.refreshDownloads,
  });

  @override
  State<DownloadItem> createState() => _DownloadItemState();
}

class _DownloadItemState extends State<DownloadItem> {
  final _downloadService = DownloadService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildDownloadItem(widget.item);
  }

  Widget _buildDownloadItem(TaskRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final path = await record.task.filePath();

                if (context.mounted && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => DocViewer(
                        source: FileSource(
                          title: record.task.filename,
                          filePath: path,
                          id: record.taskId,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.movie_outlined,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.task.displayName == ""
                                    ? record.task.filename
                                    : record.task.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Animated status text
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: _getStatusColor(record.status),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                child: Text(
                                  _getStatusText(record),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDownloadControls(record),
                      ],
                    ),
                    // Animated progress indicator
                    if (record.status != TaskStatus.complete)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(top: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: record.progress,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(record.status),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadControls(TaskRecord record) {
    if (record.status == TaskStatus.running) {
      return IconButton(
        icon: const Icon(Icons.pause, color: Colors.white),
        onPressed: () =>
            _downloadService.pauseDownload(record.task as DownloadTask),
      );
    } else if (record.status == TaskStatus.paused) {
      return IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        onPressed: () =>
            _downloadService.resumeDownload(record.task as DownloadTask),
      );
    }
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.white),
      onPressed: () async {
        await _downloadService.deleteDownload(record.taskId);
        widget.refreshDownloads();
      },
    );
  }

  String _getStatusText(TaskRecord record) {
    final expectedSize = record.expectedFileSize;

    try {
      final downloadedSize = record.progress * expectedSize;
      final sizeText =
          '${_formatSize(downloadedSize)} / ${_formatSize(expectedSize.toDouble())}';

      switch (record.status) {
        case TaskStatus.running:
          return 'Downloading... ${(record.progress * 100).toStringAsFixed(1)}%';
        case TaskStatus.complete:
          return 'Downloaded';
        case TaskStatus.paused:
          return 'Paused';
        case TaskStatus.failed:
          return 'Failed (${(record.exception)?.description})';
        default:
          return '${record.status} ($sizeText)';
      }
    } catch (e) {
      return '${record.status} ${(record.progress * 100).toStringAsFixed(1)}%';
    }
  }
}

// Add these helper methods
Color _getStatusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.running:
      return Colors.blue;
    case TaskStatus.paused:
      return Colors.orange;
    case TaskStatus.complete:
      return Colors.green;
    case TaskStatus.failed:
      return Colors.red;
    default:
      return Colors.grey.shade400;
  }
}

Color _getProgressColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.running:
      return Colors.blue;
    case TaskStatus.paused:
      return Colors.orange;
    default:
      return Colors.red;
  }
}

String _formatSize(double bytes) {
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(2)} MB';
}
