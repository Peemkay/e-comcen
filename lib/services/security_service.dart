import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/security_log.dart';
import '../constants/security_constants.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  
  SecurityService._internal();
  
  // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
  
  // Local authentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Encryption key
  late encrypt.Key _encryptionKey;
  late encrypt.IV _encryptionIV;
  
  // Session management
  DateTime? _lastActivityTime;
  Timer? _sessionTimer;
  bool _isSessionActive = false;
  
  // Security logs
  List<SecurityLog> _securityLogs = [];
  
  // Initialize security service
  Future<void> initialize() async {
    await _initializeEncryption();
    await _checkDeviceSecurity();
    _startSessionTimer();
    await _loadSecurityLogs();
  }
  
  // Initialize encryption
  Future<void> _initializeEncryption() async {
    String? storedKey = await _secureStorage.read(key: 'encryption_key');
    String? storedIV = await _secureStorage.read(key: 'encryption_iv');
    
    if (storedKey == null || storedIV == null) {
      // Generate new encryption key and IV
      final key = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Store them securely
      await _secureStorage.write(key: 'encryption_key', value: base64.encode(key.bytes));
      await _secureStorage.write(key: 'encryption_iv', value: base64.encode(iv.bytes));
      
      _encryptionKey = key;
      _encryptionIV = iv;
    } else {
      // Use stored encryption key and IV
      _encryptionKey = encrypt.Key(base64.decode(storedKey));
      _encryptionIV = encrypt.IV(base64.decode(storedIV));
    }
  }
  
  // Check device security
  Future<bool> _checkDeviceSecurity() async {
    try {
      // Check for rooted/jailbroken device
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final isDeveloperMode = await FlutterJailbreakDetection.developerMode;
      
      if (isJailbroken) {
        _logSecurityEvent(
          SecurityEventType.deviceCompromised,
          'Device is rooted or jailbroken',
        );
        return false;
      }
      
      if (isDeveloperMode) {
        _logSecurityEvent(
          SecurityEventType.developerModeEnabled,
          'Developer mode is enabled on the device',
        );
        // We'll allow developer mode but log it
      }
      
      // Check device info
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        final deviceId = windowsInfo.deviceId;
        
        // Check if this is an authorized device
        final authorizedDevices = await _getAuthorizedDevices();
        if (!authorizedDevices.contains(deviceId)) {
          // First time using this device, add it to authorized devices
          if (authorizedDevices.isEmpty) {
            await _addAuthorizedDevice(deviceId);
          } else {
            _logSecurityEvent(
              SecurityEventType.unauthorizedDevice,
              'Unauthorized device: $deviceId',
            );
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      _logSecurityEvent(
        SecurityEventType.securityCheckFailed,
        'Security check failed: $e',
      );
      return false;
    }
  }
  
  // Get authorized devices
  Future<List<String>> _getAuthorizedDevices() async {
    final devices = await _secureStorage.read(key: 'authorized_devices');
    if (devices == null) {
      return [];
    }
    return devices.split(',');
  }
  
  // Add authorized device
  Future<void> _addAuthorizedDevice(String deviceId) async {
    final devices = await _getAuthorizedDevices();
    devices.add(deviceId);
    await _secureStorage.write(key: 'authorized_devices', value: devices.join(','));
    
    _logSecurityEvent(
      SecurityEventType.deviceAuthorized,
      'Device authorized: $deviceId',
    );
  }
  
  // Start session timer
  void _startSessionTimer() {
    _lastActivityTime = DateTime.now();
    _isSessionActive = true;
    
    // Cancel existing timer if any
    _sessionTimer?.cancel();
    
    // Create new timer
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _checkSessionTimeout(),
    );
  }
  
  // Check session timeout
  void _checkSessionTimeout() {
    if (!_isSessionActive || _lastActivityTime == null) {
      return;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastActivityTime!);
    
    if (difference.inMinutes >= SecurityConstants.sessionTimeoutMinutes) {
      _logSecurityEvent(
        SecurityEventType.sessionTimeout,
        'Session timed out after ${SecurityConstants.sessionTimeoutMinutes} minutes of inactivity',
      );
      
      _isSessionActive = false;
      _sessionTimer?.cancel();
      
      // Notify listeners about session timeout
      _sessionTimeoutController.add(true);
    }
  }
  
  // Update last activity time
  void updateActivity() {
    _lastActivityTime = DateTime.now();
    
    if (!_isSessionActive) {
      _startSessionTimer();
    }
  }
  
  // Session timeout stream
  final StreamController<bool> _sessionTimeoutController = StreamController<bool>.broadcast();
  Stream<bool> get onSessionTimeout => _sessionTimeoutController.stream;
  
  // Authenticate user with biometrics or PIN
  Future<bool> authenticateUser({bool biometricOnly = false}) async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isBiometricSupported = canCheckBiometrics && 
          await _localAuth.isDeviceSupported();
      
      if (isBiometricSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        
        if (availableBiometrics.isNotEmpty) {
          final didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Please authenticate to access E-COMCEN',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
          
          if (didAuthenticate) {
            _logSecurityEvent(
              SecurityEventType.loginSuccess,
              'User authenticated with biometrics',
            );
            _startSessionTimer();
            return true;
          } else {
            _logSecurityEvent(
              SecurityEventType.loginFailed,
              'Biometric authentication failed',
            );
            return false;
          }
        }
      }
      
      if (biometricOnly) {
        _logSecurityEvent(
          SecurityEventType.loginFailed,
          'Biometric authentication not available',
        );
        return false;
      }
      
      // Fall back to password authentication
      return true;
    } catch (e) {
      _logSecurityEvent(
        SecurityEventType.loginFailed,
        'Authentication error: $e',
      );
      return false;
    }
  }
  
  // Encrypt data
  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(data, iv: _encryptionIV);
    return encrypted.base64;
  }
  
  // Decrypt data
  String decryptData(String encryptedData) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      final decrypted = encrypter.decrypt64(encryptedData, iv: _encryptionIV);
      return decrypted;
    } catch (e) {
      _logSecurityEvent(
        SecurityEventType.decryptionFailed,
        'Failed to decrypt data: $e',
      );
      return '';
    }
  }
  
  // Hash password
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Generate random salt
  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(values);
  }
  
  // Store sensitive data securely
  Future<void> secureStore(String key, String value) async {
    await _secureStorage.write(key: key, value: encryptData(value));
  }
  
  // Retrieve sensitive data
  Future<String?> secureRetrieve(String key) async {
    final encryptedValue = await _secureStorage.read(key: key);
    if (encryptedValue == null) {
      return null;
    }
    return decryptData(encryptedValue);
  }
  
  // Delete sensitive data
  Future<void> secureDelete(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  // Clear all sensitive data
  Future<void> secureClear() async {
    await _secureStorage.deleteAll();
  }
  
  // Log security event
  void _logSecurityEvent(SecurityEventType type, String details) {
    final log = SecurityLog(
      timestamp: DateTime.now(),
      type: type,
      details: details,
    );
    
    _securityLogs.add(log);
    _saveSecurityLogs();
    
    // Print to console in debug mode
    if (kDebugMode) {
      print('SECURITY EVENT: ${log.type} - ${log.details}');
    }
  }
  
  // Save security logs
  Future<void> _saveSecurityLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/security_logs.enc');
      
      final logsJson = jsonEncode(_securityLogs.map((log) => log.toJson()).toList());
      final encryptedLogs = encryptData(logsJson);
      
      await file.writeAsString(encryptedLogs);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save security logs: $e');
      }
    }
  }
  
  // Load security logs
  Future<void> _loadSecurityLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/security_logs.enc');
      
      if (await file.exists()) {
        final encryptedLogs = await file.readAsString();
        final logsJson = decryptData(encryptedLogs);
        
        final List<dynamic> logsList = jsonDecode(logsJson);
        _securityLogs = logsList.map((json) => SecurityLog.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load security logs: $e');
      }
      _securityLogs = [];
    }
  }
  
  // Get security logs
  List<SecurityLog> getSecurityLogs() {
    return List.unmodifiable(_securityLogs);
  }
  
  // Clear security logs
  Future<void> clearSecurityLogs() async {
    _securityLogs = [];
    await _saveSecurityLogs();
  }
  
  // Check network security
  Future<bool> checkNetworkSecurity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity == ConnectivityResult.none) {
        // No network connection, consider it secure for offline use
        return true;
      }
      
      // Log network connection type
      _logSecurityEvent(
        SecurityEventType.networkConnection,
        'Connected to network: $connectivity',
      );
      
      // Additional network security checks could be added here
      // For example, checking if connected to a trusted network
      
      return true;
    } catch (e) {
      _logSecurityEvent(
        SecurityEventType.networkCheckFailed,
        'Network security check failed: $e',
      );
      return false;
    }
  }
  
  // Sanitize input data
  String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input.replaceAll(RegExp(r'[<>(){}[\]\\\/]'), '');
  }
  
  // Validate input data
  bool validateInput(String input, RegExp pattern) {
    return pattern.hasMatch(input);
  }
  
  // Lock screen
  void lockScreen(BuildContext context) {
    _isSessionActive = false;
    _sessionTimer?.cancel();
    
    // Navigate to lock screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/lock',
      (route) => false,
    );
  }
  
  // Logout
  Future<void> logout() async {
    _isSessionActive = false;
    _sessionTimer?.cancel();
    
    _logSecurityEvent(
      SecurityEventType.logout,
      'User logged out',
    );
    
    // Clear session data but keep encryption keys
    await _secureStorage.delete(key: 'session_token');
    await _secureStorage.delete(key: 'user_data');
  }
  
  // Dispose
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimeoutController.close();
  }
}
