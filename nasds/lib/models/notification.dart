import 'package:flutter/material.dart';
import 'dart:convert';

/// Enum defining different types of notifications
enum NotificationType {
  dispatch,
  security,
  system,
  user,
  update,
  alert,
}

/// Enum defining notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Enum defining notification status
enum NotificationStatus {
  unread,
  read,
  archived,
  deleted,
}

/// Extension to provide additional functionality to NotificationType
extension NotificationTypeExtension on NotificationType {
  /// Get the display name of the notification type
  String get displayName {
    switch (this) {
      case NotificationType.dispatch:
        return 'Dispatch';
      case NotificationType.security:
        return 'Security';
      case NotificationType.system:
        return 'System';
      case NotificationType.user:
        return 'User';
      case NotificationType.update:
        return 'Update';
      case NotificationType.alert:
        return 'Alert';
    }
  }

  /// Get the icon for the notification type
  IconData get icon {
    switch (this) {
      case NotificationType.dispatch:
        return Icons.local_shipping;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.user:
        return Icons.person;
      case NotificationType.update:
        return Icons.update;
      case NotificationType.alert:
        return Icons.warning;
    }
  }

  /// Get the color for the notification type
  Color get color {
    switch (this) {
      case NotificationType.dispatch:
        return Colors.blue;
      case NotificationType.security:
        return Colors.red;
      case NotificationType.system:
        return Colors.purple;
      case NotificationType.user:
        return Colors.green;
      case NotificationType.update:
        return Colors.orange;
      case NotificationType.alert:
        return Colors.amber;
    }
  }
}

