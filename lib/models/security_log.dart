import 'package:flutter/material.dart';

/// Types of security events that can be logged
enum SecurityEventType {
  // Authentication events
  loginSuccess,
  loginFailed,
  logoutSuccess,
  passwordChanged,
  passwordReset,
  accountLocked,
  accountUnlocked,

  // Session events
  sessionStarted,
  sessionEnded,
  sessionTimeout,
  sessionRenewed,

  // Data events
  dataAccessed,
  dataModified,
  dataDeleted,
  dataExported,
  dataImported,
  encryptionSuccess,
  encryptionFailed,
  decryptionSuccess,
  decryptionFailed,

  // Device events
  deviceAuthorized,
  deviceUnauthorized,
  deviceCompromised,
  developerModeEnabled,
  unauthorizedDevice,

  // Network events
  networkConnection,
  networkDisconnection,
  secureConnectionEstablished,
  insecureConnectionDetected,

  // System events
  appStarted,
  appClosed,
  appCrashed,
  appUpdated,
  systemError,

  // Security check events
  securityCheckPassed,
  securityCheckFailed,
  networkCheckFailed,

  // User actions
  userCreated,
  userModified,
  userDeleted,
  permissionChanged,

  // Dispatch events
  dispatchCreated,
  dispatchModified,
  dispatchDeleted,
  dispatchViewed,

  // Other events
  logout,
  other,
}

/// Extension to get string representation of security event types
extension SecurityEventTypeExtension on SecurityEventType {
  String get name {
    return toString().split('.').last;
  }

  String get displayName {
    final name = toString().split('.').last;
    final result = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    );
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  IconData get icon {
    switch (this) {
      case SecurityEventType.loginSuccess:
      case SecurityEventType.logoutSuccess:
      case SecurityEventType.sessionStarted:
      case SecurityEventType.sessionEnded:
        return Icons.login;

      case SecurityEventType.loginFailed:
      case SecurityEventType.accountLocked:
      case SecurityEventType.securityCheckFailed:
      case SecurityEventType.networkCheckFailed:
        return Icons.error;

      case SecurityEventType.passwordChanged:
      case SecurityEventType.passwordReset:
        return Icons.password;

      case SecurityEventType.dataAccessed:
      case SecurityEventType.dataModified:
      case SecurityEventType.dataDeleted:
      case SecurityEventType.dataExported:
      case SecurityEventType.dataImported:
        return Icons.data_usage;

      case SecurityEventType.deviceAuthorized:
      case SecurityEventType.deviceUnauthorized:
      case SecurityEventType.deviceCompromised:
      case SecurityEventType.developerModeEnabled:
      case SecurityEventType.unauthorizedDevice:
        return Icons.devices;

      case SecurityEventType.networkConnection:
      case SecurityEventType.networkDisconnection:
      case SecurityEventType.secureConnectionEstablished:
      case SecurityEventType.insecureConnectionDetected:
        return Icons.network_check;

      case SecurityEventType.appStarted:
      case SecurityEventType.appClosed:
      case SecurityEventType.appCrashed:
      case SecurityEventType.appUpdated:
      case SecurityEventType.systemError:
        return Icons.app_settings_alt;

      case SecurityEventType.dispatchCreated:
      case SecurityEventType.dispatchModified:
      case SecurityEventType.dispatchDeleted:
      case SecurityEventType.dispatchViewed:
        return Icons.send;

      default:
        return Icons.security;
    }
  }

  Color get color {
    switch (this) {
      case SecurityEventType.loginSuccess:
      case SecurityEventType.logoutSuccess:
      case SecurityEventType.passwordChanged:
      case SecurityEventType.accountUnlocked:
      case SecurityEventType.securityCheckPassed:
      case SecurityEventType.deviceAuthorized:
      case SecurityEventType.secureConnectionEstablished:
        return Colors.green;

      case SecurityEventType.loginFailed:
      case SecurityEventType.accountLocked:
      case SecurityEventType.deviceCompromised:
      case SecurityEventType.deviceUnauthorized:
      case SecurityEventType.unauthorizedDevice:
      case SecurityEventType.insecureConnectionDetected:
      case SecurityEventType.securityCheckFailed:
      case SecurityEventType.networkCheckFailed:
      case SecurityEventType.encryptionFailed:
      case SecurityEventType.decryptionFailed:
      case SecurityEventType.appCrashed:
      case SecurityEventType.systemError:
        return Colors.red;

      case SecurityEventType.sessionTimeout:
      case SecurityEventType.developerModeEnabled:
      case SecurityEventType.passwordReset:
        return Colors.orange;

      default:
        return Colors.blue;
    }
  }
}

/// Security log model to track security-related events
class SecurityLog {
  final DateTime timestamp;
  final SecurityEventType type;
  final String details;
  final String? userId;
  final String? deviceInfo;
  final String? ipAddress;

  SecurityLog({
    required this.timestamp,
    required this.type,
    required this.details,
    this.userId,
    this.deviceInfo,
    this.ipAddress,
  });

  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      timestamp: DateTime.parse(json['timestamp']),
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SecurityEventType.other,
      ),
      details: json['details'],
      userId: json['userId'],
      deviceInfo: json['deviceInfo'],
      ipAddress: json['ipAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'details': details,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] ${type.displayName}: $details';
  }
}
