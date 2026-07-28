import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FileHelper {
  /// Helper to create a Dio MultipartFile from an XFile.
  /// Works safely on both Web and Mobile.
  static Future<MultipartFile> createMultipart(XFile file, {String? filename}) async {
    final name = filename ?? file.name;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return MultipartFile.fromBytes(bytes, filename: name);
    } else {
      return await MultipartFile.fromFile(file.path, filename: name);
    }
  }
}
