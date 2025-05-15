import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/file_attachment.dart';
import 'file_storage_service.dart';
import 'file_utility_service.dart';

/// Service for handling file attachments
class AttachmentService {
  // Singleton pattern
  static final AttachmentService _instance = AttachmentService._internal();
  factory AttachmentService() => _instance;
  AttachmentService._internal();

  // Services
  final FileStorageService _fileStorageService = FileStorageService();
  final FileUtilityService _fileUtilityService = FileUtilityService();

  // UUID generator
  final Uuid _uuid = const Uuid();

  /// Pick a file from device storage
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          return File(filePath);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Pick multiple files from device storage
  Future<List<File>> pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      return [];
    }
  }

  /// Save a file attachment
  Future<FileAttachment?> saveAttachment({
    required File file,
    required String referenceType,
    required String referenceId,
    String? description,
    String? uploadedBy,
  }) async {
    try {
      // Generate a unique path for the file
      final fileName = path.basename(file.path);
      final fileExt = path.extension(fileName);
      final uniqueFileName = '${_uuid.v4()}$fileExt';
      final relativePath =
          'attachments/$referenceType/$referenceId/$uniqueFileName';

      // Save file to storage
      final savedFilePath =
          await _fileStorageService.saveFile(file, relativePath);

      // Create file attachment
      final attachment = FileAttachment.fromFile(
        file: file,
        id: _uuid.v4(),
        referenceId: referenceId,
        referenceType: referenceType,
      );

      return attachment;
    } catch (e) {
      debugPrint('Error saving attachment: $e');
      return null;
    }
  }

  /// Get a file attachment
  Future<File?> getAttachment(String relativePath) async {
    try {
      return await _fileStorageService.getFile(relativePath);
    } catch (e) {
      debugPrint('Error getting attachment: $e');
      return null;
    }
  }

  /// Delete a file attachment
  Future<bool> deleteAttachment(String relativePath) async {
    try {
      return await _fileStorageService.deleteFile(relativePath);
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
      return false;
    }
  }

  /// Get all attachments for a reference
  Future<List<FileAttachment>> getAttachmentsForReference({
    required String referenceType,
    required String referenceId,
  }) async {
    try {
      final directory = 'attachments/$referenceType/$referenceId';
      final files = await _fileStorageService.listFiles(directory);

      return files.map((file) => FileAttachment.fromMap(file)).toList();
    } catch (e) {
      debugPrint('Error getting attachments for reference: $e');
      return [];
    }
  }

  /// Convert a list of attachment paths to FileAttachment objects
  Future<List<FileAttachment>> getAttachmentsFromPaths(
      List<String> paths) async {
    final List<FileAttachment> attachments = [];

    for (final path in paths) {
      final metadata = await _fileStorageService.getFileMetadata(path);
      if (metadata != null) {
        attachments.add(FileAttachment.fromMap(metadata));
      }
    }

    return attachments;
  }

  /// Open an attachment with the default application
  Future<OpenResult> openAttachment(FileAttachment attachment) async {
    try {
      // Get the file from storage
      final file = await _fileStorageService.getFile(attachment.path);

      // Check if file exists
      if (file == null || !await file.exists()) {
        debugPrint('Attachment file not found: ${attachment.path}');
        return OpenResult(
          type: ResultType.fileNotFound,
          message: 'File not found: ${attachment.name}',
        );
      }

      // Open the file
      return await _fileUtilityService.openFile(file);
    } catch (e) {
      debugPrint('Error opening attachment: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'Error opening file: $e',
      );
    }
  }

  /// Save attachment to downloads folder and open it
  Future<OpenResult> saveAndOpenAttachment(FileAttachment attachment) async {
    try {
      // Get the file from storage
      final file = await _fileStorageService.getFile(attachment.path);

      // Check if file exists
      if (file == null || !await file.exists()) {
        debugPrint('Attachment file not found: ${attachment.path}');
        return OpenResult(
          type: ResultType.fileNotFound,
          message: 'File not found: ${attachment.name}',
        );
      }

      // Save and open the file
      return await _fileUtilityService.saveAndOpenFile(file,
          customFileName: attachment.name);
    } catch (e) {
      debugPrint('Error saving and opening attachment: $e');
      return OpenResult(
        type: ResultType.error,
        message: 'Error saving and opening file: $e',
      );
    }
  }
}
