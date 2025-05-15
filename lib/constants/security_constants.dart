/// Security constants for the E-COMCEN application
class SecurityConstants {
  // Security classification - set to empty to ensure no classification is shown
  static const String securityClassification = '';

  // Flag to control display of security classification banners - must be false
  static const bool showClassificationBanner = false;

  // Session timeout in minutes
  static const int sessionTimeoutMinutes = 15;

  // Password requirements
  static const int minPasswordLength = 12;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;

  // Maximum login attempts before lockout
  static const int maxLoginAttempts = 5;

  // Lockout duration in minutes
  static const int lockoutDurationMinutes = 30;

  // Password expiry in days
  static const int passwordExpiryDays = 90;

  // Biometric authentication settings
  static const bool biometricAuthEnabled = true;

  // Encryption settings
  static const String encryptionAlgorithm = 'AES-256';
  static const String fallbackEncryptionKey =
      'E-COMCEN_SECURE_FALLBACK_KEY_DO_NOT_USE_IN_PROD';

  // Network security settings
  static const bool enforceSecureConnections = true;

  // Data retention period in days
  static const int dataRetentionDays = 365;

  // Security log retention period in days
  static const int securityLogRetentionDays = 730; // 2 years

  // Screen capture prevention
  static const bool preventScreenCapture = true;

  // Clipboard restrictions
  static const bool restrictClipboard = true;

  // Offline mode security
  static const bool enforceOfflineSecurity = true;

  // Device security
  static const bool enforceDeviceSecurity = true;

  // Regular expressions for input validation
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{6,20}$');
  static final RegExp passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{12,}$');
  static final RegExp emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  // Security warning messages
  static const String securityWarningMessage =
      'WARNING: This system contains Nigerian Army Signal information. '
      'System usage may be monitored, recorded, and subject to audit. '
      'Unauthorized use of the system is prohibited and subject to '
      'criminal and civil penalties. Use of this system indicates '
      'consent to monitoring and recording.';

  // Security breach actions
  static const List<String> securityBreachActions = [
    'Lock application',
    'Log security event',
    'Notify administrator',
    'Clear sensitive data',
    'Force logout'
  ];
}
