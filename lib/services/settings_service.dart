import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing application settings
class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Keys for shared preferences
  static const String _systemSettingsKey = 'system_settings';
  static const String _securitySettingsKey = 'security_settings';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _versionHistoryKey = 'version_history';

  // Get system settings
  Future<SystemSettings> getSystemSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_systemSettingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        return SystemSettings.fromJson(settingsMap);
      }
    } catch (e) {
      // If there's an error, return default settings
      print('Error loading system settings: $e');
    }

    // Return default settings
    return SystemSettings.defaults();
  }

  // Save system settings
  Future<void> saveSystemSettings(SystemSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String settingsJson = json.encode(settings.toJson());
      await prefs.setString(_systemSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving system settings: $e');
      throw Exception('Failed to save system settings');
    }
  }

  // Reset system settings to defaults
  Future<void> resetSystemSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_systemSettingsKey);
    } catch (e) {
      print('Error resetting system settings: $e');
      throw Exception('Failed to reset system settings');
    }
  }

  // Get security settings
  Future<SecuritySettings> getSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_securitySettingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        return SecuritySettings.fromJson(settingsMap);
      }
    } catch (e) {
      // If there's an error, return default settings
      print('Error loading security settings: $e');
    }

    // Return default settings
    return SecuritySettings.defaults();
  }

  // Save security settings
  Future<void> saveSecuritySettings(SecuritySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String settingsJson = json.encode(settings.toJson());
      await prefs.setString(_securitySettingsKey, settingsJson);
    } catch (e) {
      print('Error saving security settings: $e');
      throw Exception('Failed to save security settings');
    }
  }

  // Reset security settings to defaults
  Future<void> resetSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_securitySettingsKey);
    } catch (e) {
      print('Error resetting security settings: $e');
      throw Exception('Failed to reset security settings');
    }
  }

  // Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_notificationSettingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        return NotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      // If there's an error, return default settings
      print('Error loading notification settings: $e');
    }

    // Return default settings
    return NotificationSettings.defaults();
  }

  // Save notification settings
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String settingsJson = json.encode(settings.toJson());
      await prefs.setString(_notificationSettingsKey, settingsJson);
    } catch (e) {
      print('Error saving notification settings: $e');
      throw Exception('Failed to save notification settings');
    }
  }

  // Reset notification settings to defaults
  Future<void> resetNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationSettingsKey);
    } catch (e) {
      print('Error resetting notification settings: $e');
      throw Exception('Failed to reset notification settings');
    }
  }

  // Get version history
  Future<List<VersionHistoryItem>> getVersionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_versionHistoryKey);

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        return historyList
            .map((item) => VersionHistoryItem.fromJson(item))
            .toList();
      }
    } catch (e) {
      // If there's an error, return default history
      print('Error loading version history: $e');
    }

    // Return default history
    return _getDefaultVersionHistory();
  }

  // Default version history
  List<VersionHistoryItem> _getDefaultVersionHistory() {
    return [
      VersionHistoryItem(
        version: '1.0.0',
        releaseDate: DateTime.now(),
        changes: [
          'Initial release',
          'Dispatch management system',
          'User authentication and management',
          'Transit slip generation',
          'Communication link status tracking',
          'Units management',
          'Comprehensive reporting',
        ],
      ),
    ];
  }
}

/// System Settings Model
class SystemSettings {
  final bool enableAutoBackup;
  final String backupFrequency;
  final bool enableDataCompression;
  final bool enableDebugMode;
  final int sessionTimeoutMinutes;
  final int maxLoginAttempts;
  final int lockoutDurationMinutes;
  final bool enableAuditLogging;

  SystemSettings({
    required this.enableAutoBackup,
    required this.backupFrequency,
    required this.enableDataCompression,
    required this.enableDebugMode,
    required this.sessionTimeoutMinutes,
    required this.maxLoginAttempts,
    required this.lockoutDurationMinutes,
    required this.enableAuditLogging,
  });

  // Create default settings
  factory SystemSettings.defaults() {
    return SystemSettings(
      enableAutoBackup: true,
      backupFrequency: 'Daily',
      enableDataCompression: true,
      enableDebugMode: false,
      sessionTimeoutMinutes: 30,
      maxLoginAttempts: 5,
      lockoutDurationMinutes: 30,
      enableAuditLogging: true,
    );
  }

