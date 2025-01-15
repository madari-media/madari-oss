import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/types/stremio.dart';
import 'package:madari_client/features/connections/service/base_connection_service.dart';
import 'package:madari_client/features/doc_viewer/container/doc_viewer.dart';

import '../../../../utils/external_player.dart';
import '../../../../utils/load_language.dart';
import '../../../doc_viewer/types/doc_source.dart';
import '../../../downloads/service/service.dart';

// Note: This is because there is some conflict between drift and this
const kIsWeb = bool.fromEnvironment('dart.library.js_util');

class RenderStreamList extends StatefulWidget {
  final BaseConnectionService service;
  final LibraryItem id;
  final bool shouldPop;
  final double? progress;

  const RenderStreamList({
    super.key,
    required this.service,
    required this.id,
    this.progress,
    required this.shouldPop,
  });

  @override
  State<RenderStreamList> createState() => _RenderStreamListState();
}

class _RenderStreamListState extends State<RenderStreamList> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadError = {};

  late StreamSubscription<TaskUpdate> _hasError;

  @override
  void initState() {
    super.initState();

    getLibrary();

    if (!kIsWeb) {
      DownloadService.instance.getAllDownloads().then((data) {
        for (var item in data) {
          _downloadProgress[item.taskId] = item.progress;

          if (item.exception?.description != null) {
            _downloadError[item.taskId] = item.exception!.description;
          }
        }

        if (mounted) {
          setState(() {});
        }
      });
    }

    if (!kIsWeb) {
      _hasError = DownloadService.instance.updates.listen((update) async {
        if (update is TaskStatusUpdate) {
          final task =
              await DownloadService.instance.getById(update.task.taskId);

          if (mounted) {
            setState(() {
              _downloadProgress[update.task.taskId] = task?.progress ?? 0;
              if (task?.exception?.description != null) {
                _downloadError[update.task.taskId] =
                    task!.exception!.description;
              }
            });
          } else {
            _hasError.cancel();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _hasError.cancel();
  }

  Widget _buildDownloadButton(BuildContext context, String url, String title) {
    final taskId = calculateHash(url);
    final progress = _downloadProgress[taskId];

    return SizedBox(
      child: progress != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                  ),
                ),
                IconButton(
                  icon: _downloadError[taskId] == null
                      ? const Icon(Icons.stop_circle)
                      : const Icon(Icons.delete),
                  onPressed: () async {
                    if (_downloadError[taskId] == null) {
                      final task =
                          await DownloadService.instance.getById(taskId);
                      await DownloadService.instance.pauseDownload(
                        task!.task as DownloadTask,
                      );
                    } else {
                      DownloadService.instance.deleteDownload(taskId);
                      setState(() {
                        _downloadProgress.remove(taskId);
                      });
                    }
                  },
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                final task = DownloadTask(
                  url: url,
                  taskId: taskId,
                  filename: "${(widget.id as Meta).name!}.mp4",
                );

                await DownloadService.instance.startDownload(task);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Download started'),
                    action: SnackBarAction(
                      label: 'View',
                      onPressed: () {
                        Navigator.pushNamed(context, '/downloads');
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool hasError = false;
  bool isLoading = true;
  List<StreamList>? _list;

  final List<Error> errors = [];

  final Map<String, StreamSource> _sources = {};

  Future getLibrary() async {
    await BaseConnectionService.getLibraries();

    await widget.service.getStreams(
      widget.id,
      callback: (items, error) {
        if (mounted) {
          setState(() {
            isLoading = false;
            _list = items;

            _list?.forEach((item) {
              if (item.streamSource != null) {
                _sources[item.streamSource!.id] = item.streamSource!;
              }
            });
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        _list = _list ?? [];
      });
    }
  }

  String? selectedAddonFilter;

  @override
  Widget build(BuildContext context) {
    if (isLoading || _list == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return const Text("Something went wrong");
    }

    if ((_list ?? []).isEmpty) {
      return Center(
        child: Text(
          "No stream found",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final filteredList = (_list ?? []).where((item) {
      if (item.streamSource == null || selectedAddonFilter == null) {
        return true;
      }

      return item.streamSource!.id == selectedAddonFilter;
    }).toList();

    return ListView.builder(
      itemBuilder: (context, index) {
        if (index == 0) {
          return SizedBox(
            height: 42,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final value in _sources.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: value.id == selectedAddonFilter,
                        label: Text(value.title),
                        onSelected: (i) {
                          setState(() {
                            selectedAddonFilter = i ? value.id : null;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        final item = filteredList[index - 1];

        return ListTile(
          title: Text(item.title),
          subtitle: item.description == null && item.streamSource == null
              ? null
              : Text(
                  "${item.description ?? ""}\n---\n${item.streamSource?.title ?? ""}"
                      .trim(),
                ),
          trailing: (item.source is MediaURLSource)
              ? _buildDownloadButton(
                  context,
                  (item.source as MediaURLSource).url,
                  item.title,
                )
              : null,
          onTap: () {
            if (widget.shouldPop) {
              Navigator.of(context).pop(item.source);

              return;
            }

            PlaybackConfig config = getPlaybackConfig();

            if (config.externalPlayer) {
              if (!kIsWeb) {
                if (item.source is URLSource || item.source is TorrentSource) {
                  if (config.externalPlayer && Platform.isAndroid) {
                    openVideoUrlInExternalPlayerAndroid(
                      videoUrl: (item.source as URLSource).url,
                      playerPackage: config.currentPlayerPackage,
                    );
                    return;
                  }
                }
              }
            }

            final meta = (widget.id as Meta).copyWith();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => DocViewer(
                  source: item.source,
                  service: widget.service,
                  meta: meta,
                  progress: widget.progress,
                ),
              ),
            );
          },
        );
      },
      itemCount: filteredList.length + 1,
    );
  }
}

String calculateHash(String url) {
  return url.hashCode.toString();
}
