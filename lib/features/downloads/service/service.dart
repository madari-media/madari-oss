import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  static DownloadService get instance => _instance;

  final FileDownloader _downloader = FileDownloader();
  final _updateController = StreamController<TaskUpdate>.broadcast();

  Stream<TaskUpdate> get updates => _updateController.stream;
  StreamSubscription? _downloadSubscription;

  DownloadService._internal();

  Future<void> initialize() async {
    await _downloader.trackTasks();

    // Subscribe to FileDownloader updates and broadcast them
    _downloadSubscription = _downloader.updates.listen(
      (update) => _updateController.add(update),
      onError: (error) => _updateController.addError(error),
    );

    FileDownloader().configureNotification(
      running: const TaskNotification('Downloading', 'File: {filename}'),
      complete: const TaskNotification('Download finished', 'File: {filename}'),
      progressBar: true,
    );
  }

  void dispose() {
    _downloadSubscription?.cancel();
    _updateController.close();
  }

  Future<List<TaskRecord>> getAllDownloads() async {
    return await _downloader.database.allRecords();
  }

  Future<TaskRecord?> getById(String taskId) async {
    return await _downloader.database.recordForId(taskId);
  }

  Future<void> pauseDownload(DownloadTask task) async {
    await _downloader.pause(task);
  }

  Future<void> resumeDownload(DownloadTask task) async {
    await _downloader.resume(task);
  }

  Future<void> deleteDownload(String taskId) async {
    await _downloader.database.deleteRecordWithId(taskId);
  }

  Future<void> startDownload(DownloadTask task) async {
    const permissionType = PermissionType.notifications;
    var status = await FileDownloader().permissions.status(permissionType);
    if (status != PermissionStatus.granted) {
      if (await FileDownloader()
          .permissions
          .shouldShowRationale(permissionType)) {}
      status = await FileDownloader().permissions.request(permissionType);
      debugPrint('Permission for $permissionType was $status');
    }

    await _downloader.enqueue(task);
  }
}
