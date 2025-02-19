import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madari_engine/madari_engine.dart';

typedef ImageCallback = Function(String? image);

class StremioCard extends StatefulWidget {
  final Meta item;
  final String prefix;
  final ImageCallback onTap;
  final FocusNode focusNode;
  final bool isWide;

  const StremioCard({
    super.key,
    required this.item,
    required this.prefix,
    required this.onTap,
    required this.focusNode,
    this.isWide = false,
  });

  @override
  State<StremioCard> createState() => _StremioCardState();
}

class _StremioCardState extends State<StremioCard> {
  @override
  Widget build(BuildContext context) {
    final meta = widget.item;

    return Focus(
      focusNode: widget.focusNode,
      child: Builder(builder: (context) {
        final isFocused = Focus.of(context).hasPrimaryFocus;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 10,
                  )
                : null,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.onTap(""),
                child: !widget.isWide
                    ? _buildRegular(context, meta)
                    : _buildWideCard(context, meta),
              ),
            ),
          ),
        );
      }),
    );
  }

  _buildWideCard(BuildContext context, Meta meta) {
    return WideCardStremio(meta: meta);
  }

  String? getBackgroundImage(Meta meta) {
    String? backgroundImage;

    if (meta.currentVideo != null) {
      return meta.currentVideo?.thumbnail ?? meta.poster;
    }

    if (meta.poster != null) {
      backgroundImage = meta.poster;
    }

    return backgroundImage;
  }

  _buildRegular(BuildContext context, Meta meta) {
    final backgroundImage =
        meta.poster ?? meta.logo ?? getBackgroundImage(meta);

    return SizedBox(
      height: 100,
      width: 200,
      child: Hero(
        tag: "${widget.prefix}${meta.type}${widget.item.id}",
        child: (backgroundImage == null)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 26,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.grey,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          meta.name ?? "No title",
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(backgroundImage)}@webp",
                            imageRenderMethodForWeb:
                                ImageRenderMethodForWeb.HttpGet,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: meta.imdbRating != ""
                          ? Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        meta.imdbRating,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  if (meta.progress != null)
                    const Positioned.fill(
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(
                          Icons.play_arrow,
                          size: 24,
                        ),
                      ),
                    ),
                  if (meta.progress != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: meta.progress! / 100,
                        minHeight: 5,
                      ),
                    ),
                  if (meta.currentVideo != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                meta.name ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "S${meta.currentVideo?.season} E${meta.currentVideo?.episode}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
      ),
    );
  }
}

class WideCardStremio extends StatefulWidget {
  final Meta meta;
  final Video? video;

  const WideCardStremio({
    super.key,
    required this.meta,
    this.video,
  });

  @override
  State<WideCardStremio> createState() => _WideCardStremioState();
}

class _WideCardStremioState extends State<WideCardStremio> {
  bool hasErrorWhileLoading = false;

  bool get isInFuture {
    final video = widget.video ?? widget.meta.currentVideo;
    return video != null &&
        video.firstAired != null &&
        video.firstAired!.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meta.background == null) {
      return Container();
    }

    final video = widget.video ?? widget.meta.currentVideo;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            "https://proxy-image.syncws.com/insecure/plain/${Uri.encodeQueryComponent(
              hasErrorWhileLoading
                  ? widget.meta.background!
                  : (widget.meta.currentVideo?.thumbnail ??
                      widget.meta.background!),
            )}@webp",
            errorListener: (error) {
              setState(() {
                hasErrorWhileLoading = true;
              });
            },
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (isInFuture)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.black54,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "${widget.meta.name}",
                    style: video != null
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  if (video != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "S${video.season} E${video.episode}",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black,
                            ),
                      ),
                    ),
                  if (video != null)
                    Text(
                      "${video?.name ?? video?.title}".trim(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                ],
              ),
            ),
          ),
          if (isInFuture)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                getRelativeDate(video!.firstAired!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          if (isInFuture)
            const Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Icon(
                        Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Positioned(
            child: Center(
              child: IconButton.filled(
                onPressed: null,
                icon: Icon(
                  Icons.play_arrow,
                  size: 24,
                ),
              ),
            ),
          ),
          widget.meta.imdbRating != "" && widget.video == null
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.meta.imdbRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

String getRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);

  final difference = date.difference(today).inDays;

  if (date.isAtSameMomentAs(today)) {
    return "It's today!";
  } else if (date.isAtSameMomentAs(tomorrow)) {
    return "Coming up tomorrow!";
  } else if (difference > 1 && difference < 7) {
    return "Coming up in $difference days";
  } else if (difference >= 7 && difference < 14) {
    return "Coming up next ${DateFormat('EEEE').format(date)}";
  } else {
    return "On ${DateFormat('MM/dd/yyyy').format(date)}";
  }
}
