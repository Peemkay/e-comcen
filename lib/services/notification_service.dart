import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification.dart';
import 'security_service.dart';
import 'settings_service.dart';

/// Service for managing notifications in the application
class NotificationService {
  static const String _notificationsKey = 'notifications';
  static const String _notificationGroupsKey = 'notification_groups';
  static const String _lastNotificationIdKey = 'last_notification_id';
  static const String _notificationHistoryFile = 'notification_history.json';

  final SecurityService _securityService = SecurityService();
  final SettingsService _settingsService = SettingsService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Stream controllers for notification events
  final _notificationStreamController =
      StreamController<AppNotification>.broadcast();
  final _notificationCountStreamController = StreamController<int>.broadcast();

  // Notification streams
  Stream<AppNotification> get onNotification =>
      _notificationStreamController.stream;
  Stream<int> get onNotificationCountChanged =>
      _notificationCountStreamController.stream;

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  // Factory constructor
  factory NotificationService() {
    return _instance;
  }

  // Private constructor
  NotificationService._internal();

  // Initialize the service
  Future<void> initialize() async {
    // Load notifications from storage
    await _loadNotifications();

    // Start notification scheduler
    _startNotificationScheduler();

    // Update notification count
    _updateNotificationCount();
  }

  // Dispose resources
  void dispose() {
    _notificationStreamController.close();
    _notificationCountStreamController.close();
  }

  // Get all notifications
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

