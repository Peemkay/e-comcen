import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/translation_provider.dart';
import 'providers/security_provider.dart';
import 'providers/dispatcher_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/local_storage_provider.dart';
import 'providers/lock_screen_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen_new.dart' as home;
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dispatcher/dispatcher_login_screen.dart';
import 'screens/dispatcher/dispatcher_home_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/lock_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/user_edit_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/admin/security_settings_screen.dart';
import 'screens/units/units_management_screen_new.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/profile/user_profile_screen.dart';
import 'screens/help/help_menu_screen.dart';
import 'screens/reports/transit_slip_generator.dart';
import 'screens/reports/in_file_slip_generator.dart';
import 'screens/reports/out_file_slip_generator.dart';
import 'widgets/secure_app_wrapper.dart';
import 'widgets/security_classification_banner.dart';
import 'widgets/notifications/notification_manager.dart';
import 'widgets/responsive_container.dart';
import 'utils/app_bar_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_common_ffi for Windows
  if (Platform.isWindows) {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for Windows
    databaseFactory = databaseFactoryFfi;
    debugPrint('Initialized sqflite_ffi for Windows');
  }

  // Allow all orientations for better responsiveness
  // This enables the app to adapt to both portrait and landscape modes
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set production mode
  const bool isProduction = true;

  // Disable debug banner and print statements in production
  if (isProduction) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  runApp(const MyApp());
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
        ChangeNotifierProvider(create: (_) => LocalStorageProvider()),
        ChangeNotifierProvider(create: (_) => LockScreenProvider()),
      ],
      child: Consumer3<TranslationProvider, SecurityProvider,
          LocalStorageProvider>(
        builder: (context, translationProvider, securityProvider,
            localStorageProvider, _) {
          // Initialize the translation provider if not already initialized
          if (!translationProvider.isLoading) {
            Future.microtask(() => translationProvider.initialize());
          }

          // Initialize the security provider if not already initialized
          if (!securityProvider.isInitialized) {
            Future.microtask(() => securityProvider.initialize());
          }

          // Initialize the local storage provider if not already initialized
          if (!localStorageProvider.isInitialized &&
              !localStorageProvider.isInitializing) {
            Future.microtask(() => localStorageProvider.initialize());
          }

          // Set production mode
          const bool isProduction = true;

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: !isProduction,
            theme: AppTheme.lightTheme,
            navigatorKey: AppBarUtils.navigatorKey,
            initialRoute: AppConstants.splashRoute,

            // Define routes with builder functions that create responsive layouts
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.loadingRoute: (context) => const LoadingScreen(),
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.registrationRoute: (context) =>
                  const RegistrationScreen(),
              AppConstants.homeRoute: (context) => const home.HomeScreen(),
              // Redirect to home screen instead of old lock screen
              AppConstants.lockRoute: (context) => const home.HomeScreen(),
              AppConstants.settingsRoute: (context) => const SettingsScreen(),
              AppConstants.userManagementRoute: (context) =>
                  const UserManagementScreen(),
              AppConstants.userEditRoute: (context) => const UserEditScreen(),
              AppConstants.systemSettingsRoute: (context) =>
                  const SystemSettingsScreen(),
              AppConstants.securitySettingsRoute: (context) =>
                  const SecuritySettingsScreen(),
              AppConstants.unitsManagementRoute: (context) =>
                  const UnitsManagementScreenNew(),
              AppConstants.dispatcherLoginRoute: (context) =>
                  const DispatcherLoginScreen(),
              AppConstants.dispatcherHomeRoute: (context) =>
                  const DispatcherHomeScreen(),
              '/notifications': (context) => const NotificationCenterScreen(),
              '/notification_settings': (context) =>
                  const NotificationSettingsScreen(),
              '/profile': (context) => const UserProfileScreen(),
              '/help': (context) => const HelpMenuScreen(),
              '/about': (context) => const HelpMenuScreen(),
              '/terms': (context) => const HelpMenuScreen(),
              '/privacy': (context) => const HelpMenuScreen(),
              AppConstants.transitSlipGeneratorRoute: (context) =>
                  const TransitSlipGenerator(),
              AppConstants.inFileSlipGeneratorRoute: (context) =>
                  const InFileSlipGenerator(),
              AppConstants.outFileSlipGeneratorRoute: (context) =>
                  const OutFileSlipGenerator(),
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

              // Calculate responsive text scale based on screen width
              // This ensures text is readable on all devices while preventing overflow
              double textScaleFactor = 1.0;
              final width = mediaQuery.size.width;
              final height = mediaQuery.size.height;

              // Log screen dimensions for debugging
              debugPrint('Screen dimensions: $width x $height');

              // Adjust text scale based on screen width
              if (width < 360) {
                textScaleFactor = 0.8; // Small phones
              } else if (width < 650) {
                textScaleFactor = 0.95; // Normal phones
              } else if (width < 1100) {
                textScaleFactor = 1.0; // Tablets
              } else {
                textScaleFactor = 1.05; // Desktops
              }

              // Create a responsive text scaler
              final textScaler = TextScaler.linear(textScaleFactor);

              // Calculate padding based on screen size
              // This helps with responsive layout on different devices
              final horizontalPadding = width < 600 ? 0.0 : 16.0;
              final verticalPadding = height < 500 ? 0.0 : 8.0;

              // Return a new MediaQuery with the adjusted text scaler
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: textScaler,
                  padding: mediaQuery.padding.copyWith(
                    left: mediaQuery.padding.left + horizontalPadding,
                    right: mediaQuery.padding.right + horizontalPadding,
                    top: mediaQuery.padding.top + verticalPadding,
                    bottom: mediaQuery.padding.bottom + verticalPadding,
                  ),
                ),
                child: SecureAppWrapper(
                  child: SecurityClassificationWrapper(
                    child: NotificationManager(
                      // Apply responsive container to limit width on large screens
                      // This prevents UI elements from stretching too much on wide screens
                      child: LockScreen(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: ResponsiveContainer(
                                // Use different max widths based on screen size
                                maxWidth: width > 1200 ? 1200 : null,
                                // Center content on larger screens
                                centerContent: width > 900,
                                child: child!,
                              ),
                            );
                          },
                        ),
                      ),
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
