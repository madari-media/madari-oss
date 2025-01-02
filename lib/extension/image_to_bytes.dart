import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

extension UIImageToInputImage on ui.Image {
  Future<File> toFile({String? fileName}) async {
    // Convert image to byte data
    final byteData = await toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert ui.Image to ByteData');
    }

    // Get the application temporary directory
    final directory = await getTemporaryDirectory();

    // Create a file with a unique name if not provided
    final file = File(
        '${directory.path}/${fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.png'}');

    // Write bytes to file
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }
}
