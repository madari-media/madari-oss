import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'torrent_stat.g.dart';

class TorrentStats extends StatefulWidget {
  final String torrentHash;

  const TorrentStats({
    super.key,
    required this.torrentHash,
  });

  @override
  State<TorrentStats> createState() => _TorrentStatsState();
}

class _TorrentStatsState extends State<TorrentStats> {
  late Timer _timer;
  TorrentStat? stat;
  bool hasOpenOnce = false;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        getStats();
      },
    );
  }

  getStats() async {
    final result = await http.get(
      Uri.parse(
          "http://localhost:64544/torrents/${widget.torrentHash}/stats/v1"),
    );

    final data = TorrentStat.fromJson(jsonDecode(result.body));

    if (mounted) {
      setState(() {
        stat = data;
        hasOpenOnce = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmallScreen = media.size.width < 600;

    if (stat == null) {
      return Container(
        width: min(media.size.width, 800),
        height: min(media.size.height, 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: min(media.size.width, 800),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status and Progress Row
            if (stat?.live != null) ...[
              Row(
                children: [
                  // Status Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stat?.state == 'Downloading'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stat?.state ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${((stat!.progressBytes / stat!.totalBytes) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFFE50914),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              LinearProgressIndicator(
                value: stat!.progressBytes / stat!.totalBytes,
                backgroundColor: Colors.grey[800],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
              ),
              const SizedBox(height: 12),

              // Main Stats Grid
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildCompactStat(
                    Icons.download,
                    Colors.green,
                    stat!.live!.downloadSpeed.humanReadable,
                  ),
                  _buildCompactStat(
                    Icons.upload,
                    Colors.blue,
                    stat!.live!.uploadSpeed.humanReadable,
                  ),
                  if (stat!.live!.timeRemaining?.humanReadable != null)
                    _buildCompactStat(
                      Icons.timer,
                      Colors.orange,
                      stat!.live!.timeRemaining!.humanReadable,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Advanced Stats
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildAdvancedStatRow(
                      'Peers',
                      '${stat!.live!.snapshot.peerStats.live}/${stat!.live!.snapshot.peerStats.seen}',
                    ),
                    if (stat!.live!.averagePieceDownloadTime?.secs != null)
                      _buildAdvancedStatRow(
                        'Avg Download',
                        '${stat!.live!.averagePieceDownloadTime?.secs}s',
                      ),
                    _buildAdvancedStatRow(
                      'Downloaded',
                      _formatBytes(
                          stat!.live!.snapshot.downloadedAndCheckedBytes),
                    ),
                    _buildAdvancedStatRow(
                      'Uploaded',
                      _formatBytes(stat!.live!.snapshot.uploadedBytes),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

@JsonSerializable()
class TorrentStat {
  @JsonKey(name: "state")
  final String state;
  @JsonKey(name: "file_progress")
  final List<int> fileProgress;
  @JsonKey(name: "error")
  final dynamic error;
  @JsonKey(name: "progress_bytes")
  final int progressBytes;
  @JsonKey(name: "uploaded_bytes")
  final int uploadedBytes;
  @JsonKey(name: "total_bytes")
  final int totalBytes;
  @JsonKey(name: "finished")
  final bool finished;
  @JsonKey(name: "live")
  final Live? live;

  TorrentStat({
    required this.state,
    required this.fileProgress,
    required this.error,
    required this.progressBytes,
    required this.uploadedBytes,
    required this.totalBytes,
    required this.finished,
    required this.live,
  });

  TorrentStat copyWith({
    String? state,
    List<int>? fileProgress,
    dynamic error,
    int? progressBytes,
    int? uploadedBytes,
    int? totalBytes,
    bool? finished,
    Live? live,
  }) =>
      TorrentStat(
        state: state ?? this.state,
        fileProgress: fileProgress ?? this.fileProgress,
        error: error ?? this.error,
        progressBytes: progressBytes ?? this.progressBytes,
        uploadedBytes: uploadedBytes ?? this.uploadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        finished: finished ?? this.finished,
        live: live ?? this.live,
      );

  factory TorrentStat.fromJson(Map<String, dynamic> json) =>
      _$TorrentStatFromJson(json);

  Map<String, dynamic> toJson() => _$TorrentStatToJson(this);
}

@JsonSerializable()
class Live {
  @JsonKey(name: "snapshot")
  final Snapshot snapshot;
  @JsonKey(name: "average_piece_download_time")
  final AveragePieceDownloadTime? averagePieceDownloadTime;
  @JsonKey(name: "download_speed")
  final LoadSpeed downloadSpeed;
  @JsonKey(name: "upload_speed")
  final LoadSpeed uploadSpeed;
  @JsonKey(name: "time_remaining")
  final TimeRemaining? timeRemaining;

  Live({
    required this.snapshot,
    this.averagePieceDownloadTime,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.timeRemaining,
  });

  Live copyWith({
    Snapshot? snapshot,
    AveragePieceDownloadTime? averagePieceDownloadTime,
    LoadSpeed? downloadSpeed,
    LoadSpeed? uploadSpeed,
    TimeRemaining? timeRemaining,
  }) =>
      Live(
        snapshot: snapshot ?? this.snapshot,
        averagePieceDownloadTime:
            averagePieceDownloadTime ?? this.averagePieceDownloadTime,
        downloadSpeed: downloadSpeed ?? this.downloadSpeed,
        uploadSpeed: uploadSpeed ?? this.uploadSpeed,
        timeRemaining: timeRemaining ?? this.timeRemaining,
      );

  factory Live.fromJson(Map<String, dynamic> json) => _$LiveFromJson(json);

  Map<String, dynamic> toJson() => _$LiveToJson(this);
}

@JsonSerializable()
class AveragePieceDownloadTime {
  @JsonKey(name: "secs")
  final int secs;
  @JsonKey(name: "nanos")
  final int nanos;

  AveragePieceDownloadTime({
    required this.secs,
    required this.nanos,
  });

  AveragePieceDownloadTime copyWith({
    int? secs,
    int? nanos,
  }) =>
      AveragePieceDownloadTime(
        secs: secs ?? this.secs,
        nanos: nanos ?? this.nanos,
      );

  factory AveragePieceDownloadTime.fromJson(Map<String, dynamic> json) =>
      _$AveragePieceDownloadTimeFromJson(json);

  Map<String, dynamic> toJson() => _$AveragePieceDownloadTimeToJson(this);
}

@JsonSerializable()
class LoadSpeed {
  @JsonKey(name: "mbps")
  final double mbps;
  @JsonKey(name: "human_readable")
  final String humanReadable;

  LoadSpeed({
    required this.mbps,
    required this.humanReadable,
  });

  LoadSpeed copyWith({
    double? mbps,
    String? humanReadable,
  }) =>
      LoadSpeed(
        mbps: mbps ?? this.mbps,
        humanReadable: humanReadable ?? this.humanReadable,
      );

  factory LoadSpeed.fromJson(Map<String, dynamic> json) =>
      _$LoadSpeedFromJson(json);

  Map<String, dynamic> toJson() => _$LoadSpeedToJson(this);
}

@JsonSerializable()
class Snapshot {
  @JsonKey(name: "downloaded_and_checked_bytes")
  final int downloadedAndCheckedBytes;
  @JsonKey(name: "fetched_bytes")
  final int fetchedBytes;
  @JsonKey(name: "uploaded_bytes")
  final int uploadedBytes;
  @JsonKey(name: "downloaded_and_checked_pieces")
  final int downloadedAndCheckedPieces;
  @JsonKey(name: "total_piece_download_ms")
  final int totalPieceDownloadMs;
  @JsonKey(name: "peer_stats")
  final PeerStats peerStats;

  Snapshot({
    required this.downloadedAndCheckedBytes,
    required this.fetchedBytes,
    required this.uploadedBytes,
    required this.downloadedAndCheckedPieces,
    required this.totalPieceDownloadMs,
    required this.peerStats,
  });

  Snapshot copyWith({
    int? downloadedAndCheckedBytes,
    int? fetchedBytes,
    int? uploadedBytes,
    int? downloadedAndCheckedPieces,
    int? totalPieceDownloadMs,
    PeerStats? peerStats,
  }) =>
      Snapshot(
        downloadedAndCheckedBytes:
            downloadedAndCheckedBytes ?? this.downloadedAndCheckedBytes,
        fetchedBytes: fetchedBytes ?? this.fetchedBytes,
        uploadedBytes: uploadedBytes ?? this.uploadedBytes,
        downloadedAndCheckedPieces:
            downloadedAndCheckedPieces ?? this.downloadedAndCheckedPieces,
        totalPieceDownloadMs: totalPieceDownloadMs ?? this.totalPieceDownloadMs,
        peerStats: peerStats ?? this.peerStats,
      );

  factory Snapshot.fromJson(Map<String, dynamic> json) =>
      _$SnapshotFromJson(json);

  Map<String, dynamic> toJson() => _$SnapshotToJson(this);
}

@JsonSerializable()
class PeerStats {
  @JsonKey(name: "queued")
  final int queued;
  @JsonKey(name: "connecting")
  final int connecting;
  @JsonKey(name: "live")
  final int live;
  @JsonKey(name: "seen")
  final int seen;
  @JsonKey(name: "dead")
  final int dead;
  @JsonKey(name: "not_needed")
  final int notNeeded;
  @JsonKey(name: "steals")
  final int steals;

  PeerStats({
    required this.queued,
    required this.connecting,
    required this.live,
    required this.seen,
    required this.dead,
    required this.notNeeded,
    required this.steals,
  });

  PeerStats copyWith({
    int? queued,
    int? connecting,
    int? live,
    int? seen,
    int? dead,
    int? notNeeded,
    int? steals,
  }) =>
      PeerStats(
        queued: queued ?? this.queued,
        connecting: connecting ?? this.connecting,
        live: live ?? this.live,
        seen: seen ?? this.seen,
        dead: dead ?? this.dead,
        notNeeded: notNeeded ?? this.notNeeded,
        steals: steals ?? this.steals,
      );

  factory PeerStats.fromJson(Map<String, dynamic> json) =>
      _$PeerStatsFromJson(json);

  Map<String, dynamic> toJson() => _$PeerStatsToJson(this);
}

@JsonSerializable()
class TimeRemaining {
  @JsonKey(name: "duration")
  final AveragePieceDownloadTime duration;
  @JsonKey(name: "human_readable")
  final String humanReadable;

  TimeRemaining({
    required this.duration,
    required this.humanReadable,
  });

  TimeRemaining copyWith({
    AveragePieceDownloadTime? duration,
    String? humanReadable,
  }) =>
      TimeRemaining(
        duration: duration ?? this.duration,
        humanReadable: humanReadable ?? this.humanReadable,
      );

  factory TimeRemaining.fromJson(Map<String, dynamic> json) =>
      _$TimeRemainingFromJson(json);

  Map<String, dynamic> toJson() => _$TimeRemainingToJson(this);
}
