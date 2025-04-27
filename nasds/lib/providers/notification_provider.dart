import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

/// Provider for managing notifications state
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  List<NotificationGroup> _notificationGroups = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  
  // Stream subscriptions
  StreamSubscription<AppNotification>? _notificationSubscription;
  StreamSubscription<int>? _notificationCountSubscription;
  
  // Getters
  List<AppNotification> get notifications => _notifications;
  List<NotificationGroup> get notificationGroups => _notificationGroups;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  
  // Constructor
  NotificationProvider() {
    _initialize();
  }
  
  // Initialize the provider
  Future<void> _initialize() async {
    _setLoading(true);
    
    // Load notifications
    await _loadNotifications();
    
    // Subscribe to notification streams
    _subscribeToNotificationStreams();
    
    _setLoading(false);
  }
  
  // Load notifications
  Future<void> _loadNotifications() async {
    try {
      _notifications = await _notificationService.getNotifications();
      _unreadCount = await _notificationService.getUnreadCount();
      _groupNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }
  
  // Subscribe to notification streams
  void _subscribeToNotificationStreams() {
    // Subscribe to new notifications
    _notificationSubscription = _notificationService.onNotification.listen((notification) {
      _handleNewNotification(notification);
    });
    
    // Subscribe to notification count changes
    _notificationCountSubscription = _notificationService.onNotificationCountChanged.listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }
  
  // Handle new notification
  void _handleNewNotification(AppNotification notification) {
    // Add to notifications list
    _notifications.add(notification);
    
    // Update groups
    _addToGroup(notification);
    
    // Update unread count
    if (notification.status == NotificationStatus.unread) {
      _unreadCount++;
    }
    
    notifyListeners();
  }
  
  // Group notifications
  void _groupNotifications() {
    final Map<String, List<AppNotification>> groups = {};
    
    // Group by reference ID or type
    for (final notification in _notifications) {
      final String groupKey = notification.groupId ?? 
                             notification.referenceId ?? 
                             notification.type.toString();
      
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      
      groups[groupKey]!.add(notification);
    }
    
    // Create notification groups
    _notificationGroups = groups.entries.map((entry) {
      final notifications = entry.value;
      final firstNotification = notifications.first;
      
      return NotificationGroup(
        id: entry.key,
        title: _getGroupTitle(notifications),
        type: firstNotification.type,
        notifications: notifications,
        createdAt: _getEarliestDate(notifications),
        updatedAt: _getLatestDate(notifications),
      );
    }).toList();
    
    // Sort groups by latest update
    _notificationGroups.sort((a, b) => 
      b.updatedAt!.compareTo(a.updatedAt!)
    );
  }
  
  // Add notification to group
  void _addToGroup(AppNotification notification) {
    final String groupKey = notification.groupId ?? 
                           notification.referenceId ?? 
                           notification.type.toString();
    
    // Find existing group
    final existingGroupIndex = _notificationGroups.indexWhere((group) => 
      group.id == groupKey
    );
    
    if (existingGroupIndex >= 0) {
      // Add to existing group
      final existingGroup = _notificationGroups[existingGroupIndex];
      final updatedNotifications = [...existingGroup.notifications, notification];
      
      _notificationGroups[existingGroupIndex] = existingGroup.copyWith(
        notifications: updatedNotifications,
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new group
      _notificationGroups.add(
        NotificationGroup(
          id: groupKey,
          title: _getSingleNotificationTitle(notification),
          type: notification.type,
          notifications: [notification],
          createdAt: notification.createdAt,
          updatedAt: notification.createdAt,
        )
      );
    }
    
    // Sort groups by latest update
    _notificationGroups.sort((a, b) => 
      b.updatedAt!.compareTo(a.updatedAt!)
    );
  }
  
  // Get group title
  String _getGroupTitle(List<AppNotification> notifications) {
    if (notifications.isEmpty) return 'Notifications';
    
    // If all notifications have the same title, use that
    final firstTitle = notifications.first.title;
    final allSameTitle = notifications.every((n) => n.title == firstTitle);
    
    if (allSameTitle) return firstTitle;
    
    // Otherwise, use type-based title
    final type = notifications.first.type;
    switch (type) {
      case NotificationType.dispatch:
        return 'Dispatch Notifications';
      case NotificationType.security:
        return 'Security Alerts';
      case NotificationType.system:
        return 'System Notifications';
      case NotificationType.user:
        return 'User Notifications';
      case NotificationType.update:
        return 'Updates';
      case NotificationType.alert:
        return 'Alerts';
      default:
        return 'Notifications';
    }
  }
  
  // Get single notification title
  String _getSingleNotificationTitle(AppNotification notification) {
    return notification.title;
  }
  
  // Get earliest date from notifications
  DateTime _getEarliestDate(List<AppNotification> notifications) {
    if (notifications.isEmpty) return DateTime.now();
    
    return notifications.map((n) => n.createdAt).reduce(
      (a, b) => a.isBefore(b) ? a : b
    );
  }
  
  // Get latest date from notifications
  DateTime _getLatestDate(List<AppNotification> notifications) {
    if (notifications.isEmpty) return DateTime.now();
    
    return notifications.map((n) => n.createdAt).reduce(
      (a, b) => a.isAfter(b) ? a : b
    );
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Refresh notifications
  Future<void> refreshNotifications() async {
    _setLoading(true);
    await _loadNotifications();
    _setLoading(false);
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationService.updateNotificationStatus(
      notificationId, 
      NotificationStatus.read
    );
    
    // Update local state
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(
        status: NotificationStatus.read
      );
      
      // Update groups
      _groupNotifications();
      
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
    
    // Update local state
    _notifications = _notifications.map((notification) => 
      notification.copyWith(status: NotificationStatus.read)
    ).toList();
    
    // Update groups
    _groupNotifications();
    
    _unreadCount = 0;
    notifyListeners();
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
    
    // Update local state
    _notifications.removeWhere((n) => n.id == notificationId);
    
    // Update groups
    _groupNotifications();
    
    notifyListeners();
  }
  
  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
    
    // Update local state
    _notifications = [];
    _notificationGroups = [];
    _unreadCount = 0;
    
    notifyListeners();
  }
  
  // Create a notification
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
    final notification = await _notificationService.createNotification(
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
      showImmediately: showImmediately,
    );
    
    return notification;
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
    return _notificationService.createDispatchNotification(
      title: title,
      body: body,
      dispatchId: dispatchId,
      dispatchType: dispatchType,
      priority: priority,
      imageUrl: imageUrl,
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
    return _notificationService.createSecurityNotification(
      title: title,
      body: body,
      priority: priority,
      requiresAuth: requiresAuth,
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
    return _notificationService.createSystemNotification(
      title: title,
      body: body,
      priority: priority,
      payload: payload,
      actions: actions,
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
    return _notificationService.createAlertNotification(
      title: title,
      body: body,
      priority: priority,
      actions: actions,
      showImmediately: showImmediately,
    );
  }
  
  // Get notification history
  Future<List<AppNotification>> getNotificationHistory() async {
    return _notificationService.getNotificationHistory();
  }
  
  // Dispose
  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationCountSubscription?.cancel();
    super.dispose();
  }
}
