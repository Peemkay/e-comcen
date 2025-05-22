import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nasds/services/auth_service.dart';

/// Provider to manage the lock screen state across the application
/// Implements a simple lock screen with username/password authentication
class LockScreenProvider extends ChangeNotifier {
  // Singleton pattern
  static final LockScreenProvider _instance = LockScreenProvider._internal();
  factory LockScreenProvider() => _instance;
  LockScreenProvider._internal();

  // Dependencies
  final AuthService _authService = AuthService();

  // State
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  // Initialize the provider
  Future<void> initialize() async {
    debugPrint('Lock screen provider initialized');
  }

  // Record user activity (kept for API compatibility)
  void recordActivity() {
    // No-op - we don't use activity tracking for auto-locking anymore
  }

  // Lock the screen
  void lockScreen() {
    if (!_isLocked) {
      _isLocked = true;
      notifyListeners();
      debugPrint('Screen locked');
    }
  }

  // Unlock the screen with credentials
  Future<bool> unlockScreen(String username, String password) async {
    try {
      // Verify credentials with the auth service
      final user = await _authService.login(username, password);
      final isValid = user != null;

      if (isValid) {
        _isLocked = false;
        notifyListeners();
        debugPrint('Screen unlocked successfully');
        return true;
      }

      debugPrint('Invalid credentials for unlocking screen');
      return false;
    } catch (e) {
      debugPrint('Error in unlockScreen: $e');
      return false;
    }
  }

  // Unlock without verification (for internal use)
  void unlockWithoutVerification() {
    _isLocked = false;
    notifyListeners();
    debugPrint('Screen unlocked without verification');
  }

  // Logout from the lock screen
  void logout() {
    try {
      // First unlock the screen
      _isLocked = false;

      // Then logout the user
      _authService.logout();

      // Notify listeners after both operations
      notifyListeners();
      debugPrint('Logged out successfully');
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}
