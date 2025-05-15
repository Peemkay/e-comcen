import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for handling file utility operations
class FileUtilityService {
  // Singleton pattern
  static final FileUtilityService _instance = FileUtilityService._internal();
  factory FileUtilityService() => _instance;
  FileUtilityService._internal();

  /// Open a file with the default application
  Future<OpenResult> openFile(File file) async {
    try {
      // Ensure the file exists
      if (!await file.exists()) {
        return OpenResult(
          type: ResultType.noAppToOpen,
          message: 'File does not exist: ${file.path}',
        );
      }

      // Normalize file path for Windows
      String filePath = file.path;
      if (Platform.isWindows) {
        filePath = filePath.replaceAll('/', '\\');
      }

      // Open the file
      final result = await OpenFile.open(filePath);
      
      // Log the result
      debugPrint('Open file result: ${result.type} - ${result.message}');
      
      return result;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'Error opening file: $e',
      );
    }
  }

  /// Save a file to the downloads directory and open it
  Future<OpenResult> saveAndOpenFile(File sourceFile, {String? customFileName}) async {
    try {
      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/Downloads');

      // Create downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Use custom file name or original name
      final fileName = customFileName ?? path.basename(sourceFile.path);
      
      // Create a unique file name if file already exists
      String uniqueFileName = fileName;
      File destinationFile = File('${downloadDir.path}/$uniqueFileName');
      int counter = 1;
      
      while (await destinationFile.exists()) {
        final fileNameWithoutExtension = path.basenameWithoutExtension(fileName);
        final fileExtension = path.extension(fileName);
        uniqueFileName = '${fileNameWithoutExtension}_$counter$fileExtension';
        destinationFile = File('${downloadDir.path}/$uniqueFileName');
        counter++;
      }

      // Copy the file to the downloads directory
      await sourceFile.copy(destinationFile.path);
      
      // Open the file
      return await openFile(destinationFile);
    } catch (e) {
      debugPrint('Error saving and opening file: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'Error saving and opening file: $e',
      );
    }
  }

  /// Get file extension
  String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  /// Get file name without extension
  String getFileNameWithoutExtension(String fileName) {
    return path.basenameWithoutExtension(fileName);
  }

  /// Get file name
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get file size in human-readable format
  String getFileSizeString(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Check if a file exists
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Create a temporary file
  Future<File> createTempFile(String prefix, String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/${prefix}_$timestamp$extension';
    return File(filePath);
  }
}

/// Extension for OpenResult to provide more information
extension OpenResultExtension on OpenResult {
  /// Check if the file was opened successfully
  bool get isSuccess => type == ResultType.done;
  
  /// Get a user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case ResultType.done:
        return 'File opened successfully';
      case ResultType.noAppToOpen:
        return 'No application found to open this file type';
      case ResultType.fileNotFound:
        return 'File not found';
      case ResultType.permissionDenied:
        return 'Permission denied to open the file';
      case ResultType.error:
        return 'Error opening file: $message';
      default:
        return 'Unknown error: $message';
    }
  }
}
