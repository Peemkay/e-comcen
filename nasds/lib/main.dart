import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/translation_provider.dart';
import 'providers/security_provider.dart';
import 'providers/dispatcher_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dispatcher/dispatcher_login_screen.dart';
import 'screens/dispatcher/dispatcher_home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/user_edit_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/admin/security_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/notification_center_screen.dart';
import 'widgets/secure_app_wrapper.dart';
import 'widgets/security_classification_banner.dart';
import 'widgets/notifications/notification_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if running on Windows platform
  if (!isWindows()) {
    // Show error dialog and exit if not running on Windows
    runApp(const UnsupportedPlatformApp());
    return;
  }

  // Allow all orientations for better responsiveness on Windows
  // This enables the app to adapt to both portrait and landscape modes
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style for Windows
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

// Check if the app is running on Windows
bool isWindows() {
  return Platform.isWindows;
}

/// App to show when running on an unsupported platform
class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Not Supported',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5D1A),
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Platform Not Supported'),
          backgroundColor: const Color(0xFF1A5D1A),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Color(0xFF1A5D1A),
                ),
                SizedBox(height: 24),
                Text(
                  'E-COMCEN is only supported on Windows',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'This application is designed to run exclusively on Windows platforms. '
                  'Please launch the application on a Windows device.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => DispatcherProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<TranslationProvider, SecurityProvider>(
        builder: (context, translationProvider, securityProvider, _) {
          // Initialize the translation provider if not already initialized
          if (!translationProvider.isLoading) {
            Future.microtask(() => translationProvider.initialize());
          }

          // Initialize the security provider if not already initialized
          if (!securityProvider.isInitialized) {
            Future.microtask(() => securityProvider.initialize());
          }

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: AppConstants.splashRoute,

            // Define routes with builder functions that create responsive layouts
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.loadingRoute: (context) => const LoadingScreen(),
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.registrationRoute: (context) =>
                  const RegistrationScreen(),
              AppConstants.homeRoute: (context) => const HomeScreen(),
              AppConstants.lockRoute: (context) => const LockScreen(),
              AppConstants.settingsRoute: (context) => const SettingsScreen(),
              AppConstants.userManagementRoute: (context) =>
                  const UserManagementScreen(),
              AppConstants.userEditRoute: (context) => const UserEditScreen(),
              AppConstants.systemSettingsRoute: (context) =>
                  const SystemSettingsScreen(),
              AppConstants.securitySettingsRoute: (context) =>
                  const SecuritySettingsScreen(),
              AppConstants.dispatcherLoginRoute: (context) =>
                  const DispatcherLoginScreen(),
              AppConstants.dispatcherHomeRoute: (context) =>
                  const DispatcherHomeScreen(),
              '/notifications': (context) => const NotificationCenterScreen(),
              '/notification_settings': (context) =>
                  const NotificationSettingsScreen(),
            },

            // Add localization support
            localizationsDelegates: const [
              // Add the required localization delegates
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('fr', ''), // French
              Locale('ar', ''), // Arabic
              // For now, we'll use English as a fallback for Nigerian languages
              // until we can properly implement custom localization delegates
            ],
            // Always use English for now to avoid localization errors
            locale: Locale('en'),

            // Add responsive builder to handle screen size changes
            builder: (context, child) {
              // Get the media query data
              final mediaQuery = MediaQuery.of(context);

              // Create a fixed text scaler to prevent text overflow
              // Use TextScaler.linear instead of the deprecated textScaleFactor
              final textScaler = TextScaler.linear(1.0);

              // Return a new MediaQuery with the adjusted text scaler
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: textScaler,
                ),
                child: SecureAppWrapper(
                  child: SecurityClassificationWrapper(
                    child: NotificationManager(
                      child: child!,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
