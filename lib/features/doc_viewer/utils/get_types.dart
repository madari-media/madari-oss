import '../types/doc_source.dart';

DocType getTypeFromExtension(String extension) {
  switch (extension) {
    // PDF extensions
    case 'pdf':
      return DocType.pdf;

    // Video extensions
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'wmv':
    case 'mkv':
    case 'webm':
    case 'flv':
    case 'm4v':
    case 'mpg':
    case 'mpeg':
    case '3gp':
      return DocType.video;

    // Audio extensions
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
    case 'm4a':
    case 'wma':
    case 'ogg':
    case 'opus':
      return DocType.audio;

    // Photo extensions
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
    case 'tiff':
    case 'webp':
    case 'svg':
    case 'heic':
    case 'raw':
      return DocType.photo;

    default:
      return DocType.unknown;
  }
}
