import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:madari_client/features/connections/service/stremio_connection_service.dart';
import 'package:madari_client/utils/load_language.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shimmer/shimmer.dart';

import '../../../connections/service/base_connection_service.dart';
import '../../../connections/types/stremio/stremio_base.types.dart';

Map<String, List<Subtitle>> externalSubtitlesCache = {};

class SubtitleSelector extends StatefulWidget {
  final Player player;
  final PlaybackConfig config;
  final BaseConnectionService? service;
  final LibraryItem? meta;

  const SubtitleSelector({
    super.key,
    required this.player,
    required this.config,
    required this.service,
    this.meta,
  });

  @override
  State<SubtitleSelector> createState() => _SubtitleSelectorState();
}

class _SubtitleSelectorState extends State<SubtitleSelector> {
  List<SubtitleTrack> subtitles = [];
  Map<String, String> languages = {};
  Stream<List<Subtitle>>? externalSubtitles;

  late StreamSubscription<List<String>> _subtitles;

  @override
  void initState() {
    super.initState();

    if (widget.service is StremioConnectionService && widget.meta is Meta) {
      final meta = widget.meta as Meta;

      if (externalSubtitlesCache.containsKey(meta.id)) {
        externalSubtitles = Stream.value(externalSubtitlesCache[meta.id]!);
      } else {
        externalSubtitles = (widget.service as StremioConnectionService)
            .getSubtitles(meta)
            .map((item) {
          externalSubtitlesCache[meta.id] = item;

          return item;
        });
      }
    }

    onPlaybackReady(widget.player.state.tracks);
    _subtitles = widget.player.stream.subtitle.listen((item) {
      onPlaybackReady(widget.player.state.tracks);
    });

    loadLanguages(context).then((language) {
      if (mounted) {
        setState(() {
          languages = language;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _subtitles.cancel();
  }

  void onPlaybackReady(Tracks tracks) {
    setState(() {
      subtitles = tracks.subtitle.where((item) {
        return item.id != "auto" && item.id != "no";
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 520,
      ),
      child: Card(
        child: Container(
          height: max(MediaQuery.of(context).size.height * 0.4, 400),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Select Subtitle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Subtitle>>(
                  stream: externalSubtitles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Shimmer.fromColors(
                        baseColor: Colors.black54,
                        highlightColor: Colors.black54,
                        child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Container(
                                height: 20,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView.builder(
                        itemCount: subtitles.length,
                        itemBuilder: (context, index) {
                          final currentItem = subtitles[index];
                          final title = currentItem.language ??
                              currentItem.title ??
                              currentItem.id;

                          return ListTile(
                            title: Text(
                              languages.containsKey(title)
                                  ? languages[title]!
                                  : title,
                            ),
                            selected: widget.player.state.track.subtitle.id ==
                                currentItem.id,
                            onTap: () {
                              widget.player.setSubtitleTrack(currentItem);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    } else {
                      final externalSubtitlesList = snapshot.data!;
                      final allSubtitles = [
                        SubtitleTrack.no(),
                        ...subtitles,
                        ...externalSubtitlesList.map(
                          (subtitle) {
                            return SubtitleTrack.uri(
                              subtitle.url,
                              language: subtitle.lang,
                              title:
                                  "${languages[subtitle.lang] ?? subtitle.lang} ${subtitle.id}",
                            );
                          },
                        ),
                      ];

                      return ListView.builder(
                        itemCount: allSubtitles.length,
                        itemBuilder: (context, index) {
                          final currentItem = allSubtitles[index];
                          final title = currentItem.language ??
                              currentItem.title ??
                              currentItem.id;

                          final isExternal = currentItem.uri;

                          return ListTile(
                            title: Text(
                              "${languages.containsKey(title) ? languages[title]! : title == "no" ? "No subtitle" : title} ${isExternal ? "(External) (${Uri.parse(currentItem.id).host})" : ""}",
                            ),
                            selected: widget.player.state.track.subtitle.id ==
                                currentItem.id,
                            onTap: () async {
                              await widget.player.setSubtitleTrack(currentItem);
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
