import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/settings/widget/setting_wrapper.dart';

import '../../../logger/data/global_logs.data.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<LogEntry> parsedLogs = [];
  final FocusNode _refreshFocusNode = FocusNode();
  final FocusNode _copyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _parseLogs();
  }

  @override
  void dispose() {
    _refreshFocusNode.dispose();
    _copyFocusNode.dispose();
    super.dispose();
  }

  void _parseLogs() {
    parsedLogs = globalLogs.reversed.map((log) => LogEntry.parse(log)).toList();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: globalLogs.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logs copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          showCloseIcon: true,
        ),
      );
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: colorScheme.surface,
        title: Text(
          "Application Logs",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            focusNode: _copyFocusNode,
            onPressed: _copyToClipboard,
            icon: Icon(Icons.copy, color: colorScheme.primary),
            tooltip: 'Copy all logs',
          ),
          IconButton(
            focusNode: _refreshFocusNode,
            onPressed: () {
              setState(() {
                _parseLogs();
              });
            },
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
              const PreviousFocusIntent(),
        },
        child: SettingWrapper(
          child: parsedLogs.isEmpty
              ? Center(
                  child: Text(
                    'No logs available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: parsedLogs.length,
                  itemBuilder: (context, index) {
                    final log = parsedLogs[index];
                    return Semantics(
                      label: 'Log entry: ${log.level} from ${log.service}',
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(log.level)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _getLevelColor(log.level)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    log.level,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: _getLevelColor(log.level),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  log.service,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log.timestamp,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              log.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class LogEntry {
  final String level;
  final String service;
  final String timestamp;
  final String message;

  LogEntry({
    required this.level,
    required this.service,
    required this.timestamp,
    required this.message,
  });

  factory LogEntry.parse(String logLine) {
    final parts = logLine.split(RegExp(r'\s+'));
    if (parts.length >= 3) {
      final level = parts[0];
      final service = parts[1];
      final timestamp = parts[2];
      final message = parts.skip(3).join(' ');
      return LogEntry(
        level: level,
        service: service,
        timestamp: timestamp,
        message: message,
      );
    }
    return LogEntry(
      level: 'UNKNOWN',
      service: 'Unknown',
      timestamp: '',
      message: logLine,
    );
  }
}
