import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to handle platform-specific functionality and checks
class PlatformService {
  /// Check if the app is running on Windows
  static bool isWindows() {
    return Platform.isWindows;
  }
  
  /// Check if the app is running on a supported platform (Windows only)
  static bool isSupportedPlatform() {
    return isWindows();
  }
  
  /// Get the current platform name
  static String getPlatformName() {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }
  
  /// Get the current platform version
  static Future<String> getPlatformVersion() async {
    try {
      if (Platform.isWindows) {
        // For Windows, we can try to get more detailed information
        final result = await Process.run('ver', [], runInShell: true);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      }
    } catch (e) {
      debugPrint('Error getting platform version: $e');
    }
    
    // Fallback to basic platform version
    return Platform.operatingSystemVersion;
  }
  
  /// Check if the app is running in debug mode
  static bool isDebugMode() {
    return kDebugMode;
  }
  
  /// Check if the app is running in release mode
  static bool isReleaseMode() {
    return kReleaseMode;
  }
  
  /// Check if the app is running in profile mode
  static bool isProfileMode() {
    return kProfileMode;
  }
  
  /// Get the app's executable path
  static String? getExecutablePath() {
    try {
      return Platform.resolvedExecutable;
    } catch (e) {
      debugPrint('Error getting executable path: $e');
      return null;
    }
  }
  
  /// Get the app's temporary directory path
  static String? getTemporaryDirectoryPath() {
    try {
      return Directory.systemTemp.path;
    } catch (e) {
      debugPrint('Error getting temporary directory path: $e');
      return null;
    }
  }
}
