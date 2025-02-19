import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/features/video_player/container/video_play.dart';
import 'package:madari_engine/madari_engine.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';

class SeasonSource extends StatefulWidget {
  final Meta meta;
  final bool isMobile;
  final OnVideoChangeCallback onVideoChange;
  final BehaviorSubject<int> updateSubject;

  const SeasonSource({
    super.key,
    required this.meta,
    required this.isMobile,
    required this.onVideoChange,
    required this.updateSubject,
  });

  @override
  State<SeasonSource> createState() => _SeasonSourceState();
}

class _SeasonSourceState extends State<SeasonSource> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialCustomButton(
      onPressed: () => onSelectMobile(context),
      icon: const Icon(Icons.list_alt),
    );
  }

  onSelectDesktop(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return VideoSelectView(
          meta: widget.meta,
          onVideoChange: widget.onVideoChange,
          updateSubject: widget.updateSubject,
        );
      },
    );
  }

  onSelectMobile(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return VideoSelectView(
          meta: widget.meta,
          onVideoChange: widget.onVideoChange,
          updateSubject: widget.updateSubject,
        );
      },
    );
  }
}

class VideoSelectView extends StatefulWidget {
  final Meta meta;
  final OnVideoChangeCallback onVideoChange;
  final BehaviorSubject<int> updateSubject;

  const VideoSelectView({
    super.key,
    required this.meta,
    required this.onVideoChange,
    required this.updateSubject,
  });

  @override
  State<VideoSelectView> createState() => _VideoSelectViewState();
}

class _VideoSelectViewState extends State<VideoSelectView> {
  final ScrollController controller = ScrollController();
  int? isLoading;

  late final videos = widget.meta.videos;

  @override
  void initState() {
    super.initState();

    videos?.sort((v1, v2) {
      if (v1.season == null && v2.season == null) return 0;
      if (v1.season == null) return 1;
      if (v2.season == null) return -1;

      final seasonComparison = v1.season!.compareTo(v2.season!);
      if (seasonComparison != 0) {
        return seasonComparison;
      }

      if (v1.number == null && v2.number == null) return 0;
      if (v1.number == null) return 1;
      if (v2.number == null) return -1;

      return v1.number!.compareTo(v2.number!);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      const itemWidth = 240.0 + 16.0;
      final offset = widget.updateSubject.value * itemWidth;

      controller.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Episodes"),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final video = videos![index];

                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () async {
                              setState(() {
                                isLoading = index;
                              });

                              final res = await widget.onVideoChange(index);

                              if (res == false) {
                                return;
                              }

                              if (context.mounted) Navigator.of(context).pop();

                              if (mounted) {
                                setState(() {
                                  isLoading = null;
                                });
                              }
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: CachedNetworkImageProvider(
                                          video.thumbnail ??
                                              widget.meta.poster ??
                                              widget.meta.background ??
                                              "",
                                        ),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: 240,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black,
                                                  Colors.black54,
                                                  Colors.black38,
                                                ],
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "S${video.season} E${video.episode}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                  ),
                                                  Text(
                                                    video.name ??
                                                        video.title ??
                                                        "",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.updateSubject.value == index)
                                  Positioned(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black,
                                            Colors.black54,
                                            Colors.black38,
                                          ],
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Text("Playing"),
                                            Icon(Icons.play_arrow),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (index == isLoading)
                          const Positioned.fill(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    );
                  },
                  itemCount: (widget.meta.videos ?? []).length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
