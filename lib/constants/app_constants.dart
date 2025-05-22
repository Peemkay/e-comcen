class AppConstants {
  // App Information
  static const String appName = 'E-COMCEN';
  static const String appFullName = 'Electronic Communications Center';
  static const String appOrganization = 'Nigerian Army Signal';
  static const String appPoweredBy = 'NAS';
  static const String appDescription =
      'Communications and Dispatch Management System for Signal Units';
  static const String appVersion = '1.0.0';

  // Get current year dynamically
  static String get currentYear => DateTime.now().year.toString();

  // Platform Information
  static const String appPlatform = 'Windows';
  static const String appDeviceName = 'Desktop';

  // Splash Screen
  static const int splashDuration = 3; // in seconds

  // Routes
  static const String splashRoute = '/splash';
  static const String loadingRoute = '/loading';
  static const String loginRoute = '/login';
  static const String registrationRoute = '/registration';
  static const String homeRoute = '/home';
  static const String lockRoute = '/lock';
  static const String settingsRoute = '/settings';

  // Admin Routes
  static const String userManagementRoute = '/admin/users';
  static const String userEditRoute = '/admin/users/edit';
  static const String systemSettingsRoute = '/admin/system';
  static const String securitySettingsRoute = '/admin/security';
  static const String deviceManagementRoute = '/admin/devices';
  static const String unitsManagementRoute = '/admin/units';

  // Dispatcher Routes
  static const String dispatcherLoginRoute = '/dispatcher/login';
  static const String dispatcherHomeRoute = '/dispatcher/home';

  // Reports Routes
  static const String transitSlipGeneratorRoute = '/reports/transit-slip';
  static const String inFileSlipGeneratorRoute = '/reports/in-file-slip';
  static const String outFileSlipGeneratorRoute = '/reports/out-file-slip';

  // Assets
  static const String logoPath =
      'assets/images/nas_logo.png'; // Nigerian Army Signals logo
  static const String iconPath =
      'assets/images/nas_logo.png'; // Same logo for icon
  static const String backgroundPath = 'assets/images/background.svg';
}
