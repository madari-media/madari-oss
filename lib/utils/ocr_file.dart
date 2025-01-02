import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<String>> ocrFiles(List<PlatformFile> file) async {
  List<String> returnValue = [];

  for (var value in file) {
    final file = File(value.path!);

    String extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      case "pdf":
        final result = await extractPDF(file);

        returnValue.add(result);
        break;
      case "png":
      case "bpm":
      case "jpeg":
      case "jpg":
      default:
        returnValue.add("");
    }
  }

  return returnValue;
}

Future<String> extractPDF(File file) async {
  return "";
}
