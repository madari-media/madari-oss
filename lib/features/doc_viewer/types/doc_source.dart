import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

import '../utils/get_types.dart';

part 'doc_source.g.dart';

enum DocType { pdf, video, audio, photo, unknown }

sealed class DocSource {
  String title;
  String id;
  String? season;
  String? episode;

  DocSource({
    required this.title,
    required this.id,
    this.season,
    this.episode,
  });

  DocType getType();

  Future<void> init() async {}

  void dispose();
}

class IframeSource extends DocSource {
  late final String url;

  IframeSource({
    required this.url,
    required super.title,
    required super.id,
    super.season,
    super.episode,
  });

  @override
  void dispose() {}

  @override
  DocType getType() {
    throw UnimplementedError();
  }
}

class ProgressStatus extends DocSource {
  final double? percentage;
  final String? progressText;

  @override
  DocType getType() {
    return DocType.unknown;
  }

  ProgressStatus({
    required super.id,
    required super.title,
    this.progressText,
    this.percentage,
  });

  @override
  void dispose() {}
}

class URLSource extends DocSource {
  String url;
  String? fileName;
  Map<String, String> headers = {};

  URLSource({
    required super.title,
    required this.url,
    required super.id,
    super.season,
    super.episode,
    this.fileName,
    this.headers = const {},
  });

  @override
  DocType getType() {
    String cleanUrl = (url).split('?').first;
    String extension = (fileName ?? cleanUrl).split('.').last.toLowerCase();

    return getTypeFromExtension(extension.trim());
  }

  @override
  void dispose() {}
}

class MediaURLSource extends URLSource {
  MediaURLSource({required super.title, required super.url, required super.id});

  @override
  DocType getType() {
    return DocType.video;
  }
}

class TorrentSource extends URLSource {
  final String infoHash;
  @override
  final String fileName;
  final List<String>? trackers;
  bool disposed = false;

  TorrentSource({
    required super.id,
    required super.title,
    required this.infoHash,
    required this.fileName,
    super.season,
    super.episode,
    this.trackers,
    super.url = "",
  });

  @override
  DocType getType() {
    String extension = fileName.split('.').last.toLowerCase();

    return getTypeFromExtension(extension);
  }

