import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/global_logs.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<LogEntry> parsedLogs = [];

  @override
  void initState() {
    super.initState();
    _parseLogs();
  }

  void _parseLogs() {
    parsedLogs = globalLogs.reversed.map((log) => LogEntry.parse(log)).toList();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: globalLogs.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Application Logs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all logs',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _parseLogs();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: parsedLogs.isEmpty
          ? const Center(
              child: Text(
                'No logs available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: parsedLogs.length,
              itemBuilder: (context, index) {
                final log = parsedLogs[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLevelColor(log.level).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color:
                                    _getLevelColor(log.level).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              log.level,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getLevelColor(log.level),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${log.service} • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            log.timestamp,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        log.message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              },
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