    return notificationsJson.map((json) {
      final Map<String, dynamic> data = jsonDecode(json);
      return AppNotification.fromJson(data);
    }).toList();
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications
        .where((n) => n.status == NotificationStatus.unread)
        .length;
  }

  // Update notification count
  Future<void> _updateNotificationCount() async {
    final count = await getUnreadCount();
    _notificationCountStreamController.add(count);
  }

  // Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      // Process any scheduled notifications
      final now = DateTime.now();
      for (final json in notificationsJson) {
        final Map<String, dynamic> data = jsonDecode(json);
        final notification = AppNotification.fromJson(data);

        // Check if notification is scheduled and ready to be shown
        if (notification.scheduledFor != null &&
            notification.scheduledFor!.isBefore(now) &&
            notification.status == NotificationStatus.unread) {
          _notificationStreamController.add(notification);
        }
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  // Start notification scheduler
  void _startNotificationScheduler() {
    // Check for scheduled notifications every minute
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      final notifications = await getNotifications();
      final now = DateTime.now();

      for (final notification in notifications) {
        if (notification.scheduledFor != null &&
            notification.scheduledFor!.isBefore(now) &&
            notification.status == NotificationStatus.unread) {
          // Show the notification
          _notificationStreamController.add(notification);

          // Update the notification status
          await updateNotificationStatus(
              notification.id, NotificationStatus.unread);
        }
      }
    });
  }

  // Generate a unique notification ID
  Future<String> _generateNotificationId() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_lastNotificationIdKey) ?? 0;
    final newId = lastId + 1;
    await prefs.setInt(_lastNotificationIdKey, newId);
    return 'notification_$newId';
  }

  // Create and show a notification
  Future<AppNotification> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool isEncrypted = false,
    String? groupId,
    String? referenceId,
    String? senderId,
    String? senderName,
    bool requiresAuth = false,
    bool isSystemNotification = false,
    bool showImmediately = true,
  }) async {
    // Check notification settings
    final settings = await _settingsService.getNotificationSettings();

    // Check if notifications are enabled for this type
    if (!_isNotificationTypeEnabled(type, settings)) {
      debugPrint('Notifications of type $type are disabled');
      return await _saveNotificationWithoutShowing(
        title: title,
        body: body,
        type: type,
        priority: priority,
        scheduledFor: scheduledFor,
        expiresAt: expiresAt,
        imageUrl: imageUrl,
        deepLink: deepLink,
        payload: payload,
        actions: actions,
        isEncrypted: isEncrypted,
        groupId: groupId,
        referenceId: referenceId,
        senderId: senderId,
        senderName: senderName,
        requiresAuth: requiresAuth,
        isSystemNotification: isSystemNotification,
      );
    }

    // Check Do Not Disturb settings
    if (settings.enableDoNotDisturb && !isSystemNotification) {
      final now = TimeOfDay.now();
      final startTime = settings.doNotDisturbStart;
      final endTime = settings.doNotDisturbEnd;

      // Convert to minutes for easier comparison
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      bool isDuringDoNotDisturb = false;

      // Handle cases where DND period crosses midnight
      if (startMinutes > endMinutes) {
        // e.g., 22:00 to 07:00
        isDuringDoNotDisturb =
            nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      } else {
        // e.g., 08:00 to 17:00
        isDuringDoNotDisturb =
            nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      }

      if (isDuringDoNotDisturb && priority != NotificationPriority.urgent) {
        // Schedule the notification for after DND period
        final newScheduledFor = _calculateEndOfDoNotDisturb(endTime);
        scheduledFor = newScheduledFor;
        showImmediately = false;
      }
    }

    // Generate a unique ID for the notification
    final id = await _generateNotificationId();

    // Create the notification object
    final notification = AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      priority: priority,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      expiresAt: expiresAt,
      imageUrl: imageUrl,
      deepLink: deepLink,
      payload: payload,
      actions: actions,
      isEncrypted: isEncrypted,
      groupId: groupId,
      referenceId: referenceId,
      senderId: senderId,
      senderName: senderName,
      requiresAuth: requiresAuth,
      isSystemNotification: isSystemNotification,
    );

    // Save the notification
    await _saveNotification(notification);

    // Show the notification immediately if needed
    if (showImmediately &&
        (scheduledFor == null || scheduledFor.isBefore(DateTime.now()))) {
      await _showNotification(notification);
    }

    // Update notification count
    _updateNotificationCount();

    return notification;
  }

  // Save a notification without showing it
  Future<AppNotification> _saveNotificationWithoutShowing({
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool isEncrypted = false,
    String? groupId,
    String? referenceId,
    String? senderId,
    String? senderName,
    bool requiresAuth = false,
    bool isSystemNotification = false,
  }) async {
    // Generate a unique ID for the notification
    final id = await _generateNotificationId();

    // Create the notification object
    final notification = AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      priority: priority,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      expiresAt: expiresAt,
      imageUrl: imageUrl,
      deepLink: deepLink,
      payload: payload,
      actions: actions,
      isEncrypted: isEncrypted,
      groupId: groupId,
      referenceId: referenceId,
      senderId: senderId,
      senderName: senderName,
      requiresAuth: requiresAuth,
      isSystemNotification: isSystemNotification,
    );

    // Save the notification
    await _saveNotification(notification);

    // Update notification count
    _updateNotificationCount();

    return notification;
  }

  // Save a notification to storage
  Future<void> _saveNotification(AppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      // Convert notification to JSON
      final notificationJson = jsonEncode(notification.toJson());

      // Add to list
      notificationsJson.add(notificationJson);

      // Save to SharedPreferences
      await prefs.setStringList(_notificationsKey, notificationsJson);

      // If notification is encrypted, save the encrypted content separately
      if (notification.isEncrypted) {
        final encryptedTitle = _securityService.encryptData(notification.title);
        final encryptedBody = _securityService.encryptData(notification.body);

        await _secureStorage.write(
          key: 'notification_title_${notification.id}',
          value: encryptedTitle,
        );

        await _secureStorage.write(
          key: 'notification_body_${notification.id}',
          value: encryptedBody,
        );
      }

      // Add to notification history
      await _addToNotificationHistory(notification);
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  // Show a notification
  Future<void> _showNotification(AppNotification notification) async {
    try {
      // Check if notification is expired
      if (notification.expiresAt != null &&
          notification.expiresAt!.isBefore(DateTime.now())) {
        return;
      }

      // Check if notification requires authentication
      if (notification.requiresAuth) {
        // Check if user is authenticated
        try {
          final securityService = SecurityService();
          final isAuthenticated =
              await securityService.initialize().then((_) => true);
          if (!isAuthenticated) {
            // Save for later when user authenticates
            return;
          }
        } catch (e) {
          debugPrint('Error checking authentication: $e');
          return;
        }
      }

      // If notification is encrypted, we'll decrypt it when displaying
      // This is handled by the notification manager when displaying the notification

      // Show the notification based on platform
      if (Platform.isWindows) {
        // For Windows, use the notification stream for in-app notifications
        _notificationStreamController.add(notification);
      } else {
        // For other platforms, use platform-specific notification APIs
        // This is a placeholder for future implementation
        debugPrint('Showing notification on non-Windows platform');
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Add notification to history
  Future<void> _addToNotificationHistory(AppNotification notification) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_notificationHistoryFile');

      // Create file if it doesn't exist
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(jsonEncode([]));
      }

      // Read existing history
      final historyJson = await file.readAsString();
      final List<dynamic> history = jsonDecode(historyJson);

      // Add new notification to history
      history.add(notification.toJson());

      // Limit history size (keep last 100 notifications)
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }

      // Write updated history
      await file.writeAsString(jsonEncode(history));
    } catch (e) {
      debugPrint('Error adding notification to history: $e');
    }
  }

  // Get notification history
  Future<List<AppNotification>> getNotificationHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_notificationHistoryFile');

      if (!await file.exists()) {
        return [];
      }

      final historyJson = await file.readAsString();
      final List<dynamic> history = jsonDecode(historyJson);

      return history.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      return [];
    }
  }

  // Update notification status
  Future<void> updateNotificationStatus(
      String notificationId, NotificationStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedNotifications = <String>[];

      for (final json in notificationsJson) {
        final Map<String, dynamic> data = jsonDecode(json);
        final notification = AppNotification.fromJson(data);

        if (notification.id == notificationId) {
          // Update status
          final updatedNotification = notification.copyWith(status: status);
          updatedNotifications.add(jsonEncode(updatedNotification.toJson()));
        } else {
          updatedNotifications.add(json);
        }
      }

      // Save updated notifications
      await prefs.setStringList(_notificationsKey, updatedNotifications);

      // Update notification count
      _updateNotificationCount();
    } catch (e) {
      debugPrint('Error updating notification status: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedNotifications = <String>[];

      for (final json in notificationsJson) {
        final Map<String, dynamic> data = jsonDecode(json);
        final notification = AppNotification.fromJson(data);

        if (notification.status == NotificationStatus.unread) {
          // Update status
          final updatedNotification =
              notification.copyWith(status: NotificationStatus.read);
          updatedNotifications.add(jsonEncode(updatedNotification.toJson()));
        } else {
          updatedNotifications.add(json);
        }
      }

      // Save updated notifications
      await prefs.setStringList(_notificationsKey, updatedNotifications);

      // Update notification count
      _updateNotificationCount();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final updatedNotifications = <String>[];

      for (final json in notificationsJson) {
        final Map<String, dynamic> data = jsonDecode(json);
        final notification = AppNotification.fromJson(data);

        if (notification.id != notificationId) {
          updatedNotifications.add(json);
        }
      }

      // Save updated notifications
      await prefs.setStringList(_notificationsKey, updatedNotifications);

      // Delete encrypted content if exists
      await _secureStorage.delete(key: 'notification_title_$notificationId');
      await _secureStorage.delete(key: 'notification_body_$notificationId');

      // Update notification count
      _updateNotificationCount();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);

      // Update notification count
      _updateNotificationCount();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // Check if notification type is enabled in settings
  bool _isNotificationTypeEnabled(
      NotificationType type, NotificationSettings settings) {
    if (!settings.enablePushNotifications) {
      return false;
    }

    switch (type) {
      case NotificationType.dispatch:
        return settings.notifyNewDispatch ||
            settings.notifyDispatchUpdates ||
            settings.notifyDispatchDelivered ||
            settings.notifyDispatchDelayed;
      case NotificationType.security:
        return settings.notifySecurityAlerts;
      case NotificationType.system:
        return settings.notifySystemUpdates;
      case NotificationType.alert:
        return true; // Always show alerts
      default:
        return true;
    }
  }

  // Calculate end of Do Not Disturb period
  DateTime _calculateEndOfDoNotDisturb(TimeOfDay endTime) {
    final now = DateTime.now();
    final endDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    // If end time is before current time, it means it's for tomorrow
    if (endDateTime.isBefore(now)) {
      return endDateTime.add(const Duration(days: 1));
    }

    return endDateTime;
  }

  // Create a dispatch notification
  Future<AppNotification> createDispatchNotification({
    required String title,
    required String body,
    required String dispatchId,
    required String dispatchType,
    NotificationPriority priority = NotificationPriority.normal,
    String? imageUrl,
    String? senderId,
    String? senderName,
    bool showImmediately = true,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: NotificationType.dispatch,
      priority: priority,
      imageUrl: imageUrl,
      deepLink: 'dispatch/$dispatchId',
      payload: {
        'dispatchId': dispatchId,
        'dispatchType': dispatchType,
      },
      actions: [
        NotificationAction(
          id: 'view',
          label: 'View Details',
          icon: 'visibility',
          isDefault: true,
        ),
        NotificationAction(
          id: 'dismiss',
          label: 'Dismiss',
          icon: 'close',
        ),
      ],
      referenceId: dispatchId,
      senderId: senderId,
      senderName: senderName,
      showImmediately: showImmediately,
    );
  }

  // Create a security notification
  Future<AppNotification> createSecurityNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.high,
    bool requiresAuth = true,
    bool showImmediately = true,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: NotificationType.security,
      priority: priority,
      isEncrypted: true,
      requiresAuth: requiresAuth,
      isSystemNotification: true,
      actions: [
        NotificationAction(
          id: 'acknowledge',
          label: 'Acknowledge',
          icon: 'check',
          isDefault: true,
        ),
      ],
      showImmediately: showImmediately,
    );
  }

  // Create a system notification
  Future<AppNotification> createSystemNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool showImmediately = true,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: NotificationType.system,
      priority: priority,
      payload: payload,
      actions: actions,
      isSystemNotification: true,
      showImmediately: showImmediately,
    );
  }

  // Create an alert notification
  Future<AppNotification> createAlertNotification({
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.urgent,
    List<NotificationAction>? actions,
    bool showImmediately = true,
  }) async {
    return createNotification(
      title: title,
      body: body,
      type: NotificationType.alert,
      priority: priority,
      actions: actions ??
          [
            NotificationAction(
              id: 'acknowledge',
              label: 'Acknowledge',
              icon: 'check',
              isDefault: true,
            ),
          ],
      isSystemNotification: true,
      showImmediately: showImmediately,
    );
  }
}