  @override
  Future<void> init() async {
    final trackers = [
      "udp://47.ip-51-68-199.eu:6969/announce",
      "udp://9.rarbg.me:2940",
      "udp://9.rarbg.to:2820",
      "udp://exodus.desync.com:6969/announce",
      "udp://explodie.org:6969/announce",
      "udp://ipv4.tracker.harry.lu:80/announce",
      "udp://open.stealth.si:80/announce",
      "udp://opentor.org:2710/announce",
      "udp://opentracker.i2p.rocks:6969/announce",
      "udp://retracker.lanta-net.ru:2710/announce",
      "udp://tracker.cyberia.is:6969/announce",
      "udp://tracker.dler.org:6969/announce",
      "udp://tracker.ds.is:6969/announce",
      "udp://tracker.internetwarriors.net:1337",
      "udp://tracker.openbittorrent.com:6969/announce",
      "udp://tracker.opentrackr.org:1337/announce",
      "udp://tracker.tiny-vps.com:6969/announce",
      "udp://tracker.torrent.eu.org:451/announce",
      "udp://valakas.rollo.dnsabr.com:2710/announce",
      "udp://www.torrent.eu.org:451/announce"
    ];

    final value1 =
        await http.get(Uri.parse("http://localhost:64544/torrents/$infoHash"));

    if (jsonDecode(value1.body)["error_kind"] == "torrent_not_found") {
      await http.post(
        Uri.parse("http://localhost:64544/torrents?overwrite=true"),
        body: addTrackersToMagnet(
          "magnet:?xt=urn:btih:${Uri.encodeComponent(infoHash)}",
          trackers,
        ),
      );
    } else {
      await http.post(
        Uri.parse("http://localhost:64544/torrents/$infoHash/start"),
      );
    }

    final value = await http.get(
      Uri.parse("http://localhost:64544/torrents/$infoHash"),
    );

    final obj = jsonDecode(
      value.body,
    );

    final objTorrent = TorrentInfoObject.fromJson(obj);

    for (final (index, file) in objTorrent.files.indexed) {
      if (path.basename(file.name) == fileName) {
        url = "http://localhost:64544/torrents/$infoHash/stream/$index";

        await http.post(
          Uri.parse(
              "http://localhost:64544/torrents/$infoHash/update_only_files"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(
            {
              "only_files": [index]
            },
          ),
        );
        break;
      }
    }

    if (url == "") throw AssertionError();

    return super.init();
  }

  @override
  void dispose() {
    super.dispose();

    disposed = true;

    http
        .post(
      Uri.parse(
        "http://localhost:64544/torrents/$infoHash/pause",
      ),
    )
        .then(
      (docs) {
        if (kDebugMode) {
          print(docs.statusCode);
          print("Stopped downloading file");
        }
      },
    );
  }

  Future<Uint8List?> readFirst1MBFromUrl(String url) async {
    final client = http.Client();

    try {
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts) {
        if (kDebugMode) {
          print("Reading $attempts at $url");
        }

        if (disposed) {
          break;
        }

        try {
          final request = http.Request('GET', Uri.parse(url));
          request.headers['range'] = 'bytes=0-${1024 * 1}';

          final streamedResponse = await client.send(request);

          // Check if the response is successful
          if (streamedResponse.statusCode >= 200 &&
              streamedResponse.statusCode < 300) {
            final bytes =
                await streamedResponse.stream.take(1024 * 1024).fold<List<int>>(
              [],
              (previous, element) => previous..addAll(element),
            );
            return Uint8List.fromList(bytes);
          }

          throw HttpException(
              'Failed with status: ${streamedResponse.statusCode}');
        } catch (e) {
          attempts++;
          if (attempts >= maxAttempts) {
            throw Exception('Failed after $maxAttempts attempts: $e');
          }

          if (kDebugMode) {
            print(e);
          }

          await Future.delayed(
            Duration(milliseconds: pow(2, attempts).toInt() * 100),
          );
        }
      }
      throw Exception('Unexpected error');
    } finally {
      client.close();
    }
  }
}

@JsonSerializable()
class TorrentInfoObject {
  final List<TorrentFile> files;

  TorrentInfoObject({
    required this.files,
  });

  factory TorrentInfoObject.fromJson(Map<String, dynamic> json) =>
      _$TorrentInfoObjectFromJson(json);

  Map<String, dynamic> toJson() => _$TorrentInfoObjectToJson(this);
}

@JsonSerializable()
class TorrentFile {
  final String name;

  TorrentFile({
    required this.name,
  });

  factory TorrentFile.fromJson(Map<String, dynamic> json) =>
      _$TorrentFileFromJson(json);

  Map<String, dynamic> toJson() => _$TorrentFileToJson(this);
}

String escapeRegex(String input) {
  const specialChars = r'[.*+?^${}()|[\]\\]';

  return input.replaceAllMapped(
      RegExp(specialChars), (Match match) => '\\${match.group(0)}');
}

class FileSource extends DocSource {
  String filePath;

  FileSource({
    required super.title,
    required this.filePath,
    required super.id,
  });

  @override
  DocType getType() {
    String extension = filePath.split('.').last.toLowerCase();
    return getTypeFromExtension(extension);
  }

  @override
  void dispose() {}
}

String addTrackersToMagnet(String magnetLink, List<String> trackers) {
  final uri = Uri.parse(magnetLink);

  if (!uri.scheme.contains("magnet")) {
    throw ArgumentError("Invalid magnet link");
  }

  final existingTrackers = uri.queryParametersAll['tr'] ?? [];
  final updatedTrackers = [...existingTrackers, ...trackers];

  final updatedQueryParameters =
      Map<String, List<String>>.from(uri.queryParametersAll)
        ..['tr'] = updatedTrackers;

  final updatedUri = uri.replace(queryParameters: updatedQueryParameters);

  return updatedUri.toString();
}
