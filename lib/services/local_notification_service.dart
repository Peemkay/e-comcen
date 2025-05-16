import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'local_storage_service.dart';

/// Service for handling local notifications
/// This replaces the Firebase notification service with a local implementation
class LocalNotificationService {
  // Singleton pattern
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;

  // Database
  Database? _database;
  final String _notificationsTable = 'notifications';

  // Notification callback
  Function(Map<String, dynamic>)? _onNotificationTap;

  // Stream controller for notifications
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Stream getter
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  LocalNotificationService._internal();

  /// Initialize local notification services
  Future<void> initialize(
      {Function(Map<String, dynamic>)? onNotificationTap}) async {
    debugPrint('Initializing local notification services');

    _onNotificationTap = onNotificationTap;

    // Get database from LocalStorageService
    final localStorageService = LocalStorageService();
    await localStorageService.initialize();

    // Initialize database
    await _initDatabase();

    debugPrint('Local notification services initialized');
  }

  /// Initialize the SQLite database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'nasds_notifications.db');

    // Open the database
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create notifications table
        await db.execute('''
          CREATE TABLE $_notificationsTable (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT,
            senderId TEXT,
            recipientId TEXT,
            unitId TEXT,
            isRead INTEGER DEFAULT 0,
            data TEXT,
            createdAt TEXT
          )
        ''');

        // Insert sample notifications
        await _insertSampleNotifications(db);
      },
    );
  }

  /// Insert sample notifications into the database
  Future<void> _insertSampleNotifications(Database db) async {
    final now = DateTime.now();

    // Insert welcome notification
    await db.insert(_notificationsTable, {
      'id': const Uuid().v4(),
      'title': 'Welcome to NASDS',
      'body': 'Thank you for using the Nigerian Army Signal Dispatch System.',
      'senderId': 'system',
      'recipientId': null,
      'unitId': 'unit_001',
      'isRead': 0,
      'data': jsonEncode({'type': 'welcome'}),
      'createdAt': now.toIso8601String(),
    });
  }

  /// Subscribe to unit topic
  Future<void> subscribeToUnitTopic() async {
    // Get current unit ID from LocalStorageService
    final localStorageService = LocalStorageService();
    final unitId = localStorageService.currentUnitId;

    if (unitId != null) {
      debugPrint('Subscribed to unit topic: $unitId (local implementation)');
    }
  }

  /// Send notification to user
  Future<void> sendNotificationToUser(
    String recipientId,
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final db = _database;

      final notification = {
        'id': const Uuid().v4(),
        'title': title,
        'body': body,
        'senderId':
            'current_user', // This would be the actual user ID in a real implementation
        'recipientId': recipientId,
        'unitId': null,
        'isRead': 0,
        'data': data != null ? jsonEncode(data) : null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await db!.insert(_notificationsTable, notification);

      // Emit notification to stream
      _notificationStreamController.add({
        ...notification,
        'data': data,
      });

      debugPrint('Notification sent to user: $recipientId');
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }

  /// Send notification to unit
  Future<void> sendNotificationToUnit(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get current unit ID from LocalStorageService
      final localStorageService = LocalStorageService();
      final unitId = localStorageService.currentUnitId;

      if (unitId == null) {
        debugPrint('Cannot send notification: No unit ID');
        return;
      }

      final db = _database;

      final notification = {
        'id': const Uuid().v4(),
        'title': title,
        'body': body,
        'senderId':
            'current_user', // This would be the actual user ID in a real implementation
        'recipientId': null,
        'unitId': unitId,
        'isRead': 0,
        'data': data != null ? jsonEncode(data) : null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await db!.insert(_notificationsTable, notification);

      // Emit notification to stream
      _notificationStreamController.add({
        ...notification,
        'data': data,
      });

      debugPrint('Notification sent to unit: $unitId');
    } catch (e) {
      debugPrint('Error sending notification to unit: $e');
    }
  }

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getNotificationsForCurrentUser(
      String userId) async {
    try {
      final db = _database;

      // Get current unit ID from LocalStorageService
      final localStorageService = LocalStorageService();
      final unitId = localStorageService.currentUnitId;

      // Query for user-specific and unit-wide notifications
      final result = await db!.query(
        _notificationsTable,
        where: 'recipientId = ? OR (unitId = ? AND recipientId IS NULL)',
        whereArgs: [userId, unitId],
        orderBy: 'createdAt DESC',
      );

      return result.map((notification) {
        final Map<String, dynamic> notificationData = {...notification};

        // Parse data field
        if (notification['data'] != null) {
          try {
            notificationData['data'] =
                jsonDecode(notification['data'] as String);
          } catch (e) {
            debugPrint('Error parsing notification data: $e');
            notificationData['data'] = {};
          }
        }

        return notificationData;
      }).toList();
    } catch (e) {
      debugPrint('Error getting notifications for user: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final db = _database;

      await db!.update(
        _notificationsTable,
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );

      debugPrint('Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final db = _database;

      // Get current unit ID from LocalStorageService
      final localStorageService = LocalStorageService();
      final unitId = localStorageService.currentUnitId;

      // Query for unread user-specific and unit-wide notifications
      final result = await db!.rawQuery('''
        SELECT COUNT(*) as count FROM $_notificationsTable
        WHERE isRead = 0 AND (recipientId = ? OR (unitId = ? AND recipientId IS NULL))
      ''', [userId, unitId]);

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Handle notification tap
  void handleNotificationTap(Map<String, dynamic> notification) {
    if (_onNotificationTap != null) {
      _onNotificationTap!(notification);
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}
