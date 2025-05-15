import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Model class for a saved report
class SavedReport {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final String reportType;
  final int fileSize;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  SavedReport({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.reportType,
    required this.fileSize,
    this.thumbnailPath,
    this.metadata,
  });

  /// Create a SavedReport from a map
  factory SavedReport.fromMap(Map<String, dynamic> map) {
    return SavedReport(
      id: map['id'],
      name: map['name'],
      filePath: map['filePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      reportType: map['reportType'],
      fileSize: map['fileSize'],
      thumbnailPath: map['thumbnailPath'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  /// Convert SavedReport to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reportType': reportType,
      'fileSize': fileSize,
      'thumbnailPath': thumbnailPath,
      'metadata': metadata,
    };
  }

  /// Get formatted file size
  String get formattedFileSize {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = fileSize.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Get formatted creation date
  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy, HH:mm').format(createdAt);
  }
}

/// Service for managing the report library
class ReportLibraryService {
  // Singleton pattern
  static final ReportLibraryService _instance = ReportLibraryService._internal();
  factory ReportLibraryService() => _instance;
  ReportLibraryService._internal();

  // Database
  Database? _database;
  final String _reportsTable = 'reports';
  final _uuid = Uuid();

  /// Initialize the database
  Future<void> initDatabase() async {
    if (_database != null) return;

    // Get the database path
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'nasds_reports.db');

    // Open the database
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Create reports table
        await db.execute('''
          CREATE TABLE $_reportsTable (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            filePath TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            reportType TEXT NOT NULL,
            fileSize INTEGER NOT NULL,
            thumbnailPath TEXT,
            metadata TEXT
          )
        ''');
      },
    );
  }

  /// Get reports directory
  Future<Directory> get _reportsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${appDir.path}/reports');

    // Create directory if it doesn't exist
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    return reportsDir;
  }

  /// Get thumbnails directory
  Future<Directory> get _thumbnailsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${appDir.path}/reports/thumbnails');

    // Create directory if it doesn't exist
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    return thumbnailsDir;
  }

  /// Save a report to the library
  Future<SavedReport?> saveReport({
    required pw.Document pdfDocument,
    required String name,
    required String reportType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Initialize database
      await initDatabase();

      // Generate a unique ID
      final id = _uuid.v4();

      // Get reports directory
      final reportsDir = await _reportsDir;

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${path.basenameWithoutExtension(name)}_$timestamp.pdf';
      final filePath = '${reportsDir.path}/$fileName';

      // Save the PDF to the file system
      final file = File(filePath);
      final pdfBytes = await pdfDocument.save();
      await file.writeAsBytes(pdfBytes);

      // Get file size
      final fileSize = await file.length();

      // Create a thumbnail (first page of the PDF)
      String? thumbnailPath;
      try {
        thumbnailPath = await _createThumbnail(pdfDocument, id);
      } catch (e) {
        debugPrint('Error creating thumbnail: $e');
      }

      // Create SavedReport object
      final report = SavedReport(
        id: id,
        name: name,
        filePath: filePath,
        createdAt: DateTime.now(),
        reportType: reportType,
        fileSize: fileSize,
        thumbnailPath: thumbnailPath,
        metadata: metadata,
      );

      // Save to database
      await _database?.insert(_reportsTable, report.toMap());

      return report;
    } catch (e) {
      debugPrint('Error saving report: $e');
      return null;
    }
  }

  /// Create a thumbnail for a PDF document
  Future<String?> _createThumbnail(pw.Document pdfDocument, String reportId) async {
    // Get thumbnails directory
    final thumbnailsDir = await _thumbnailsDir;

    // Create a thumbnail file path
    final thumbnailPath = '${thumbnailsDir.path}/$reportId.png';

    // TODO: Implement PDF to image conversion for thumbnail
    // This would require a plugin like pdf_render or a custom implementation
    // For now, we'll return null

    return null;
  }

  /// Get all saved reports
  Future<List<SavedReport>> getAllReports() async {
    // Initialize database
    await initDatabase();

    // Query the database
    final List<Map<String, dynamic>> maps = await _database?.query(
      _reportsTable,
      orderBy: 'createdAt DESC',
    ) ?? [];

    // Convert to SavedReport objects
    return List.generate(maps.length, (i) {
      return SavedReport.fromMap(maps[i]);
    });
  }

  /// Get a report by ID
  Future<SavedReport?> getReportById(String id) async {
    // Initialize database
    await initDatabase();

    // Query the database
    final List<Map<String, dynamic>> maps = await _database?.query(
      _reportsTable,
      where: 'id = ?',
      whereArgs: [id],
    ) ?? [];

    // Return the report if found
    if (maps.isNotEmpty) {
      return SavedReport.fromMap(maps.first);
    }

    return null;
  }

  /// Delete a report
  Future<bool> deleteReport(String id) async {
    try {
      // Initialize database
      await initDatabase();

      // Get the report
      final report = await getReportById(id);
      if (report == null) {
        return false;
      }

      // Delete the file
      final file = File(report.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete the thumbnail if it exists
      if (report.thumbnailPath != null) {
        final thumbnailFile = File(report.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }

      // Delete from database
      await _database?.delete(
        _reportsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting report: $e');
      return false;
    }
  }

  /// Open a report
  Future<bool> openReport(String id) async {
    try {
      // Get the report
      final report = await getReportById(id);
      if (report == null) {
        return false;
      }

      // Check if the file exists
      final file = File(report.filePath);
      if (!await file.exists()) {
        return false;
      }

      // Open the file
      final result = await OpenFile.open(report.filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error opening report: $e');
      return false;
    }
  }
}
