import 'dart:async';
import 'package:flutter/material.dart';
import '../models/security_log.dart';
import '../services/security_service.dart';

class SecurityProvider extends ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  
  bool _isInitialized = false;
  bool _isSecure = false;
  bool _isAuthenticated = false;
  bool _isSessionActive = false;
  bool _isOfflineMode = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSecure => _isSecure;
  bool get isAuthenticated => _isAuthenticated;
  bool get isSessionActive => _isSessionActive;
  bool get isOfflineMode => _isOfflineMode;
  
  // Stream subscription for session timeout
  StreamSubscription<bool>? _sessionTimeoutSubscription;
  
  // Initialize security provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _securityService.initialize();
      
      // Subscribe to session timeout events
      _sessionTimeoutSubscription = _securityService.onSessionTimeout.listen((timeout) {
        if (timeout) {
          _isSessionActive = false;
          notifyListeners();
        }
      });
      
      // Check device security
      _isSecure = await _securityService.checkNetworkSecurity();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = false;
      _isSecure = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Authenticate user
  Future<bool> authenticateUser({bool biometricOnly = false}) async {
    try {
      final result = await _securityService.authenticateUser(biometricOnly: biometricOnly);
      
      if (result) {
        _isAuthenticated = true;
        _isSessionActive = true;
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      return false;
    }
  }
  
  // Update user activity
  void updateActivity() {
    _securityService.updateActivity();
    _isSessionActive = true;
    notifyListeners();
  }
  
  // Lock application
  void lockApplication(BuildContext context) {
    _securityService.lockScreen(context);
    _isSessionActive = false;
    notifyListeners();
  }
  
  // Logout
  Future<void> logout() async {
    await _securityService.logout();
    _isAuthenticated = false;
    _isSessionActive = false;
    notifyListeners();
  }
  
  // Get security logs
  List<SecurityLog> getSecurityLogs() {
    return _securityService.getSecurityLogs();
  }
  
  // Clear security logs
  Future<void> clearSecurityLogs() async {
    await _securityService.clearSecurityLogs();
    notifyListeners();
  }
  
  // Store sensitive data securely
  Future<void> secureStore(String key, String value) async {
    await _securityService.secureStore(key, value);
  }
  
  // Retrieve sensitive data
  Future<String?> secureRetrieve(String key) async {
    return _securityService.secureRetrieve(key);
  }
  
  // Delete sensitive data
  Future<void> secureDelete(String key) async {
    await _securityService.secureDelete(key);
  }
  
  // Clear all sensitive data
  Future<void> secureClear() async {
    await _securityService.secureClear();
  }
  
  // Encrypt data
  String encryptData(String data) {
    return _securityService.encryptData(data);
  }
  
  // Decrypt data
  String decryptData(String encryptedData) {
    return _securityService.decryptData(encryptedData);
  }
  
  // Set offline mode
  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }
  
  // Check network security
  Future<bool> checkNetworkSecurity() async {
    final result = await _securityService.checkNetworkSecurity();
    _isSecure = result;
    notifyListeners();
    return result;
  }
  
  // Sanitize input data
  String sanitizeInput(String input) {
    return _securityService.sanitizeInput(input);
  }
  
  // Validate input data
  bool validateInput(String input, RegExp pattern) {
    return _securityService.validateInput(input, pattern);
  }
  
  @override
  void dispose() {
    _sessionTimeoutSubscription?.cancel();
    _securityService.dispose();
    super.dispose();
  }
}