  // Create from JSON
  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      enableAutoBackup: json['enableAutoBackup'] ?? true,
      backupFrequency: json['backupFrequency'] ?? 'Daily',
      enableDataCompression: json['enableDataCompression'] ?? true,
      enableDebugMode: json['enableDebugMode'] ?? false,
      sessionTimeoutMinutes: json['sessionTimeoutMinutes'] ?? 30,
      maxLoginAttempts: json['maxLoginAttempts'] ?? 5,
      lockoutDurationMinutes: json['lockoutDurationMinutes'] ?? 30,
      enableAuditLogging: json['enableAuditLogging'] ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enableAutoBackup': enableAutoBackup,
      'backupFrequency': backupFrequency,
      'enableDataCompression': enableDataCompression,
      'enableDebugMode': enableDebugMode,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDurationMinutes': lockoutDurationMinutes,
      'enableAuditLogging': enableAuditLogging,
    };
  }
}

/// Security Settings Model
class SecuritySettings {
  final bool enforceStrongPasswords;
  final bool enableTwoFactorAuth;
  final bool requirePasswordChange;
  final int passwordExpiryDays;
  final bool preventPasswordReuse;
  final int passwordHistoryCount;
  final bool enableIpRestriction;
  final List<String> allowedIpAddresses;
  final bool enableEncryption;
  final String encryptionLevel;

  SecuritySettings({
    required this.enforceStrongPasswords,
    required this.enableTwoFactorAuth,
    required this.requirePasswordChange,
    required this.passwordExpiryDays,
    required this.preventPasswordReuse,
    required this.passwordHistoryCount,
    required this.enableIpRestriction,
    required this.allowedIpAddresses,
    required this.enableEncryption,
    required this.encryptionLevel,
  });

  // Create default settings
  factory SecuritySettings.defaults() {
    return SecuritySettings(
      enforceStrongPasswords: true,
      enableTwoFactorAuth: false,
      requirePasswordChange: true,
      passwordExpiryDays: 90,
      preventPasswordReuse: true,
      passwordHistoryCount: 5,
      enableIpRestriction: false,
      allowedIpAddresses: [],
      enableEncryption: true,
      encryptionLevel: 'AES-256',
    );
  }

  // Create from JSON
  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      enforceStrongPasswords: json['enforceStrongPasswords'] ?? true,
      enableTwoFactorAuth: json['enableTwoFactorAuth'] ?? false,
      requirePasswordChange: json['requirePasswordChange'] ?? true,
      passwordExpiryDays: json['passwordExpiryDays'] ?? 90,
      preventPasswordReuse: json['preventPasswordReuse'] ?? true,
      passwordHistoryCount: json['passwordHistoryCount'] ?? 5,
      enableIpRestriction: json['enableIpRestriction'] ?? false,
      allowedIpAddresses: List<String>.from(json['allowedIpAddresses'] ?? []),
      enableEncryption: json['enableEncryption'] ?? true,
      encryptionLevel: json['encryptionLevel'] ?? 'AES-256',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enforceStrongPasswords': enforceStrongPasswords,
      'enableTwoFactorAuth': enableTwoFactorAuth,
      'requirePasswordChange': requirePasswordChange,
      'passwordExpiryDays': passwordExpiryDays,
      'preventPasswordReuse': preventPasswordReuse,
      'passwordHistoryCount': passwordHistoryCount,
      'enableIpRestriction': enableIpRestriction,
      'allowedIpAddresses': allowedIpAddresses,
      'enableEncryption': enableEncryption,
      'encryptionLevel': encryptionLevel,
    };
  }
}

