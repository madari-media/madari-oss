import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';

class StremioVideoList extends StatelessWidget {
  final List<Video>? videos;
  final Meta meta;

  const StremioVideoList({
    super.key,
    this.videos,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Videos",
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.left,
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final video = videos![index];

            return ListTile(
              leading: const Icon(Icons.play_arrow),
              onTap: () {
                context.push(
                  "/player/${meta.type}/${meta.id}/${Uri.encodeComponent(video.streams!.first.url!)}",
                  extra: {
                    "meta": meta.copyWith(
                      selectedVideoIndex: index,
                    ),
                  },
                );
              },
              title: Text("${video.title}"),
              subtitle: Text(
                "Released	${video.released.toString().split(' ')[0]}",
              ),
            );
          },
          shrinkWrap: true,
          itemCount: videos?.length ?? 0,
        ),
      ],
    );
  }
}