/// Extension to provide additional functionality to NotificationPriority
extension NotificationPriorityExtension on NotificationPriority {
  /// Get the display name of the priority level
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get the color for the priority level
  Color get color {
    switch (this) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  /// Get the icon for the priority level
  IconData get icon {
    switch (this) {
      case NotificationPriority.low:
        return Icons.arrow_downward;
      case NotificationPriority.normal:
        return Icons.arrow_forward;
      case NotificationPriority.high:
        return Icons.arrow_upward;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }
}

/// Extension to provide additional functionality to NotificationStatus
extension NotificationStatusExtension on NotificationStatus {
  /// Get the display name of the status
  String get displayName {
    switch (this) {
      case NotificationStatus.unread:
        return 'Unread';
      case NotificationStatus.read:
        return 'Read';
      case NotificationStatus.archived:
        return 'Archived';
      case NotificationStatus.deleted:
        return 'Deleted';
    }
  }

  /// Get the icon for the status
  IconData get icon {
    switch (this) {
      case NotificationStatus.unread:
        return Icons.mark_email_unread;
      case NotificationStatus.read:
        return Icons.mark_email_read;
      case NotificationStatus.archived:
        return Icons.archive;
      case NotificationStatus.deleted:
        return Icons.delete;
    }
  }
}

/// Model class for notification actions
class NotificationAction {
  final String id;
  final String label;
  final String? icon;
  final Map<String, dynamic>? data;
  final bool isDestructive;
  final bool isDefault;

  NotificationAction({
    required this.id,
    required this.label,
    this.icon,
    this.data,
    this.isDestructive = false,
    this.isDefault = false,
  });

  /// Create from JSON
  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'],
      label: json['label'],
      icon: json['icon'],
      data: json['data'],
      isDestructive: json['isDestructive'] ?? false,
      isDefault: json['isDefault'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
      'data': data,
      'isDestructive': isDestructive,
      'isDefault': isDefault,
    };
  }
}

/// Model class for notifications
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final String? imageUrl;
  final String? deepLink;
  final Map<String, dynamic>? payload;
  final List<NotificationAction>? actions;
  final bool isEncrypted;
  final String? groupId;
  final String? referenceId;
  final String? senderId;
  final String? senderName;
  final bool requiresAuth;
  final bool isSystemNotification;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.scheduledFor,
    this.expiresAt,
    this.imageUrl,
    this.deepLink,
    this.payload,
    this.actions,
    this.isEncrypted = false,
    this.groupId,
    this.referenceId,
    this.senderId,
    this.senderName,
    this.requiresAuth = false,
    this.isSystemNotification = false,
  });

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    String? imageUrl,
    String? deepLink,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool? isEncrypted,
    String? groupId,
    String? referenceId,
    String? senderId,
    String? senderName,
    bool? requiresAuth,
    bool? isSystemNotification,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      payload: payload ?? this.payload,
      actions: actions ?? this.actions,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      groupId: groupId ?? this.groupId,
      referenceId: referenceId ?? this.referenceId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      isSystemNotification: isSystemNotification ?? this.isSystemNotification,
    );
  }

  /// Create from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${json['priority']}',
        orElse: () => NotificationPriority.normal,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == 'NotificationStatus.${json['status']}',
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      imageUrl: json['imageUrl'],
      deepLink: json['deepLink'],
      payload: json['payload'],
      actions: json['actions'] != null
          ? List<NotificationAction>.from(
              json['actions'].map((x) => NotificationAction.fromJson(x)))
          : null,
      isEncrypted: json['isEncrypted'] ?? false,
      groupId: json['groupId'],
      referenceId: json['referenceId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      requiresAuth: json['requiresAuth'] ?? false,
      isSystemNotification: json['isSystemNotification'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'payload': payload,
      'actions': actions?.map((x) => x.toJson()).toList(),
      'isEncrypted': isEncrypted,
      'groupId': groupId,
      'referenceId': referenceId,
      'senderId': senderId,
      'senderName': senderName,
      'requiresAuth': requiresAuth,
      'isSystemNotification': isSystemNotification,
    };
  }

  /// Check if the notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the notification is scheduled for the future
  bool get isScheduled {
    if (scheduledFor == null) return false;
    return DateTime.now().isBefore(scheduledFor!);
  }

  /// Check if the notification is ready to be shown
  bool get isReady {
    return !isExpired && !isScheduled;
  }

  /// Get the time elapsed since the notification was created
  String get timeElapsed {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a dispatch notification
  static AppNotification createDispatchNotification({
    required String id,
    required String title,
    required String body,
    required String dispatchId,
    required String dispatchType,
    NotificationPriority priority = NotificationPriority.normal,
    String? imageUrl,
    String? senderId,
    String? senderName,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: NotificationType.dispatch,
      priority: priority,
      createdAt: DateTime.now(),
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
    );
  }

  /// Create a security notification
  static AppNotification createSecurityNotification({
    required String id,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.high,
    bool requiresAuth = true,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: NotificationType.security,
      priority: priority,
      createdAt: DateTime.now(),
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
    );
  }

  /// Create a system notification
  static AppNotification createSystemNotification({
    required String id,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: NotificationType.system,
      priority: priority,
      createdAt: DateTime.now(),
      payload: payload,
      actions: actions,
      isSystemNotification: true,
    );
  }
}

/// Model class for notification group
class NotificationGroup {
  final String id;
  final String title;
  final NotificationType type;
  final List<AppNotification> notifications;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isCollapsed;

  NotificationGroup({
    required this.id,
    required this.title,
    required this.type,
    required this.notifications,
    required this.createdAt,
    this.updatedAt,
    this.isCollapsed = false,
  });

  /// Create from JSON
  factory NotificationGroup.fromJson(Map<String, dynamic> json) {
    return NotificationGroup(
      id: json['id'],
      title: json['title'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.system,
      ),
      notifications: List<AppNotification>.from(
        json['notifications'].map((x) => AppNotification.fromJson(x)),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'notifications': notifications.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isCollapsed': isCollapsed,
    };
  }

  /// Get the count of unread notifications in the group
  int get unreadCount {
    return notifications
        .where((notification) => notification.status == NotificationStatus.unread)
        .length;
  }

  /// Get the latest notification in the group
  AppNotification? get latestNotification {
    if (notifications.isEmpty) return null;
    return notifications.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  /// Create a copy with updated fields
  NotificationGroup copyWith({
    String? id,
    String? title,
    NotificationType? type,
    List<AppNotification>? notifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCollapsed,
  }) {
    return NotificationGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      notifications: notifications ?? this.notifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}
