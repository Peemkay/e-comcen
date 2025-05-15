import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import '../models/notification.dart';

/// Service for running background tasks
class BackgroundTaskService {
  // Singleton pattern
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  // Services
  final LocalStorageService _localStorageService = LocalStorageService();
  final NotificationService _notificationService = NotificationService();

  // Database
  Database? _database;
  final String _dispatchesTable = 'dispatches';
  final String _notificationsTable = 'notifications';
  final String _reportsTable = 'reports';

  // Timers
  Timer? _notificationTimer;
  Timer? _dispatchSyncTimer;
  Timer? _reportGenerationTimer;

  // Last check timestamps
  int _lastNotificationCheck = 0;
  int _lastDispatchSync = 0;

  // Initialize background tasks
  Future<void> initialize() async {
    // Initialize database
    await _initDatabase();

    // Start notification check timer (every 30 seconds)
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForNotifications();
    });

    // Start dispatch sync timer (every 1 minute)
    _dispatchSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _syncDispatches();
    });

    // Start report generation timer (every 24 hours)
    _reportGenerationTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _generateDailyReport();
    });

    debugPrint('Background tasks initialized');
  }

  /// Initialize the SQLite database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    // Get the database path
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'nasds_background.db');

    // Open the database
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create reports table
        await db.execute('''
          CREATE TABLE $_reportsTable (
            id TEXT PRIMARY KEY,
            date TEXT,
            unitId TEXT,
            totalDispatches INTEGER,
            incomingCount INTEGER,
            outgoingCount INTEGER,
            localCount INTEGER,
            externalCount INTEGER,
            completedCount INTEGER,
            pendingCount INTEGER,
            generatedAt INTEGER,
            type TEXT
          )
        ''');
      },
    );
  }

  // Check for new notifications
  Future<void> _checkForNotifications() async {
    if (_localStorageService.currentUnitId == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Get database from LocalStorageService
      final db = _database;
      if (db == null) return;

      // Query for new notifications (simulated for local implementation)
      // In a real implementation, this would query a remote database

      // Update last check timestamp
      _lastNotificationCheck = now;
    } catch (e) {
      debugPrint('Error checking for notifications: $e');
    }
  }

  // Process notification
  Future<void> _processNotification(Map<String, dynamic> data) async {
    final title = data['title'] ?? 'E-COMCEN';
    final body = data['body'] ?? '';

    // Determine notification type
    NotificationType type = NotificationType.system;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'dispatch':
          type = NotificationType.dispatch;
          break;
        case 'security':
          type = NotificationType.security;
          break;
        case 'alert':
          type = NotificationType.alert;
          break;
        default:
          type = NotificationType.system;
      }
    }

    // Determine priority
    NotificationPriority priority = NotificationPriority.normal;
    if (data.containsKey('priority')) {
      switch (data['priority']) {
        case 'low':
          priority = NotificationPriority.low;
          break;
        case 'high':
          priority = NotificationPriority.high;
          break;
        case 'urgent':
          priority = NotificationPriority.urgent;
          break;
        default:
          priority = NotificationPriority.normal;
      }
    }

    // Create notification based on type
    switch (type) {
      case NotificationType.dispatch:
        if (data.containsKey('dispatchId')) {
          await _notificationService.createDispatchNotification(
            title: title,
            body: body,
            dispatchId: data['dispatchId'],
            dispatchType: data['dispatchType'] ?? 'unknown',
            priority: priority,
            senderId: data['senderId'],
            senderName: data['senderName'],
          );
        }
        break;
      case NotificationType.security:
        await _notificationService.createSecurityNotification(
          title: title,
          body: body,
          priority: priority,
        );
        break;
      case NotificationType.alert:
        await _notificationService.createAlertNotification(
          title: title,
          body: body,
          priority: priority,
        );
        break;
      default:
        await _notificationService.createSystemNotification(
          title: title,
          body: body,
          priority: priority,
          payload: data['data'],
        );
    }
  }

  // Sync dispatches between main app and dispatcher app
  Future<void> _syncDispatches() async {
    if (_localStorageService.currentUnitId == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // In a local implementation, this would query the local database
      // and update any changed dispatches

      // Update last sync timestamp
      _lastDispatchSync = now;
    } catch (e) {
      debugPrint('Error syncing dispatches: $e');
    }
  }

  // Generate daily report
  Future<void> _generateDailyReport() async {
    if (_localStorageService.currentUnitId == null) return;

    try {
      final db = _database;
      if (db == null) return;

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      yesterday.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

      final today = DateTime.now();
      today.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);

      // Generate report data (simulated for local implementation)
      final reportData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'date': yesterday.toIso8601String(),
        'unitId': _localStorageService.currentUnitId,
        'totalDispatches': 0,
        'incomingCount': 0,
        'outgoingCount': 0,
        'localCount': 0,
        'externalCount': 0,
        'completedCount': 0,
        'pendingCount': 0,
        'generatedAt': DateTime.now().millisecondsSinceEpoch,
        'type': 'daily',
      };

      // Save report to local database
      await db.insert(_reportsTable, reportData);

      debugPrint('Generated daily report');
    } catch (e) {
      debugPrint('Error generating daily report: $e');
    }
  }

  // Dispose background tasks
  void dispose() {
    _notificationTimer?.cancel();
    _dispatchSyncTimer?.cancel();
    _reportGenerationTimer?.cancel();
  }
}
