import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'local_storage_service.dart';

/// Service for handling file storage locally
class FileStorageService {
  // Singleton pattern
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  // Local storage service
  final LocalStorageService _localStorageService = LocalStorageService();

  // Database
  Database? _database;
  final String _filesTable = 'files';

  // Get application documents directory
  Future<Directory> get _appDir async =>
      await getApplicationDocumentsDirectory();

  // Get E-COMCEN storage directory
  Future<Directory> get _storageDir async {
    final appDir = await _appDir;
    final storageDir = Directory('${appDir.path}/e-comcen-storage');

    // Create directory if it doesn't exist
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    return storageDir;
  }

  // Get unit storage directory
  Future<Directory> get _unitStorageDir async {
    if (_localStorageService.currentUnitId == null) {
      throw Exception('No unit selected');
    }

    final storageDir = await _storageDir;
    final unitDir =
        Directory('${storageDir.path}/${_localStorageService.currentUnitId}');

    // Create directory if it doesn't exist
    if (!await unitDir.exists()) {
      await unitDir.create(recursive: true);
    }

    return unitDir;
  }

  /// Initialize the database
  Future<void> initDatabase() async {
    if (_database != null) return;

    // Get the database path
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'nasds_files.db');

    // Open the database
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Create files table
        await db.execute('''
          CREATE TABLE $_filesTable (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            size INTEGER,
            mimeType TEXT,
            uploadedBy TEXT,
            uploadedAt INTEGER,
            unitId TEXT
          )
        ''');
      },
    );
  }

  // Save file to local storage
  Future<String> saveFile(File file, String relativePath) async {
    try {
      // Initialize database if not already initialized
      await initDatabase();

      final unitDir = await _unitStorageDir;
      final fileName = path.basename(file.path);
      final fileDir = path.dirname(relativePath);

      // Create directory if it doesn't exist
      final saveDir = Directory('${unitDir.path}/$fileDir');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Save file
      final savedFile = await file.copy('${saveDir.path}/$fileName');

      // Create file metadata
      final fileId = const Uuid().v4();
      final fileMetadata = {
        'id': fileId,
        'name': fileName,
        'path': relativePath,
        'size': await file.length(),
        'mimeType': _getMimeType(fileName),
        'uploadedBy':
            'current_user', // In a real app, this would be the actual user ID
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
        'unitId': _localStorageService.currentUnitId,
      };

      // Save metadata to local database
      final db = _database;
      if (db != null) {
        await db.insert(_filesTable, fileMetadata);
      }

      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      rethrow;
    }
  }

  // Get file from local storage
  Future<File?> getFile(String relativePath) async {
    try {
      final unitDir = await _unitStorageDir;

      // Normalize path for Windows
      String normalizedPath = relativePath.replaceAll('\\', '/');

      // Ensure there's no leading slash
      if (normalizedPath.startsWith('/')) {
        normalizedPath = normalizedPath.substring(1);
      }

      // Combine paths properly
      final filePath = path.join(unitDir.path, normalizedPath);

      // Create file object
      final file = File(filePath);

      // Check if file exists
      if (await file.exists()) {
        return file;
      } else {
        debugPrint('File not found at path: $filePath');

        // Try alternative path formats
        final alternativePath1 = '${unitDir.path}/$normalizedPath';
        final alternativeFile1 = File(alternativePath1);

        if (await alternativeFile1.exists()) {
          debugPrint('File found at alternative path: $alternativePath1');
          return alternativeFile1;
        }

        // Try with Windows path separator
        final alternativePath2 =
            '${unitDir.path}\\${normalizedPath.replaceAll('/', '\\')}';
        final alternativeFile2 = File(alternativePath2);

        if (await alternativeFile2.exists()) {
          debugPrint('File found at Windows path: $alternativePath2');
          return alternativeFile2;
        }

        debugPrint('File not found after trying alternative paths');
      }

      return null;
    } catch (e) {
      debugPrint('Error getting file: $e');
      return null;
    }
  }

  // Delete file from local storage
  Future<bool> deleteFile(String relativePath) async {
    try {
      // Initialize database if not already initialized
      await initDatabase();

      final unitDir = await _unitStorageDir;
      final filePath = '${unitDir.path}/$relativePath';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();

        // Delete file metadata from local database
        final db = _database;
        if (db != null) {
          await db.delete(
            _filesTable,
            where: 'path = ? AND unitId = ?',
            whereArgs: [relativePath, _localStorageService.currentUnitId],
          );
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // List files in a directory
  Future<List<Map<String, dynamic>>> listFiles(String directory) async {
    try {
      // Initialize database if not already initialized
      await initDatabase();

      final db = _database;
      if (db == null) return [];

      // Query files from local database
      final result = await db.query(
        _filesTable,
        where: 'path LIKE ? AND unitId = ?',
        whereArgs: ['$directory%', _localStorageService.currentUnitId],
      );

      return result;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  // Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String relativePath) async {
    try {
      // Initialize database if not already initialized
      await initDatabase();

      final db = _database;
      if (db == null) return null;

      // Query file metadata from local database
      final result = await db.query(
        _filesTable,
        where: 'path = ? AND unitId = ?',
        whereArgs: [relativePath, _localStorageService.currentUnitId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  // Get MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // Clear all files
  Future<void> clearAllFiles() async {
    try {
      final storageDir = await _storageDir;

      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
        await storageDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing files: $e');
    }
  }

  // Get total storage size
  Future<int> getTotalStorageSize() async {
    try {
      final storageDir = await _storageDir;
      int totalSize = 0;

      await for (final entity in storageDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error getting total storage size: $e');
      return 0;
    }
  }

  // Get unit storage size
  Future<int> getUnitStorageSize() async {
    try {
      final unitDir = await _unitStorageDir;
      int totalSize = 0;

      await for (final entity in unitDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error getting unit storage size: $e');
      return 0;
    }
  }
}
