import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;

/// Service for handling file save dialogs and opening saved files
class FileSaveDialogService {
  /// Show a save file dialog and save the PDF to the selected location
  /// Returns the path to the saved file, or null if the operation was cancelled
  Future<String?> saveFileWithDialog(
    pw.Document pdf,
    String defaultFileName, {
    String? initialDirectory,
  }) async {
    try {
      // Show the save file dialog
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        lockParentWindow: true,
      );

      // Ensure the file has a .pdf extension
      if (!outputPath.toLowerCase().endsWith('.pdf')) {
        outputPath = '$outputPath.pdf';
      }

      // Save the PDF to the selected location
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());
      debugPrint('File saved to: $outputPath');

      return outputPath;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  /// Open a file with the default application
  /// Returns true if the file was opened successfully, false otherwise
  Future<bool> openFile(String filePath) async {
    try {
      // Ensure the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return false;
      }

      // Normalize file path for Windows
      String normalizedPath = filePath;
      if (Platform.isWindows) {
        normalizedPath = normalizedPath.replaceAll('/', '\\');
      }

      // Open the file with the default application
      final result = await OpenFile.open(normalizedPath);

      // Check if the file was opened successfully
      if (result.type != ResultType.done) {
        debugPrint('Error opening file: ${result.message}');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error opening file: $e');
      return false;
    }
  }

  /// Open the folder containing a file
  /// Returns true if the folder was opened successfully, false otherwise
  Future<bool> openContainingFolder(String filePath) async {
    try {
      // Get the directory containing the file
      final directory = path.dirname(filePath);

      // Normalize directory path for Windows
      String normalizedPath = directory;
      if (Platform.isWindows) {
        normalizedPath = normalizedPath.replaceAll('/', '\\');
      }

      // Open the directory
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [normalizedPath]);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', [normalizedPath]);
        return true;
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [normalizedPath]);
        return true;
      } else {
        debugPrint('Opening containing folder not supported on this platform');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening containing folder: $e');
      return false;
    }
  }
}
