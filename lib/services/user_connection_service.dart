import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import 'local_storage_service.dart';

/// Service for tracking user connections
class UserConnectionService {
  // Singleton pattern
  static final UserConnectionService _instance =
      UserConnectionService._internal();
  factory UserConnectionService() => _instance;
  UserConnectionService._internal();

  // Local storage service
  final LocalStorageService _localStorageService = LocalStorageService();

  // Database
  Database? _database;
  final String _connectionsTable = 'connections';

  // Device info
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Connection ID
  String? _connectionId;

  // Heartbeat timer
  Timer? _heartbeatTimer;

  // Current user
  User? _currentUser;

  // Getters
  String? get connectionId => _connectionId;
  User? get currentUser => _currentUser;

  // Initialize the service
  Future<void> initialize(User user) async {
    _currentUser = user;

    // Generate a unique connection ID
    _connectionId = const Uuid().v4();

    // Get device info
    final deviceInfo = await _getDeviceInfo();

    // Get IP address
    final ipAddress = await _getIpAddress();

    // Update user with connection info
    final updatedUser = user.copyWith(
      isOnline: true,
      lastSeen: DateTime.now(),
      deviceId: deviceInfo['deviceId'],
      deviceInfo: deviceInfo['deviceName'],
      connectionId: _connectionId,
      ipAddress: ipAddress,
    );

    // Update user in Firestore
    await _updateUserConnection(updatedUser);

    // Start heartbeat timer
    _startHeartbeat();

    debugPrint('User connection initialized: ${user.name} ($_connectionId)');
  }

  // Get device info
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      if (Platform.isWindows) {
        final info = await _deviceInfoPlugin.windowsInfo;
        return {
          'deviceId': info.deviceId,
          'deviceName': '${info.computerName} (${info.productName})',
        };
      } else {
        return {
          'deviceId': 'unknown',
          'deviceName': 'Unknown Device',
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {
        'deviceId': 'error',
        'deviceName': 'Error Getting Device Info',
      };
    }
  }

  // Get IP address
  Future<String?> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting IP address: $e');
      return null;
    }
  }

  // Update user connection in Firestore
  Future<void> _updateUserConnection(User user) async {
    try {
      if (_firebaseService.currentUnitId == null) return;

      // Update user document
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .doc(user.id)
          .update({
        'isOnline': user.isOnline,
        'lastSeen': user.lastSeen?.millisecondsSinceEpoch,
        'deviceId': user.deviceId,
        'deviceInfo': user.deviceInfo,
        'connectionId': user.connectionId,
        'ipAddress': user.ipAddress,
      });

      // Add connection record
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .doc(_connectionId)
          .set({
        'userId': user.id,
        'username': user.username,
        'name': user.name,
        'role': user.role.name,
        'unitId': user.unitId,
        'deviceId': user.deviceId,
        'deviceInfo': user.deviceInfo,
        'ipAddress': user.ipAddress,
        'connectionId': _connectionId,
        'connectedAt': DateTime.now().millisecondsSinceEpoch,
        'lastHeartbeat': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
      }, SetOptions(merge: true));

      _currentUser = user;
    } catch (e) {
      debugPrint('Error updating user connection: $e');
    }
  }

  // Start heartbeat timer
  void _startHeartbeat() {
    // Cancel existing timer
    _heartbeatTimer?.cancel();

    // Start new timer (every 30 seconds)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  // Send heartbeat
  Future<void> _sendHeartbeat() async {
    try {
      if (_firebaseService.currentUnitId == null ||
          _connectionId == null ||
          _currentUser == null) {
        return;
      }

      // Update connection record
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .doc(_connectionId)
          .update({
        'lastHeartbeat': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
      });

      // Update user document
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .doc(_currentUser!.id)
          .update({
        'isOnline': true,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('Heartbeat sent: ${_currentUser!.name} ($_connectionId)');
    } catch (e) {
      debugPrint('Error sending heartbeat: $e');
    }
  }

  // Disconnect user
  Future<void> disconnect() async {
    try {
      if (_firebaseService.currentUnitId == null ||
          _connectionId == null ||
          _currentUser == null) {
        return;
      }

      // Cancel heartbeat timer
      _heartbeatTimer?.cancel();

      // Update connection record
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .doc(_connectionId)
          .update({
        'isActive': false,
        'disconnectedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Update user document
      await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .doc(_currentUser!.id)
          .update({
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('User disconnected: ${_currentUser!.name} ($_connectionId)');

      // Clear connection ID
      _connectionId = null;
      _currentUser = null;
    } catch (e) {
      debugPrint('Error disconnecting user: $e');
    }
  }

  // Get active connections for a unit
  Future<List<Map<String, dynamic>>> getActiveConnections() async {
    try {
      if (_firebaseService.currentUnitId == null) return [];

      final querySnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting active connections: $e');
      return [];
    }
  }

  // Get online users for a unit
  Future<List<User>> getOnlineUsers() async {
    try {
      if (_firebaseService.currentUnitId == null) return [];

      final querySnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting online users: $e');
      return [];
    }
  }

  // Get connection history for a user
  Future<List<Map<String, dynamic>>> getUserConnectionHistory(
      String userId) async {
    try {
      if (_firebaseService.currentUnitId == null) return [];

      final querySnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .where('userId', isEqualTo: userId)
          .orderBy('connectedAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user connection history: $e');
      return [];
    }
  }

  // Get connection statistics for a unit
  Future<Map<String, dynamic>> getConnectionStatistics() async {
    try {
      if (_firebaseService.currentUnitId == null) return {};

      // Get total users
      final usersSnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .get();

      // Get online users
      final onlineUsersSnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .get();

      // Get active connections
      final connectionsSnapshot = await _firebaseService.firestore
          .collection('units')
          .doc(_firebaseService.currentUnitId)
          .collection('connections')
          .where('isActive', isEqualTo: true)
          .get();

      // Get connections by role
      final adminConnections = connectionsSnapshot.docs
          .where((doc) => doc.data()['role'] == UserRole.admin.name)
          .length;

      final superadminConnections = connectionsSnapshot.docs
          .where((doc) => doc.data()['role'] == UserRole.superadmin.name)
          .length;

      final dispatcherConnections = connectionsSnapshot.docs
          .where((doc) => doc.data()['role'] == UserRole.dispatcher.name)
          .length;

      return {
        'totalUsers': usersSnapshot.size,
        'onlineUsers': onlineUsersSnapshot.size,
        'activeConnections': connectionsSnapshot.size,
        'adminConnections': adminConnections,
        'superadminConnections': superadminConnections,
        'dispatcherConnections': dispatcherConnections,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      debugPrint('Error getting connection statistics: $e');
      return {};
    }
  }

  // Dispose
  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
