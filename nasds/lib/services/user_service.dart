import 'dart:math';
import '../models/user.dart';

/// Service for managing user data
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // In-memory storage for users (in a real app, this would use a database)
  final List<User> _users = [];

  // Initialize with sample data
  void initialize() {
    if (_users.isEmpty) {
      _generateSampleData();
    }
  }

  // Get all users
  Future<List<User>> getUsers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_users);
  }

  // Get all users (synchronous version for internal use)
  List<User> getAllUsers() {
    return List.from(_users);
  }

  // Get user by ID
  Future<User?> getUserById(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _users.firstWhere(
          (user) => user.username.toLowerCase() == username.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Add a new user
  Future<void> addUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

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
            role: user.role,
          )
        : user;

    _users.add(newUser);
  }

  // Update an existing user
  Future<void> updateUser(User updatedUser) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check if username already exists (but not for the same user)
    final existingUser = await getUserByUsername(updatedUser.username);
    if (existingUser != null && existingUser.id != updatedUser.id) {
      throw Exception('Username already exists');
    }

    final index = _users.indexWhere((user) => user.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
    } else {
      throw Exception('User not found');
    }
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _users.removeWhere((user) => user.id == id);
  }

  // Authenticate a user
  Future<User?> authenticateUser(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final user = _users.firstWhere(
        (user) =>
            user.username.toLowerCase() == username.toLowerCase() &&
            user.password == password,
      );

      // Check if user is active and approved (except for superadmin who is always approved)
      if (user.role == UserRole.superadmin ||
          (user.isActive && user.isApproved)) {
        return user;
      } else {
        // Return null if user is not active or not approved
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Approve a user
  Future<void> approveUser(String userId, String approvedBy) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        isApproved: true,
        approvalDate: DateTime.now(),
        approvedBy: approvedBy,
      );
    } else {
      throw Exception('User not found');
    }
  }

  // Toggle user active status
  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        isActive: isActive,
      );
    } else {
      throw Exception('User not found');
    }
  }

  // Get pending approval users
  Future<List<User>> getPendingApprovalUsers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return _users.where((user) => !user.isApproved).toList();
  }

  // Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Generate sample data for testing
  void _generateSampleData() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    // Create a single super admin user with placeholder credentials
    // In a production environment, this would be set up during installation
    // or through a secure registration process
    _users.add(
      User(
        id: '1',
        name: 'System Administrator',
        username: '', // Empty username - will require setup on first run
        password: '', // Empty password - will require setup on first run
        rank: 'Administrator',
        corps: 'Signals',
        dateOfBirth: DateTime(1970, 1, 1),
        yearOfEnlistment: 2000,
        armyNumber: 'ADMIN',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.superadmin,
        isActive: true,
        isApproved: true,
        registrationDate: twoWeeksAgo,
        approvalDate: twoWeeksAgo,
        approvedBy: 'System',
      ),
    );
  }
}
