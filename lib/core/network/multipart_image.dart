import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

abstract final class MultipartImage {
  static String resolveFilename({
    String? pickedName,
    String? filePath,
    String fallback = 'image.jpg',
  }) {
    final name = pickedName?.trim();
    if (name != null && name.isNotEmpty && name.contains('.')) {
      return name;
    }

    if (filePath != null && filePath.contains('.')) {
      return filePath.split(Platform.pathSeparator).last;
    }

    return fallback;
  }

  static Future<MultipartFile> fromPickedFile({
    required File file,
    String? filename,
    Uint8List? bytes,
  }) async {
    final safeName = resolveFilename(pickedName: filename, filePath: file.path);

    if (bytes != null && bytes.isNotEmpty) {
      return MultipartFile.fromBytes(bytes, filename: safeName);
    }

    return MultipartFile.fromFile(file.path, filename: safeName);
  }
}
