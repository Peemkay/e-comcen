import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'constants/app_theme.dart';
import 'screens/home_screen_new.dart' as home;

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASDS E-COMCEN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const home.HomeScreen(),
    );
  }
}
