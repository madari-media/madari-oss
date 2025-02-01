import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/external_player/service/external_player.dart';
import 'package:madari_client/features/settings/service/playback_setting_service.dart';
import 'package:madari_client/features/streamio_addons/extension/query_extension.dart';

import '../../../../streamio_addons/models/stremio_base_types.dart';
import '../../../../streamio_addons/service/stremio_addon_service.dart';

final _logger = Logger('StreamioStreamList');

class StreamioStreamList extends StatefulWidget {
  final Meta meta;

  const StreamioStreamList({
    super.key,
    required this.meta,
  });

  @override
  State<StreamioStreamList> createState() => _StreamioStreamListState();
}

class _StreamioStreamListState extends State<StreamioStreamList> {
  final service = StremioAddonService.instance;
  final List<StreamWithAddon> streams = [];

  int streamSupportedAddonCount = 0;

  bool _isLoading = true;
  Set<String> _selectedResolutions = {};
  Set<String> _selectedQualities = {};
  Set<String> _selectedCodecs = {};
  Set<String> _selectedAudios = {};
  Set<String> _selectedSizes = {};
  final Set<String> _selectedAddons = {};

  Set<String> _resolutions = {};
  Set<String> _qualities = {};
  Set<String> _codecs = {};
  Set<String> _audios = {};
  Set<String> _sizes = {};
  final Set<String> _addons = {};

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  void _loadStreams() async {
    _logger.info('Loading streams for ${widget.meta.id}');

    final addons = service.getInstalledAddons();

    final result = await addons.queryFn();

    final count = result
        .where((res) {
          for (final item in (res.resources ?? [])) {
            if (item.name == "stream") {
              return true;
            }
          }

          return false;
        })
        .toList()
        .length;

    int left = count;

    setState(() {
      streamSupportedAddonCount = count;
    });

    if (left == 0) {
      setState(() {
        _isLoading = false;
      });
    }

    service.getStreams(
      widget.meta,
      callback: (items, addonName, error) {
        setState(() {
          left -= 1;

          if (left <= 0) {
            _isLoading = false;
          }
        });

        if (error != null) {
          _logger.severe('Error loading streams: $error');
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        if (items != null) {
          final Set<String> resSet = {};
          final Set<String> qualSet = {};
          final Set<String> codecSet = {};
          final Set<String> audioSet = {};
          final Set<String> sizeSet = {};

          final streamsWithAddon = items
              .map(
                (stream) => StreamWithAddon(
                  stream: stream,
                  addonName: addonName,
                ),
              )
              .toList();

          for (var streamData in streamsWithAddon) {
            if (streamData.stream.name != null) {
              try {
                final info =
                    StreamParser.parseStreamName(streamData.stream.name!);
                if (info.resolution != null) resSet.add(info.resolution!);
                if (info.quality != null) qualSet.add(info.quality!);
                if (info.codec != null) codecSet.add(info.codec!);
                if (info.audio != null) audioSet.add(info.audio!);
                if (info.size != null) {
                  sizeSet.add(StreamParser.getSizeCategory(info.size));
                }
              } catch (e) {
                _logger.warning(
                    'Error parsing stream name: ${streamData.stream.name}', e);
              }
            }
          }

          if (mounted) {
            setState(() {
              streams.addAll(streamsWithAddon);
              if (addonName != null) _addons.add(addonName);
              _resolutions = resSet;
              _qualities = qualSet;
              _codecs = codecSet;
              _audios = audioSet;
              _sizes = sizeSet;
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  Color _getQualityColor(String resolution) {
    final res = resolution.toUpperCase();
    if (res.contains('2160P') || res.contains('4K') || res.contains('UHD')) {
      return Colors.amberAccent;
    } else if (res.contains('1080P')) {
      return Colors.blue;
    } else if (res.contains('720P')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  List<StreamWithAddon> _getFilteredStreams() {
    return streams.where((streamData) {
      if (streamData.stream.name == null) return false;

      if (_selectedAddons.isNotEmpty &&
          !_selectedAddons.contains(streamData.addonName)) {
        return false;
      }

      try {
        final info = StreamParser.parseStreamName(streamData.stream.name!);

        bool matchesResolution = _selectedResolutions.isEmpty ||
            (info.resolution != null &&
                _selectedResolutions.contains(info.resolution));
        bool matchesQuality = _selectedQualities.isEmpty ||
            (info.quality != null && _selectedQualities.contains(info.quality));
        bool matchesCodec = _selectedCodecs.isEmpty ||
            (info.codec != null && _selectedCodecs.contains(info.codec));
        bool matchesAudio = _selectedAudios.isEmpty ||
            (info.audio != null && _selectedAudios.contains(info.audio));
        bool matchesSize = _selectedSizes.isEmpty ||
            (info.size != null &&
                _selectedSizes
                    .contains(StreamParser.getSizeCategory(info.size)));

        return matchesResolution &&
            matchesQuality &&
            matchesCodec &&
            matchesAudio &&
            matchesSize;
      } catch (e) {
        _logger.warning(
            'Error parsing stream info: ${streamData.stream.name}', e);
        return false;
      }
    }).toList();
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);

    Widget buildFilterGroup(Set<String> options, Set<String> selected,
        Function(Set<String>) onChanged) {
      if (options.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 8,
        children: options.map((option) {
          return FilterChip(
            label: Text(option),
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected.contains(option)
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            selected: selected.contains(option),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            onSelected: (bool value) {
              final newSelection = Set<String>.from(selected);
              if (value) {
                newSelection.add(option);
              } else {
                newSelection.remove(option);
              }
              onChanged(newSelection);
            },
          );
        }).toList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          buildFilterGroup(_resolutions, _selectedResolutions,
              (value) => setState(() => _selectedResolutions = value)),
          if (_qualities.isNotEmpty) const SizedBox(width: 8),
          buildFilterGroup(_qualities, _selectedQualities,
              (value) => setState(() => _selectedQualities = value)),
          if (_codecs.isNotEmpty) const SizedBox(width: 8),
          buildFilterGroup(_codecs, _selectedCodecs,
              (value) => setState(() => _selectedCodecs = value)),
          if (_audios.isNotEmpty) const SizedBox(width: 8),
          buildFilterGroup(_audios, _selectedAudios,
              (value) => setState(() => _selectedAudios = value)),
          if (_sizes.isNotEmpty) const SizedBox(width: 8),
          buildFilterGroup(_sizes, _selectedSizes,
              (value) => setState(() => _selectedSizes = value)),
        ],
      ),
    );
  }

  Widget _buildStreamCard(StreamWithAddon streamData, ThemeData theme) {
    final stream = streamData.stream;
    final info = StreamParser.parseStreamName(stream.name ?? '');

    return InkWell(
      onTap: stream.url != null
          ? () async {
              if (stream.url != null) {
                final settings =
                    await PlaybackSettingsService.instance.getSettings();

                if (settings.externalPlayer) {
                  await ExternalPlayerService.openInExternalPlayer(
                    videoUrl: stream.url!,
                    playerPackage: settings.selectedExternalPlayer,
                  );

                  return;
                }

                String url =
                    '/player/${widget.meta.type}/${widget.meta.id}/${Uri.encodeQueryComponent(stream.url!)}?';

                final List<String> query = [];

                if (widget.meta.selectedVideoIndex != null) {
                  query.add("index=${widget.meta.selectedVideoIndex}");
                }

                if (stream.behaviorHints?["bingeGroup"] != null) {
                  query.add(
                    "binge-group=${Uri.encodeQueryComponent(stream.behaviorHints?["bingeGroup"])}",
                  );
                }

                if (mounted) {
                  context.push(
                    url + query.join("&"),
                    extra: {
                      "meta": widget.meta,
                    },
                  );
                }
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (info.resolution != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: StreamTag(
                            text: info.resolution!,
                            color: _getQualityColor(info.resolution!),
                            outlined: true,
                          ),
                        ),
                      Text(
                        (stream.name ?? 'Unknown Title') +
                            (stream.url != null ? "" : " (Not supported)"),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        stream.title ?? 'Unknown Title',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (stream.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stream.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (streamData.addonName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'From: ${streamData.addonName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (info.quality != null &&
                info.codec != null &&
                info.audio != null &&
                info.size != null &&
                info.unrated)
              const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info.quality != null)
                  StreamTag(
                    text: info.quality!,
                    color: theme.colorScheme.secondary,
                  ),
                if (info.codec != null)
                  StreamTag(
                    text: info.codec!,
                    color: theme.colorScheme.tertiary,
                  ),
                if (info.audio != null)
                  StreamTag(
                    text: info.audio!,
                    color: theme.colorScheme.primary,
                  ),
                if (info.size != null)
                  StreamTag(
                    text: StreamParser.getSizeCategory(info.size),
                    color: theme.colorScheme.secondary,
                  ),
                if (info.unrated)
                  StreamTag(
                    text: 'UNRATED',
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    if (streamSupportedAddonCount == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("No addons"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You have configured no addons for the streaming.",
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  "In order to stream you have to have atleast one addon in order to play.",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 12,
                ),
                OutlinedButton(
                  onPressed: () {
                    context.push('/settings/addons');
                  },
                  child: const Text(
                    "Manage Addons",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredStreams = _getFilteredStreams();

    return Scaffold(
      appBar: AppBar(
        title: Text("Streams (${filteredStreams.length})"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by addon',
            onSelected: (String addon) {
              setState(() {
                if (_selectedAddons.contains(addon)) {
                  _selectedAddons.remove(addon);
                } else {
                  _selectedAddons.add(addon);
                }
              });
            },
            itemBuilder: (BuildContext context) {
              return _addons.map((String addon) {
                return PopupMenuItem<String>(
                  value: addon,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedAddons.contains(addon),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedAddons.add(addon);
                            } else {
                              _selectedAddons.remove(addon);
                            }
                          });
                          Navigator.pop(context);
                        },
                      ),
                      Text(addon),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: theme.colorScheme.surface,
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildFilterChips(),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredStreams.isEmpty
                ? Center(
                    child: Text(
                      "No streams found",
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredStreams.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final streamData = filteredStreams[index];
                      return _buildStreamCard(streamData, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StreamWithAddon {
  final VideoStream stream;
  final String? addonName;

  StreamWithAddon({required this.stream, this.addonName});
}

class StreamTag extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;
  final bool outlined;

  const StreamTag({
    super.key,
    required this.text,
    this.color,
    this.backgroundColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;
    final effectiveBgColor = backgroundColor ?? effectiveColor.withAlpha(30);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? null : effectiveBgColor,
        borderRadius: BorderRadius.circular(4),
        border:
            outlined ? Border.all(color: effectiveColor.withAlpha(100)) : null,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
