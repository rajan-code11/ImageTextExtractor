import 'dart:io';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  /// Loads an image from file, converts to grayscale, enhances contrast, and saves to a temp file.
  static Future<File> preprocess(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    // Convert to grayscale
    image = img.grayscale(image);
    // Enhance contrast
    image = img.adjustColor(image, contrast: 1.2, brightness: 0.05);
    // Optionally, resize if too large (uncomment if needed)
    // if (image.width > 2000) {
    //   image = img.copyResize(image, width: 2000);
    // }

    // Save to temp file
    final tempPath = file.parent.path + '/preprocessed_' + file.uri.pathSegments.last;
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(img.encodeJpg(image, quality: 95));
    return tempFile;
  }
}
