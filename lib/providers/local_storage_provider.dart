import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../services/local_storage_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_listener_service.dart';
import '../services/background_task_service.dart';
import '../models/user.dart';
import '../models/unit.dart';
import 'device_management_provider.dart';

/// Provider for local storage services
/// This replaces the Firebase provider with a local implementation
class LocalStorageProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  final LocalNotificationService _notificationService = LocalNotificationService();
  final NotificationListenerService _notificationListener = NotificationListenerService();
  final BackgroundTaskService _backgroundTaskService = BackgroundTaskService();

  bool _isInitialized = false;
  bool _isInitializing = false;
  User? _currentUser;
  Unit? _currentUnit;
  String? _currentUnitId;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  User? get currentUser => _currentUser;
  Unit? get currentUnit => _currentUnit;
  String? get currentUnitId => _currentUnitId;
  LocalStorageService get localStorageService => _localStorageService;

  // Initialize local storage services
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      // Initialize local storage
      await _localStorageService.initialize();

      try {
        // Initialize notifications
        await _notificationService.initialize(
          onNotificationTap: _handleNotificationTap,
        );
      } catch (e) {
        debugPrint('Error initializing notifications: $e');
        // Continue with other initializations
      }

      try {
        // Initialize notification listener
        await _notificationListener.initialize();
      } catch (e) {
        debugPrint('Error initializing notification listener: $e');
        // Continue with other initializations
      }

      try {
        // Initialize background tasks
        await _backgroundTaskService.initialize();
      } catch (e) {
        debugPrint('Error initializing background tasks: $e');
        // Continue with other initializations
      }

      try {
        // Subscribe to unit topic
        await _notificationService.subscribeToUnitTopic();
      } catch (e) {
        debugPrint('Error subscribing to unit topic: $e');
        // Continue with other initializations
      }

      // Get current unit
      _currentUnitId = _localStorageService.currentUnitId;
      _currentUnit = _localStorageService.currentUnit;

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local storage: $e');
      // Set up fallback data
      _currentUnitId = '521BS';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Notification tapped: $data');
    // TODO: Implement navigation based on notification data
  }

  // Set current user
  Future<void> setCurrentUser(User? user, {BuildContext? context}) async {
    _currentUser = user;
    notifyListeners();

    // Initialize device management provider if user is set and context is provided
    if (user != null && context != null) {
      try {
        final deviceProvider =
            Provider.of<DeviceManagementProvider>(context, listen: false);
        if (!deviceProvider.isInitialized && !deviceProvider.isInitializing) {
          await deviceProvider.initialize(user);
        }
      } catch (e) {
        debugPrint('Error initializing device management provider: $e');
      }
    }
  }

  // Set current unit
  Future<void> setCurrentUnit(String unitId) async {
    try {
      await _localStorageService.setCurrentUnit(unitId);
      _currentUnitId = _localStorageService.currentUnitId;
      _currentUnit = _localStorageService.currentUnit;

      // Subscribe to new unit topic
      await _notificationService.subscribeToUnitTopic();

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting current unit: $e');
    }
  }

  // Sign in with username and password
  Future<User?> signInWithUsernameAndPassword(
      String username, String password) async {
    try {
      final user = await _localStorageService.signInWithUsernameAndPassword(
          username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _localStorageService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Register user
  Future<User?> registerUser(User user) async {
    try {
      final newUser = await _localStorageService.registerUser(user);
      return newUser;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return null;
    }
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      return await _localStorageService.getAllUsers();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      return await _localStorageService.getUserById(userId);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    try {
      final result = await _localStorageService.updateUser(user);

      // Update current user if it's the same user
      if (result && _currentUser != null && _currentUser!.id == user.id) {
        _currentUser = user;
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      return await _localStorageService.deleteUser(userId);
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Get all units
  Future<List<Unit>> getAllUnits() async {
    try {
      return await _localStorageService.getAllUnits();
    } catch (e) {
      debugPrint('Error getting all units: $e');
      return [];
    }
  }

  // Send notification
  Future<void> sendNotification(String title, String body,
      {String? recipientId}) async {
    try {
      if (recipientId != null) {
        await _notificationService.sendNotificationToUser(
          recipientId,
          title,
          body,
        );
      } else {
        await _notificationService.sendNotificationToUnit(
          title,
          body,
        );
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
