import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';
import 'package:madari_client/features/doc_viewer/types/doc_source.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../connection/services/stremio_service.dart';
import '../../downloads/service/service.dart';

class StremioStreamSelector extends StatefulWidget {
  final StremioService stremio;
  final Meta item;
  final String? episode;
  final String? season;
  final String id;
  final Widget? library;

  const StremioStreamSelector({
    super.key,
    required this.id,
    required this.stremio,
    required this.item,
    this.episode,
    this.season,
    this.library,
  });

  @override
  State<StremioStreamSelector> createState() => _StremioStreamSelectorState();
}

class _StremioStreamSelectorState extends State<StremioStreamSelector> {
  late final Stream<List<VideoStream>> _stream;
  final Map<int, TaskStatus> _downloadStatus = {};
  final Map<int, double> _downloadProgress = {};
  DownloadService? _downloadService;
  StreamSubscription? _downloadSubscription;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) _downloadService = DownloadService.instance;

    _stream = widget.stremio.getStreams(
      widget.item.type,
      widget.id,
      episode: widget.episode,
      season: widget.season,
    );

    _setupDownloadListener();
    _checkExistingDownloads();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  void _setupDownloadListener() {
    _downloadSubscription = _downloadService?.updates.listen((update) {
      if (!mounted) return;

      switch (update) {
        case TaskStatusUpdate():
          final index = int.tryParse(update.task.taskId.split('_').last);
          if (index != null) {
            setState(() {
              _downloadStatus[index] = update.status;
            });
          }

        case TaskProgressUpdate():
          final index = int.tryParse(update.task.taskId.split('_').last);
          if (index != null) {
            setState(() {
              _downloadProgress[index] = update.progress;
            });
          }
      }
    });
  }

  Future<void> _checkExistingDownloads() async {
    final downloads = await _downloadService?.getAllDownloads();
    if (!mounted) return;

    setState(() {
      for (var record in (downloads ?? [])) {
        final index = int.tryParse(record.task.taskId.split('_').last);
        if (index != null) {
          _downloadStatus[index] = record.status;
          _downloadProgress[index] = record.progress;
        }
      }
    });
  }

  String _getFileName(VideoStream item) {
    return item.behaviorHints?["filename"] ?? "${widget.item.name}.mp4";
  }

  Future<void> _startDownload(VideoStream item, int index) async {
    final fileName = _getFileName(item);
    final url = item.url;

    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No URL available for download')),
        );
      }
      return;
    }

    final task = DownloadTask(
      taskId: 'download_$index',
      url: url,
      displayName: fileName.split("/").last,
      filename: fileName.split("/").last,
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );

    try {
      await _downloadService?.startDownload(task);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Widget _buildDownloadButton(VideoStream item, int index) {
    if (isWeb) {
      return const SizedBox(
        width: 1,
        height: 1,
      );
    }

    final status = _downloadStatus[index];
    final progress = _downloadProgress[index] ?? 0.0;

    switch (status) {
      case TaskStatus.complete:
        return IconButton(
          icon: const Icon(Icons.play_circle, color: Colors.green),
          onPressed: () => _playDownloadedFile(item),
        );

      case TaskStatus.running:
        return Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: progress),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _downloadService?.pauseDownload(
                DownloadTask(
                  taskId: 'download_$index',
                  url: item.url!,
                  filename: _getFileName(item),
                ),
              ),
            ),
          ],
        );

      case TaskStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => _downloadService?.resumeDownload(
            DownloadTask(
              taskId: 'download_$index',
              url: item.url!,
              filename: _getFileName(item),
            ),
          ),
        );

      default:
        return IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _startDownload(item, index),
        );
    }
  }

  Future<void> _playDownloadedFile(VideoStream item) async {}

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong: ${snapshot.error}");
        }

        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return const Center(
            child: Text("No streams available"),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data?.isEmpty == true) {
          return const Center(
            child: Text("No streams available"),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, index) {
            final item = snapshot.data![index];

            return ListTile(
              onTap: () {
                DocSource? source;

                if ((item.behaviorHints)?.containsKey("iframe") == true) {
                  final url =
                      (item.behaviorHints!["iframe"] as String).replaceAll(
                    "{imdb}",
                    widget.item.imdbId!,
                  );

                  source = IframeSource(
                    url: url,
                    title: widget.item.name!,
                    id: widget.item.id,
                    season: widget.season,
                    episode: widget.episode,
                  );
                }

                if (item.infoHash != null) {
                  source = TorrentSource(
                    id: widget.item.id,
                    title: widget.item.name!,
                    infoHash: item.infoHash!,
                    fileName:
                        "${item.behaviorHints?["filename"] as String}.mp4",
                    season: widget.season,
                    episode: widget.episode,
                  );
                }

                if (item.url != null) {
                  source = URLSource(
                    title: "${utf8.decode(
                      widget.item.name!.runes.toList(),
                    )}.mp4",
                    url: item.url!,
                    id: widget.item.id,
                    fileName: "${_getFileName(item)}.mp4",
                    season: widget.season,
                    episode: widget.episode,
                  );
                }

                if (source == null) {
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) {
                    return DocViewer(
                      source: source!,
                    );
                  }),
                );
              },
              enabled: item.behaviorHints?["filename"] != null,
              leading: const Icon(Icons.stream),
              title: Text(
                utf8.decode((item.name ?? item.title ?? "").runes.toList()),
              ),
              subtitle: Text(
                utf8.decode(
                    (item.description ?? item.title ?? '').runes.toList()),
              ),
              trailing: _buildDownloadButton(item, index),
            );
          },
        );
      },
    );
  }
}
