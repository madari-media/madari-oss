import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../connections/types/stremio/stremio_base.types.dart';

class SeasonSource extends StatelessWidget {
  final Meta meta;
  final bool isMobile;
  final Player player;
  final Function(int index) onVideoChange;

  const SeasonSource({
    super.key,
    required this.meta,
    required this.isMobile,
    required this.player,
    required this.onVideoChange,
  });

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
          meta: meta,
          onVideoChange: onVideoChange,
        );
      },
    );
  }

  onSelectMobile(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return VideoSelectView(
          meta: meta,
          onVideoChange: onVideoChange,
        );
      },
    );
  }
}

class VideoSelectView extends StatefulWidget {
  final Meta meta;
  final Function(int index) onVideoChange;

  const VideoSelectView({
    super.key,
    required this.meta,
    required this.onVideoChange,
  });

  @override
  State<VideoSelectView> createState() => _VideoSelectViewState();
}

class _VideoSelectViewState extends State<VideoSelectView> {
  final ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();

    if (widget.meta.selectedVideoIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const itemWidth = 240.0 + 16.0;
        final offset = widget.meta.selectedVideoIndex! * itemWidth;

        controller.jumpTo(offset);
      });
    }
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
        backgroundColor: Colors.black38,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Episodes"),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 150,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final video = widget.meta.videos![index];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          widget.onVideoChange(index);
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
                                            ""),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 240,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
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
                                          padding: const EdgeInsets.all(8.0),
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
                                                video.name ?? video.title ?? "",
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
                            if (widget.meta.selectedVideoIndex == index)
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
