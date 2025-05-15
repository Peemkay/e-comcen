import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'local_storage_service.dart';

/// Service for managing user data
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Local storage service
  final LocalStorageService _localStorageService = LocalStorageService();

  // In-memory cache for users
  List<User> _usersCache = [];
  bool _isInitialized = false;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local storage
      await _localStorageService.initialize();

      // Load users from local storage
      _usersCache = await _localStorageService.getAllUsers();

      // Create default super admin if no users exist or if we can't find the default admin users
      bool hasSuperAdmin = false;
      bool hasAdmin = false;

      for (final user in _usersCache) {
        if (user.username == 'superadmin') hasSuperAdmin = true;
        if (user.username == 'admin') hasAdmin = true;
      }

      if (_usersCache.isEmpty || !hasSuperAdmin || !hasAdmin) {
        debugPrint('Creating default users because some are missing');
        await _createDefaultSuperAdmin();
        // Reload users after creating default admin
        _usersCache = await _localStorageService.getAllUsers();
      }

      // Debug output to verify users
      for (final user in _usersCache) {
        debugPrint(
            'User in cache: ${user.username}, role: ${user.role.name}, active: ${user.isActive}, approved: ${user.isApproved}');
      }

      _isInitialized = true;
      debugPrint('UserService initialized with ${_usersCache.length} users');
    } catch (e) {
      debugPrint('Error initializing UserService: $e');
      // Create default super admin in memory if initialization fails
      _createDefaultSuperAdminInMemory();

      // Debug output for in-memory users
      for (final user in _usersCache) {
        debugPrint(
            'In-memory user: ${user.username}, role: ${user.role.name}, active: ${user.isActive}, approved: ${user.isApproved}');
      }
    }
  }

  // Get all users
  Future<List<User>> getUsers() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get users from local storage
      _usersCache = await _localStorageService.getAllUsers();
      return List.from(_usersCache);
    } catch (e) {
      debugPrint('Error getting users: $e');
      return List.from(
          _usersCache); // Return cached users if local storage fails
    }
  }

  // Get all users (synchronous version for internal use)
  List<User> getAllUsers() {
    return List.from(_usersCache);
  }

  // Get user by ID
  Future<User?> getUserById(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Try to get from local storage first
      final user = await _localStorageService.getUserById(id);
      if (user != null) {
        return user;
      }

      // Fall back to cache if not found in local storage
      return _usersCache.firstWhere((user) => user.id == id);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Search in cache first for performance
      for (final user in _usersCache) {
        if (user.username.toLowerCase() == username.toLowerCase()) {
          return user;
        }
      }

      // If not found in cache, refresh cache from local storage
      _usersCache = await _localStorageService.getAllUsers();

      // Try again with refreshed cache
      for (final user in _usersCache) {
        if (user.username.toLowerCase() == username.toLowerCase()) {
          return user;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user by username: $e');
      return null;
    }
  }

  // Add a new user
  Future<void> addUser(User user) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if username already exists
      final existingUser = await getUserByUsername(user.username);
      if (existingUser != null) {
        throw Exception('Username already exists');
      }

      // Generate a new ID if not provided
      final newUser = user.id.isEmpty
          ? User(
              id: _generateId(),
              name: user.name,
              username: user.username,
              password: user.password,
              rank: user.rank,
              corps: user.corps,
              dateOfBirth: user.dateOfBirth,
              yearOfEnlistment: user.yearOfEnlistment,
              armyNumber: user.armyNumber,
              unit: user.unit,
              unitId: user.unitId,
              role: user.role,
              isActive: user.isActive,
              isApproved: user.isApproved,
              registrationDate: user.registrationDate,
              approvalDate: user.approvalDate,
              approvedBy: user.approvedBy,
            )
          : user;

      // Add to local storage
      final registeredUser = await _localStorageService.registerUser(newUser);
      if (registeredUser == null) {
        throw Exception('Failed to register user in local storage');
      }

      // Update cache
      _usersCache.add(registeredUser);
    } catch (e) {
      debugPrint('Error adding user: $e');
      throw Exception('Failed to add user: $e');
    }
  }

  // Update an existing user
  Future<void> updateUser(User updatedUser) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check if username already exists (but not for the same user)
      final existingUser = await getUserByUsername(updatedUser.username);
      if (existingUser != null && existingUser.id != updatedUser.id) {
        throw Exception('Username already exists');
      }

      // Update in local storage
      final success = await _localStorageService.updateUser(updatedUser);
      if (!success) {
        throw Exception('Failed to update user in local storage');
      }

      // Update cache
      final index = _usersCache.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        _usersCache[index] = updatedUser;
      } else {
        _usersCache.add(updatedUser);
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Delete from local storage
      final success = await _localStorageService.deleteUser(id);
      if (!success) {
        throw Exception('Failed to delete user from local storage');
      }

      // Update cache
      _usersCache.removeWhere((user) => user.id == id);
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Authenticate a user
  Future<User?> authenticateUser(String username, String password) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('Attempting to authenticate user: $username');

      // No default credentials - all users must be properly registered

      // Try to authenticate with local storage
      final user = await _localStorageService.signInWithUsernameAndPassword(
          username, password);

      if (user != null) {
        debugPrint(
            'User found in local storage: ${user.username}, role: ${user.role.name}, active: ${user.isActive}, approved: ${user.isApproved}');

        // Check if user is active and approved (except for superadmin who is always approved)
        if (user.role == UserRole.superadmin ||
            (user.isActive && user.isApproved)) {
          // Update cache if needed
          final index = _usersCache.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _usersCache[index] = user;
          } else {
            _usersCache.add(user);
          }

          return user;
        } else {
          debugPrint(
              'User not active or approved: ${user.username}, active: ${user.isActive}, approved: ${user.isApproved}');
        }
      } else {
        debugPrint('User not found in local storage');
      }

      // If local storage authentication fails, try cache as fallback
      for (final cachedUser in _usersCache) {
        if (cachedUser.username.toLowerCase() == username.toLowerCase() &&
            cachedUser.password == password) {
          debugPrint(
              'User found in cache: ${cachedUser.username}, role: ${cachedUser.role.name}, active: ${cachedUser.isActive}, approved: ${cachedUser.isApproved}');

          if (cachedUser.role == UserRole.superadmin ||
              (cachedUser.isActive && cachedUser.isApproved)) {
            return cachedUser;
          } else {
            debugPrint(
                'Cached user not active or approved: ${cachedUser.username}, active: ${cachedUser.isActive}, approved: ${cachedUser.isApproved}');
          }
        }
      }

      debugPrint('Authentication failed for user: $username');
      return null;
    } catch (e) {
      debugPrint('Error authenticating user: $e');
      return null;
    }
  }

  // Approve a user
  Future<void> approveUser(String userId, String approvedBy) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get the user
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Update user with approval info
      final updatedUser = user.copyWith(
        isApproved: true,
        approvalDate: DateTime.now(),
        approvedBy: approvedBy,
      );

      // Update in local storage
      await updateUser(updatedUser);
    } catch (e) {
      debugPrint('Error approving user: $e');
      throw Exception('Failed to approve user: $e');
    }
  }

  // Toggle user active status
  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get the user
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      // Update user with active status
      final updatedUser = user.copyWith(
        isActive: isActive,
      );

      // Update in local storage
      await updateUser(updatedUser);
    } catch (e) {
      debugPrint('Error toggling user active status: $e');
      throw Exception('Failed to toggle user active status: $e');
    }
  }

  // Get pending approval users
  Future<List<User>> getPendingApprovalUsers() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get all users
      final allUsers = await getUsers();

      // Filter for pending approval
      return allUsers.where((user) => !user.isApproved).toList();
    } catch (e) {
      debugPrint('Error getting pending approval users: $e');
      return [];
    }
  }

  // Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Create default super admin account
  Future<void> _createDefaultSuperAdmin() async {
    final now = DateTime.now();

    // Create a super admin user with default credentials
    final superAdmin = User(
      id: 'superadmin_001',
      name: 'System Administrator',
      username: 'superadmin', // Default superadmin username
      password: 'superadmin123', // Default superadmin password
      rank: 'Administrator',
      corps: 'Signals',
      dateOfBirth: DateTime(1970, 1, 1),
      yearOfEnlistment: 2000,
      armyNumber: 'ADMIN',
      unit: 'Nigerian Army School of Signals',
      unitId: 'unit_001', // Default unit ID
      role: UserRole
          .superadmin, // Has all permissions including managing user privileges
      isActive: true,
      isApproved: true,
      registrationDate: now,
      approvalDate: now,
      approvedBy: 'System',
    );

    try {
      // Register in local storage
      final registeredUser =
          await _localStorageService.registerUser(superAdmin);
      if (registeredUser == null) {
        throw Exception('Failed to register super admin in local storage');
      }

      // Add to in-memory cache as well
      _usersCache.add(superAdmin);

      debugPrint(
          'Created default super admin account with username: superadmin');
    } catch (e) {
      debugPrint('Error creating default super admin: $e');
      _createDefaultSuperAdminInMemory();
    }

    // No additional default users are created
    // Users will need to be created through the registration process
  }

  // Create placeholder admin user in memory (fallback if local storage fails)
  void _createDefaultSuperAdminInMemory() {
    final now = DateTime.now();

    // Create a super admin user with default credentials
    final superAdmin = User(
      id: 'superadmin_001',
      name: 'System Administrator',
      username: 'superadmin', // Default superadmin username
      password: 'superadmin123', // Default superadmin password
      rank: 'Administrator',
      corps: 'Signals',
      dateOfBirth: DateTime(1970, 1, 1),
      yearOfEnlistment: 2000,
      armyNumber: 'ADMIN',
      unit: 'Nigerian Army School of Signals',
      unitId: 'unit_001', // Default unit ID
      role: UserRole
          .superadmin, // Has all permissions including managing user privileges
      isActive: true,
      isApproved: true,
      registrationDate: now,
      approvalDate: now,
      approvedBy: 'System',
    );

    // Add to in-memory cache
    _usersCache.add(superAdmin);
    debugPrint(
        'Created default superadmin account in memory with username: superadmin');
  }
}
