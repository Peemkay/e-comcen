import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import 'notification_popup.dart';

/// Widget that manages displaying notifications in the app
class NotificationManager extends StatefulWidget {
  final Widget child;
  
  const NotificationManager({
    super.key,
    required this.child,
  });
  
  @override
  State<NotificationManager> createState() => _NotificationManagerState();
}

class _NotificationManagerState extends State<NotificationManager> {
  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService = SettingsService();
  
  StreamSubscription<AppNotification>? _notificationSubscription;
  final List<AppNotification> _activeNotifications = [];
  
  @override
  void initState() {
    super.initState();
    _subscribeToNotifications();
  }
  
  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
  
  // Subscribe to notifications
  void _subscribeToNotifications() {
    _notificationSubscription = _notificationService.onNotification.listen((notification) {
      _showNotification(notification);
    });
  }
  
  // Show notification
  Future<void> _showNotification(AppNotification notification) async {
    // Check notification settings
    final settings = await _settingsService.getNotificationSettings();
    
    // Skip if notifications are disabled
    if (!settings.enablePushNotifications) {
      return;
    }
    
    // Add to active notifications
    setState(() {
      _activeNotifications.add(notification);
    });
    
    // Play sound if enabled
    if (settings.enableSoundAlerts) {
      // TODO: Implement sound playback
    }
  }
  
  // Remove notification
  void _removeNotification(String notificationId) {
    setState(() {
      _activeNotifications.removeWhere((n) => n.id == notificationId);
    });
  }
  
  // Handle notification tap
  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    Provider.of<NotificationProvider>(context, listen: false)
        .markAsRead(notification.id);
    
    // Remove from active notifications
    _removeNotification(notification.id);
    
    // Handle deep link if present
    if (notification.deepLink != null) {
      // TODO: Implement deep linking
    } else {
      // Navigate to notification center
      Navigator.pushNamed(context, '/notifications');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        widget.child,
        
        // Notification popups
        ..._activeNotifications.map((notification) {
          return NotificationPopup(
            key: Key('popup_${notification.id}'),
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _removeNotification(notification.id),
            displayDuration: _getDisplayDuration(notification.priority),
          );
        }),
      ],
    );
  }
  
  // Get display duration based on priority
  Duration _getDisplayDuration(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return const Duration(seconds: 3);
      case NotificationPriority.normal:
        return const Duration(seconds: 5);
      case NotificationPriority.high:
        return const Duration(seconds: 7);
      case NotificationPriority.urgent:
        return const Duration(seconds: 10);
    }
  }
}
