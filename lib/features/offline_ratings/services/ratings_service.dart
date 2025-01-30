import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../data/db.dart';
import '../models/rating_model.dart';

class RatingsService {
  final db = AppDatabase();

  Future<List<RatingModel>> downloadAndParseRatings(
    String url,
    void Function(double) onProgress,
  ) async {
    List<RatingModel> ratings = [];
    File? tempGzFile;
    File? tempTsvFile;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      tempGzFile = File(path.join(tempDir.path, 'ratings_$timestamp.tsv.gz'));
      tempTsvFile = File(path.join(tempDir.path, 'ratings_$timestamp.tsv'));

      await _downloadFile(url, tempGzFile, onProgress);

      onProgress(0.95);

      await _extractGzFile(tempGzFile, tempTsvFile);

      onProgress(0.98);

      ratings = await _parseTsvFile(tempTsvFile);

      onProgress(1.0);

      await AppDatabase().ratingTable.deleteAll();

      await AppDatabase().ratingTable.insertAll(
        ratings.map(
          (rating) {
            return RatingTableData(
              tconst: rating.tconst,
              averageRating: rating.averageRating,
              numVotes: rating.numVotes,
            );
          },
        ),
      );

      return ratings;
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception(
            'Download timed out. Please check your connection and try again.');
      } else if (e is FormatException) {
        throw Exception(
            'Failed to parse the downloaded data. The file may be corrupted.');
      } else {
        throw Exception('Failed to process ratings: ${e.toString()}');
      }
    } finally {
      // Cleanup temporary files
      await _cleanupTempFiles([tempGzFile, tempTsvFile]);
    }
  }

  Future<void> _downloadFile(
      String url, File destFile, Function(double) onProgress) async {
    final client = http.Client();

    try {
      final response = await client
          .send(
            http.Request('GET', Uri.parse(url)),
          )
          .timeout(
            const Duration(seconds: 120),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int received = 0;

      final sink = destFile.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;

          if (contentLength > 0) {
            onProgress(
              0.9 * received / contentLength,
            );
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _extractGzFile(File gzFile, File outputFile) async {
    final bytes = await gzFile.readAsBytes();
    const gzip = GZipDecoder();
    final decoded = gzip.decodeBytes(bytes);

    if (decoded.isEmpty) {
      throw Exception('Decompression failed: Empty result');
    }

    await outputFile.writeAsBytes(decoded);
  }

  Future<List<RatingModel>> _parseTsvFile(File tsvFile) async {
    final lines = await tsvFile.readAsLines();

    if (lines.isNotEmpty) {
      lines.removeAt(0);
    }

    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final columns = line.split('\t');
          try {
            return RatingModel.fromTsv(columns);
          } catch (e) {
            print('Warning: Failed to parse line: $line');
            return null;
          }
        })
        .where((rating) => rating != null)
        .cast<RatingModel>()
        .toList();
  }

  Future<void> _cleanupTempFiles(List<File?> files) async {
    for (final file in files) {
      if (file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          print('Warning: Failed to delete temporary file: ${file.path}');
        }
      }
    }
  }
}
