import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nasds/constants/app_theme.dart';
import 'package:nasds/constants/security_constants.dart';
import 'package:nasds/providers/translation_provider.dart';
import 'package:nasds/providers/security_provider.dart';
import 'package:nasds/providers/dispatcher_provider.dart';
import 'package:nasds/screens/dispatcher/dispatcher_login_screen.dart';
import 'package:nasds/screens/dispatcher/dispatcher_home_screen.dart';
import 'package:nasds/widgets/secure_app_wrapper.dart';
import 'package:nasds/widgets/security_classification_banner.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
      ],
      child: Consumer<TranslationProvider>(
        builder: (context, translationProvider, _) {
          return MaterialApp(
            title: 'E-COMCEN DSM',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppTheme.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppTheme.primaryColor,
                primary: AppTheme.primaryColor,
                secondary: AppTheme.secondaryColor,
              ),
              fontFamily: 'Roboto',
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            home: SecureAppWrapper(
              child: Builder(
                builder: (context) {
                  // Add security classification banner
                  return Stack(
                    children: [
                      const DispatcherLoginScreen(),
                      if (SecurityConstants.showClassificationBanner)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SecurityClassificationBanner(),
                        ),
                    ],
                  );
                },
              ),
            ),
            routes: {
              '/login': (context) => const DispatcherLoginScreen(),
              '/home': (context) => const DispatcherHomeScreen(),
            },
          );
        },
      ),
    );
  }
}
