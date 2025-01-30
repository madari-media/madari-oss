import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  static DownloadService get instance => _instance;

  final StreamController<List<TaskRecord>> _recordsController =
      StreamController<List<TaskRecord>>.broadcast();
  Stream<List<TaskRecord>> get records => _recordsController.stream;

  final Map<String, DownloadTask> _tasks = {};

  DownloadService._internal() {
    _init();
  }

  Future<void> _init() async {
    await FileDownloader().trackTasks();

    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading', 'File: {filename}'),
      complete: const TaskNotification('Download Complete', 'File: {filename}'),
      error: const TaskNotification('Download Failed', 'File: {filename}'),
      progressBar: true,
    );

    FileDownloader().updates.listen((update) async {
      await _updateRecords();
    });
  }

  Future<void> _updateRecords() async {
    final records = await FileDownloader().database.allRecords();
    _recordsController.add(records);
  }

  Future<bool> startDownload(String url, String filename) async {
    final task = DownloadTask(
      url: url,
      filename: filename,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
    );

    _tasks[task.taskId] = task;
    final success = await FileDownloader().enqueue(task);
    await _updateRecords();
    return success;
  }

  Future<void> pauseDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await FileDownloader().pause(task);
      await _updateRecords();
    }
  }

  Future<void> resumeDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await FileDownloader().resume(task);
      await _updateRecords();
    }
  }

  Future<void> cancelDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task != null) {
      await FileDownloader().cancelTaskWithId(taskId);
      _tasks.remove(taskId);
      await _updateRecords();
    }
  }

  Future<void> dispose() async {
    await _recordsController.close();
  }
}
