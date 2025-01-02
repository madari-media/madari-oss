import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Base64ImageWidget extends StatelessWidget {
  /// The base64 encoded image string
  final String base64String;

  /// Optional width for the image
  final double? width;

  /// Optional height for the image
  final double? height;

  /// Optional BoxFit to control how the image fills its space
  final BoxFit? fit;

  const Base64ImageWidget({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Decode the base64 string
      Uint8List bytes = base64Decode(base64String);

      // Create an image from the decoded bytes
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback error widget if image fails to load
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Handle decoding errors
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Text(
            'Invalid image',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
  }
}
