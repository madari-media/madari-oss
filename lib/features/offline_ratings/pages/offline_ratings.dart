import 'package:flutter/material.dart';

import '../models/rating_model.dart' as rating_model;
import '../services/ratings_service.dart';

class OfflineRatings extends StatefulWidget {
  const OfflineRatings({super.key});

  @override
  State<OfflineRatings> createState() => _OfflineRatingsState();
}

class _OfflineRatingsState extends State<OfflineRatings> {
  final _urlController = TextEditingController();
  final _ratingsService = RatingsService();

  List<rating_model.RatingModel>? _ratings;
  double _downloadProgress = 0;
  String? _error;
  bool _isLoading = false;
  bool _isDownloadComplete = false;

  Future<void> _downloadRatings(String url) async {
    if (url.isEmpty) {
      setState(() {
        _error = 'Please enter a valid URL';
        _showSnackBar('Please enter a valid URL', isError: true);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _ratings = null;
      _isDownloadComplete = false;
    });

    try {
      final ratings = await _ratingsService.downloadAndParseRatings(
        url,
        (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      setState(() {
        _ratings = ratings;
        _isLoading = false;
        _isDownloadComplete = true;
      });

      _showSnackBar('Download completed successfully!');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    if (_ratings == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _error != null
            ? theme.colorScheme.errorContainer
            : _isDownloadComplete
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _error != null
                      ? Icons.error_outline
                      : _isDownloadComplete
                          ? Icons.check_circle
                          : Icons.info_outline,
                  color: _error != null
                      ? theme.colorScheme.error
                      : _isDownloadComplete
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error ??
                        (_isDownloadComplete ? 'Download Complete!' : 'Status'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _error != null
                          ? theme.colorScheme.error
                          : theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_ratings != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                ),
                child: Text(
                  "Ratings found ${_ratings!.length.toString()}",
                ),
              ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ratings Downloader"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Download Ratings",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Download and view title ratings offline. Data will be stored locally for quick access.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Enter TSV.GZ URL',
                        hintText: 'https://example.com/title.ratings.tsv.gz',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _downloadRatings(_urlController.text),
                        icon: Icon(_isLoading
                            ? Icons.hourglass_empty
                            : Icons.download),
                        label: Text(
                          _isLoading ? 'Downloading...' : 'Start Download',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildStatusIndicator(theme),
          ],
        ),
      ),
    );
  }
}