/// Notification Settings Model
class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSoundAlerts;
  final bool enableVibration;
  final bool showNotificationPreview;

  final bool notifyNewDispatch;
  final bool notifyDispatchUpdates;
  final bool notifyDispatchDelivered;
  final bool notifyDispatchDelayed;
  final bool notifySystemUpdates;
  final bool notifySecurityAlerts;

  final bool enableDoNotDisturb;
  final TimeOfDay doNotDisturbStart;
  final TimeOfDay doNotDisturbEnd;

  NotificationSettings({
    required this.enablePushNotifications,
    required this.enableEmailNotifications,
    required this.enableSoundAlerts,
    required this.enableVibration,
    required this.showNotificationPreview,
    required this.notifyNewDispatch,
    required this.notifyDispatchUpdates,
    required this.notifyDispatchDelivered,
    required this.notifyDispatchDelayed,
    required this.notifySystemUpdates,
    required this.notifySecurityAlerts,
    required this.enableDoNotDisturb,
    required this.doNotDisturbStart,
    required this.doNotDisturbEnd,
  });

  // Create default settings
  factory NotificationSettings.defaults() {
    return NotificationSettings(
      enablePushNotifications: true,
      enableEmailNotifications: true,
      enableSoundAlerts: true,
      enableVibration: true,
      showNotificationPreview: true,
      notifyNewDispatch: true,
      notifyDispatchUpdates: true,
      notifyDispatchDelivered: true,
      notifyDispatchDelayed: true,
      notifySystemUpdates: false,
      notifySecurityAlerts: true,
      enableDoNotDisturb: false,
      doNotDisturbStart: const TimeOfDay(hour: 22, minute: 0),
      doNotDisturbEnd: const TimeOfDay(hour: 7, minute: 0),
    );
  }

  // Create from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? true,
      enableSoundAlerts: json['enableSoundAlerts'] ?? true,
      enableVibration: json['enableVibration'] ?? true,
      showNotificationPreview: json['showNotificationPreview'] ?? true,
      notifyNewDispatch: json['notifyNewDispatch'] ?? true,
      notifyDispatchUpdates: json['notifyDispatchUpdates'] ?? true,
      notifyDispatchDelivered: json['notifyDispatchDelivered'] ?? true,
      notifyDispatchDelayed: json['notifyDispatchDelayed'] ?? true,
      notifySystemUpdates: json['notifySystemUpdates'] ?? false,
      notifySecurityAlerts: json['notifySecurityAlerts'] ?? true,
      enableDoNotDisturb: json['enableDoNotDisturb'] ?? false,
      doNotDisturbStart: _timeOfDayFromJson(json['doNotDisturbStart']) ??
          const TimeOfDay(hour: 22, minute: 0),
      doNotDisturbEnd: _timeOfDayFromJson(json['doNotDisturbEnd']) ??
          const TimeOfDay(hour: 7, minute: 0),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSoundAlerts': enableSoundAlerts,
      'enableVibration': enableVibration,
      'showNotificationPreview': showNotificationPreview,
      'notifyNewDispatch': notifyNewDispatch,
      'notifyDispatchUpdates': notifyDispatchUpdates,
      'notifyDispatchDelivered': notifyDispatchDelivered,
      'notifyDispatchDelayed': notifyDispatchDelayed,
      'notifySystemUpdates': notifySystemUpdates,
      'notifySecurityAlerts': notifySecurityAlerts,
      'enableDoNotDisturb': enableDoNotDisturb,
      'doNotDisturbStart': _timeOfDayToJson(doNotDisturbStart),
      'doNotDisturbEnd': _timeOfDayToJson(doNotDisturbEnd),
    };
  }

  // Helper method to convert TimeOfDay to JSON
  static Map<String, int> _timeOfDayToJson(TimeOfDay timeOfDay) {
    return {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
  }

  // Helper method to convert JSON to TimeOfDay
  static TimeOfDay? _timeOfDayFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TimeOfDay(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
    );
  }
}

/// Version History Item Model
class VersionHistoryItem {
  final String version;
  final DateTime releaseDate;
  final List<String> changes;

  VersionHistoryItem({
    required this.version,
    required this.releaseDate,
    required this.changes,
  });

  // Create from JSON
  factory VersionHistoryItem.fromJson(Map<String, dynamic> json) {
    return VersionHistoryItem(
      version: json['version'] ?? '',
      releaseDate: DateTime.parse(
          json['releaseDate'] ?? DateTime.now().toIso8601String()),
      changes: List<String>.from(json['changes'] ?? []),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'releaseDate': releaseDate.toIso8601String(),
      'changes': changes,
    };
  }
}
