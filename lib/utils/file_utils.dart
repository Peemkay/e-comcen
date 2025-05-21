import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class FileUtils {
  /// Opens a file using the default application
  static Future<void> openFile(String filePath) async {
    try {
      // Normalize file path for Windows
      String normalizedPath = filePath;
      if (Platform.isWindows) {
        normalizedPath = normalizedPath.replaceAll('/', '\\');
      }

      final result = await OpenFile.open(normalizedPath);
      if (result.type != ResultType.done) {
        debugPrint('Error opening file: ${result.message}');
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint('Error in openFile: $e');
      throw Exception('Failed to open file: $e');
    }
  }

  /// Gets the MIME type of a file
  static String getMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    return mimeType ?? 'application/octet-stream';
  }

  /// Gets a formatted file size (e.g., "1.2 MB")
  static String getFormattedFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Checks if a file exists
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Gets the file extension from a path
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Gets the file name from a path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Gets the file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Creates a temporary file with the given content
  static Future<File> createTempFile(
      Uint8List content, String extension) async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/temp_$timestamp$extension';

    final file = File(filePath);
    await file.writeAsBytes(content);

    return file;
  }
}
