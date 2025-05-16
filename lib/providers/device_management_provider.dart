import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

/// Provider for device management
class DeviceManagementProvider extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Current device info
  Map<String, dynamic>? _currentDevice;

  // List of user devices
  List<Map<String, dynamic>> _userDevices = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  Map<String, dynamic>? get currentDevice => _currentDevice;
  List<Map<String, dynamic>> get userDevices => _userDevices;

  /// Initialize device management
  Future<void> initialize(User user) async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      // Get current device info
      _currentDevice = {
        'id': 'device_001',
        'name': 'Current Device',
        'model': 'Windows PC',
        'platform': 'Windows',
        'isActive': true,
        'isPrimary': true,
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
      };

      // Initialize empty user devices list
      _userDevices = [
        {
          'id': 'device_001',
          'name': 'Current Device',
          'model': 'Windows PC',
          'platform': 'Windows',
          'isActive': true,
          'isPrimary': true,
          'lastUsed': DateTime.now().millisecondsSinceEpoch,
        },
      ];

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing device management: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Refresh devices
  Future<void> refreshDevices() async {
    try {
      // In a real implementation, this would fetch devices from a remote server
      // For local implementation, we'll just use the existing data
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing devices: $e');
    }
  }

  /// Remove device
  Future<bool> removeDevice(String deviceId) async {
    try {
      // Don't allow removing the current device
      if (_currentDevice != null && _currentDevice!['id'] == deviceId) {
        return false;
      }

      // Remove device from list
      _userDevices.removeWhere((device) => device['id'] == deviceId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error removing device: $e');
      return false;
    }
  }

  /// Set device as primary
  Future<bool> setDeviceAsPrimary(String deviceId) async {
    try {
      // Find device
      final deviceIndex =
          _userDevices.indexWhere((device) => device['id'] == deviceId);
      if (deviceIndex == -1) {
        return false;
      }

      // Update all devices
      for (int i = 0; i < _userDevices.length; i++) {
        _userDevices[i] = {
          ..._userDevices[i],
          'isPrimary': i == deviceIndex,
        };
      }

      // Update current device if it's the one being set as primary
      if (_currentDevice != null && _currentDevice!['id'] == deviceId) {
        _currentDevice = {
          ..._currentDevice!,
          'isPrimary': true,
        };
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error setting device as primary: $e');
      return false;
    }
  }
}
