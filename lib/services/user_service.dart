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

    _users.addAll([
      // Super Admin user (always approved and active)
      User(
        id: '1',
        name: 'Super Admin',
        username: 'super',
        password: 'super123',
        rank: 'Brigadier General',
        corps: 'Signals',
        dateOfBirth: DateTime(1970, 3, 10),
        yearOfEnlistment: 1990,
        armyNumber: 'NA/10001',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.superadmin,
        isActive: true,
        isApproved: true,
        registrationDate: twoWeeksAgo,
        approvalDate: twoWeeksAgo,
        approvedBy: 'System',
      ),

      // Admin users (approved and active)
      User(
        id: '2',
        name: 'Admin User',
        username: 'admin',
        password: 'admin123',
        rank: 'Colonel',
        corps: 'Signals',
        dateOfBirth: DateTime(1975, 5, 15),
        yearOfEnlistment: 1995,
        armyNumber: 'NA/12345',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.admin,
        isActive: true,
        isApproved: true,
        registrationDate: twoWeeksAgo,
        approvalDate: twoWeeksAgo,
        approvedBy: 'Super Admin',
      ),
      User(
        id: '3',
        name: 'John Doe',
        username: 'johndoe',
        password: 'password123',
        rank: 'Captain',
        corps: 'Signals',
        dateOfBirth: DateTime(1985, 8, 22),
        yearOfEnlistment: 2005,
        armyNumber: 'NA/23456',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.admin,
        isActive: true,
        isApproved: true,
        registrationDate: twoWeeksAgo,
        approvalDate: twoWeeksAgo,
        approvedBy: 'Super Admin',
      ),

      // Admin user (inactive but approved)
      User(
        id: '4',
        name: 'Jane Smith',
        username: 'janesmith',
        password: 'password123',
        rank: 'Lieutenant',
        corps: 'Signals',
        dateOfBirth: DateTime(1990, 3, 10),
        yearOfEnlistment: 2012,
        armyNumber: 'NA/34567',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.admin,
        isActive: false,
        isApproved: true,
        registrationDate: twoWeeksAgo,
        approvalDate: twoWeeksAgo,
        approvedBy: 'Super Admin',
      ),

      // Dispatcher users (approved and active)
      User(
        id: '5',
        name: 'Ibrahim Mohammed',
        username: 'ibrahim',
        password: 'dispatcher123',
        rank: 'Sergeant',
        corps: 'Signals',
        dateOfBirth: DateTime(1988, 11, 5),
        yearOfEnlistment: 2008,
        armyNumber: '08NA/44/5678',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.dispatcher,
        isActive: true,
        isApproved: true,
        registrationDate: oneWeekAgo,
        approvalDate: oneWeekAgo,
        approvedBy: 'Admin User',
      ),
      User(
        id: '6',
        name: 'Chukwu Emeka',
        username: 'emeka',
        password: 'dispatcher123',
        rank: 'Corporal',
        corps: 'Signals',
        dateOfBirth: DateTime(1992, 7, 18),
        yearOfEnlistment: 2012,
        armyNumber: '12NA/44/7890',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.dispatcher,
        isActive: true,
        isApproved: true,
        registrationDate: oneWeekAgo,
        approvalDate: oneWeekAgo,
        approvedBy: 'Admin User',
      ),

      // Dispatcher (pending approval)
      User(
        id: '7',
        name: 'Aisha Bello',
        username: 'aisha',
        password: 'dispatcher123',
        rank: 'Sergeant',
        corps: 'Signals',
        dateOfBirth: DateTime(1990, 4, 12),
        yearOfEnlistment: 2010,
        armyNumber: '10NA/44/6543',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.dispatcher,
        isActive: true,
        isApproved: false,
        registrationDate: now,
        approvalDate: null,
        approvedBy: null,
      ),

      // Test dispatcher (approved and active)
      User(
        id: '8',
        name: 'Test Dispatcher',
        username: 'dispatcher',
        password: 'dispatcher',
        rank: 'Corporal',
        corps: 'Signals',
        dateOfBirth: DateTime(1995, 6, 15),
        yearOfEnlistment: 2015,
        armyNumber: '15NA/44/8765',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.dispatcher,
        isActive: true,
        isApproved: true,
        registrationDate: oneWeekAgo,
        approvalDate: oneWeekAgo,
        approvedBy: 'Super Admin',
      ),

      // New user (pending approval)
      User(
        id: '9',
        name: 'New User',
        username: 'newuser',
        password: 'password123',
        rank: 'Lieutenant',
        corps: 'Signals',
        dateOfBirth: DateTime(1993, 9, 25),
        yearOfEnlistment: 2018,
        armyNumber: 'NA/45678',
        unit: 'Nigerian Army School of Signals',
        role: UserRole.admin,
        isActive: true,
        isApproved: false,
        registrationDate: now,
        approvalDate: null,
        approvedBy: null,
      ),
    ]);
  }
}
