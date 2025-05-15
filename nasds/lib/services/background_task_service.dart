import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import '../models/notification.dart';

/// Service for running background tasks
class BackgroundTaskService {
  // Singleton pattern
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  // Services
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  // Timers
  Timer? _notificationTimer;
  Timer? _dispatchSyncTimer;
  Timer? _reportGenerationTimer;
  
  // Last check timestamps
  int _lastNotificationCheck = 0;
  int _lastDispatchSync = 0;
  
  // Initialize background tasks
  Future<void> initialize() async {
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
  
  // Check for new notifications
  Future<void> _checkForNotifications() async {
    if (_firebaseService.currentUnitId == null) return;
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Query for new notifications
      final querySnapshot = await _firebaseService.firestore
          .collection('notifications')
          .where('unitId', isEqualTo: _firebaseService.currentUnitId)
          .where('createdAt', isGreaterThan: _lastNotificationCheck)
          .get();
      
      // Process new notifications
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        await _processNotification(data);
      }
      
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
    if (_firebaseService.currentUnitId == null) return;
    
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Query for updated dispatches
      final querySnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('dispatches')
          .where('lastUpdated', isGreaterThan: _lastDispatchSync)
          .get();
      
      // Process updated dispatches
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final dispatchId = doc.id;
        
        // Add tracking entry if status changed
        if (data.containsKey('status')) {
          await _firebaseService.firestore
              .collection('units')
              .doc(_firebaseService.currentUnitId)
              .collection('dispatches')
              .doc(dispatchId)
              .collection('tracking')
              .add({
            'status': data['status'],
            'timestamp': now,
            'notes': 'Status updated via sync',
            'location': data['currentLocation'] ?? '',
            'handlerId': data['currentHandler'] ?? '',
          });
        }
      }
      
      // Update last sync timestamp
      _lastDispatchSync = now;
    } catch (e) {
      debugPrint('Error syncing dispatches: $e');
    }
  }
  
  // Generate daily report
  Future<void> _generateDailyReport() async {
    if (_firebaseService.currentUnitId == null) return;
    
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      yesterday.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      
      final today = DateTime.now();
      today.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      
      // Query for dispatches from yesterday
      final querySnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('dispatches')
          .where('dateTime', isGreaterThanOrEqualTo: yesterday.millisecondsSinceEpoch)
          .where('dateTime', isLessThan: today.millisecondsSinceEpoch)
          .get();
      
      // Generate report data
      final reportData = {
        'date': yesterday.toIso8601String(),
        'unitId': _firebaseService.currentUnitId,
        'totalDispatches': querySnapshot.size,
        'incomingCount': 0,
        'outgoingCount': 0,
        'localCount': 0,
        'externalCount': 0,
        'completedCount': 0,
        'pendingCount': 0,
      };
      
      // Calculate statistics
      for (final doc in querySnapshot.docs) {
        final dispatch = doc.data();
        
        if (dispatch['type'] == 'incoming') reportData['incomingCount'] = (reportData['incomingCount'] as int) + 1;
        if (dispatch['type'] == 'outgoing') reportData['outgoingCount'] = (reportData['outgoingCount'] as int) + 1;
        if (dispatch['type'] == 'local') reportData['localCount'] = (reportData['localCount'] as int) + 1;
        if (dispatch['type'] == 'external') reportData['externalCount'] = (reportData['externalCount'] as int) + 1;
        
        if (dispatch['status'] == 'completed' || dispatch['status'] == 'delivered') {
          reportData['completedCount'] = (reportData['completedCount'] as int) + 1;
        } else {
          reportData['pendingCount'] = (reportData['pendingCount'] as int) + 1;
        }
      }
      
      // Save report to Firestore
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('reports')
          .add({
        ...reportData,
        'generatedAt': DateTime.now().millisecondsSinceEpoch,
        'type': 'daily',
      });
      
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
