import '../models/user.dart';
import 'user_service.dart';

/// Service for handling authentication
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final UserService _userService = UserService();

  User? _currentUser;

  // Get the current logged in user
  User? get currentUser => _currentUser;

  // Check if a user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Check if current user is a super admin
  bool get isSuperAdmin => _currentUser?.role == UserRole.superadmin;

  // Check if current user is an admin
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // Check if current user is a dispatcher
  bool get isDispatcher => _currentUser?.role == UserRole.dispatcher;

  // Check if current user has a specific permission
  bool hasPermission(Permission permission) {
    if (_currentUser == null) return false;
    return _currentUser!.role.hasPermission(permission);
  }

  // Initialize the service
  Future<void> initialize() async {
    await _userService.initialize();
  }

  // Get the user service (for internal use)
  UserService getUserService() {
    return _userService;
  }

  // Set the current user (for testing/debugging)
  void setCurrentUser(User user) {
    _currentUser = user;
  }

  // Logout the current user
  void logout() {
    _currentUser = null;
  }

  // Login with username and password
  Future<User?> login(String username, String password) async {
    final user = await _userService.authenticateUser(username, password);
    if (user != null) {
      _currentUser = user;
    }
    return user;
  }

  // Login with username and password for specific role
  Future<User?> loginWithRole(
      String username, String password, UserRole requiredRole) async {
    final user = await _userService.authenticateUser(username, password);
    if (user != null && user.role == requiredRole) {
      _currentUser = user;
      return user;
    }
    return null;
  }

  // Register a new user
  Future<User?> register(User user) async {
    // Set registration date
    final userWithDate = user.copyWith(
      registrationDate: DateTime.now(),
      isApproved: false, // New users are not approved by default
      isActive: true, // But they are active
    );

    // We don't catch exceptions here so they can be properly handled by the caller
    await _userService.addUser(userWithDate);
    return userWithDate;
  }

  // Approve a user (only super admin can do this)
  Future<bool> approveUser(String userId) async {
    if (!isSuperAdmin) return false;

    try {
      await _userService.approveUser(userId, _currentUser!.name);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle user active status (only super admin can do this)
  Future<bool> toggleUserActiveStatus(String userId, bool isActive) async {
    if (!isSuperAdmin) return false;

    try {
      await _userService.toggleUserActiveStatus(userId, isActive);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get pending approval users (only super admin can do this)
  Future<List<User>> getPendingApprovalUsers() async {
    if (!isSuperAdmin) return [];

    try {
      return await _userService.getPendingApprovalUsers();
    } catch (e) {
      return [];
    }
  }

  // Update the current user's profile
  Future<bool> updateProfile(User updatedUser) async {
    try {
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Change the current user's password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_currentUser == null) {
      return false;
    }

    // Verify current password
    if (_currentUser!.password != currentPassword) {
      return false;
    }

    try {
      final updatedUser = _currentUser!.copyWith(password: newPassword);
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      return false;
    }
  }
}
