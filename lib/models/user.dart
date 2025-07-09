import 'package:flutter/foundation.dart';

/// Enum for user roles
enum UserRole { superadmin, admin, dispatcher, operator, viewer }

/// Extension to get string representation of user roles
extension UserRoleExtension on UserRole {
  String get name {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.dispatcher:
        return 'Dispatcher';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superadmin:
        return 'Full access to all system features, including user management and privileges.';
      case UserRole.admin:
        return 'Administrative access to manage dispatches and users, but cannot modify user privileges.';
      case UserRole.dispatcher:
        return 'Can create, manage, and track dispatches, with access to reports.';
      case UserRole.operator:
        return 'Can view and create dispatches, but cannot modify system settings.';
      case UserRole.viewer:
        return 'Read-only access to view dispatches and reports.';
    }
  }

  /// Check if this role has permission to access a specific feature
  bool hasPermission(Permission permission) {
    switch (this) {
      case UserRole.superadmin:
        // Super admin has all permissions
        return true;
      case UserRole.admin:
        // Admin has all permissions except managing user privileges
        return permission != Permission.manageUserPrivileges;
      case UserRole.dispatcher:
        // Dispatcher can manage dispatches and view reports
        return permission == Permission.viewDispatch ||
            permission == Permission.manageDispatch ||
            permission == Permission.createDispatch ||
            permission == Permission.editDispatch ||
            permission == Permission.viewReports;
      case UserRole.operator:
        // Operator can view and create dispatches but not modify system settings
        return permission == Permission.viewDispatch ||
            permission == Permission.createDispatch ||
            permission == Permission.viewReports;
      case UserRole.viewer:
        // Viewer can only view dispatches and reports
        return permission == Permission.viewDispatch ||
            permission == Permission.viewReports;
    }
  }
}

/// Enum for permissions in the application
enum Permission {
  // Admin permissions
  viewAdmin,
  manageAdmin,

  // Dispatch permissions
  viewDispatch,
  createDispatch,
  editDispatch,
  deleteDispatch,
  manageDispatch, // Includes create, edit, delete

  // User management permissions
  viewUsers,
  createUser,
  editUser,
  deleteUser,
  manageUsers, // Includes create, edit, delete
  manageUserPrivileges,

  // Report permissions
  viewReports,
  generateReports,
  exportReports,

  // Unit management permissions
  viewUnits,
  manageUnits,

  // System settings permissions
  viewSettings,
  manageSettings,

  // Security permissions
  viewSecurityLogs,
  manageSecuritySettings,
}

/// Extension for permission utilities
extension PermissionExtension on Permission {
  /// Check if this permission is included in another permission
  bool isIncludedIn(Permission other) {
    // Specific permissions are included in their respective "manage" permissions
    if (other == Permission.manageDispatch) {
      return this == Permission.viewDispatch ||
          this == Permission.createDispatch ||
          this == Permission.editDispatch ||
          this == Permission.deleteDispatch;
    }

    if (other == Permission.manageUsers) {
      return this == Permission.viewUsers ||
          this == Permission.createUser ||
          this == Permission.editUser ||
          this == Permission.deleteUser;
    }

    if (other == Permission.manageSettings) {
      return this == Permission.viewSettings;
    }

    if (other == Permission.manageSecuritySettings) {
      return this == Permission.viewSecurityLogs;
    }

    return false;
  }
}

class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final String rank;
  final String corps;
  final DateTime dateOfBirth;
  final int yearOfEnlistment;
  final String armyNumber;
  final String unit;
  final String unitId; // Added unitId field
  final UserRole role;
  final bool isActive;
  final bool isApproved;
  final DateTime? registrationDate;
  final DateTime? approvalDate;
  final String? approvedBy;
  final Map<Permission, bool>? customPermissions; // Custom permissions override
  final DateTime? lastLogin;
  final String? deviceInfo;
  final String? lastLoginIp;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.rank,
    required this.corps,
    required this.dateOfBirth,
    required this.yearOfEnlistment,
    required this.armyNumber,
    required this.unit,
    this.unitId = '', // Default value for unitId
    this.role = UserRole.admin,
    this.isActive = true,
    this.isApproved = false,
    this.registrationDate,
    this.approvalDate,
    this.approvedBy,
    this.customPermissions,
    this.lastLogin,
    this.deviceInfo,
    this.lastLoginIp,
  });

  /// Check if user has a specific permission
  bool hasPermission(Permission permission) {
    // If user is not active or not approved, they have no permissions
    if (!isActive || (!isApproved && role != UserRole.superadmin)) {
      return false;
    }

    // Check custom permissions first if they exist
    if (customPermissions != null &&
        customPermissions!.containsKey(permission)) {
      return customPermissions![permission]!;
    }

    // Fall back to role-based permissions
    return role.hasPermission(permission);
  }

  /// Get all permissions for this user
  Map<Permission, bool> getAllPermissions() {
    final Map<Permission, bool> allPermissions = {};

    // Start with role-based permissions
    for (var permission in Permission.values) {
      allPermissions[permission] = role.hasPermission(permission);
    }

    // Override with custom permissions if they exist
    if (customPermissions != null) {
      allPermissions.addAll(customPermissions!);
    }

    return allPermissions;
  }

  // Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? rank,
    String? corps,
    DateTime? dateOfBirth,
    int? yearOfEnlistment,
    String? armyNumber,
    String? unit,
    String? unitId,
    UserRole? role,
    bool? isActive,
    bool? isApproved,
    DateTime? registrationDate,
    DateTime? approvalDate,
    String? approvedBy,
    Map<Permission, bool>? customPermissions,
    DateTime? lastLogin,
    String? deviceInfo,
    String? lastLoginIp,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      rank: rank ?? this.rank,
      corps: corps ?? this.corps,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      yearOfEnlistment: yearOfEnlistment ?? this.yearOfEnlistment,
      armyNumber: armyNumber ?? this.armyNumber,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      customPermissions: customPermissions ?? this.customPermissions,
      lastLogin: lastLogin ?? this.lastLogin,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
    );
  }

  // Convert user to a map for storage
  Map<String, dynamic> toMap() {
    // Create a map with all fields
    final map = {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'rank': rank,
      'corps': corps,
      'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
      'yearOfEnlistment': yearOfEnlistment,
      'armyNumber': armyNumber,
      'unit': unit,
      'unitId': unitId,
      'role': role.name,
      // Convert boolean values to integers for SQLite compatibility
      'isActive': isActive ? 1 : 0,
      'isApproved': isApproved ? 1 : 0,
    };

    // Add optional fields only if they're not null
    if (registrationDate != null) {
      map['registrationDate'] = registrationDate!.millisecondsSinceEpoch;
    }

    if (approvalDate != null) {
      map['approvalDate'] = approvalDate!.millisecondsSinceEpoch;
    }

    if (approvedBy != null) {
      map['approvedBy'] = approvedBy as String;
    }

    if (lastLogin != null) {
      map['lastLogin'] = lastLogin!.millisecondsSinceEpoch;
    }

    if (deviceInfo != null) {
      map['deviceInfo'] = deviceInfo as String;
    }

    if (lastLoginIp != null) {
      map['lastLoginIp'] = lastLoginIp as String;
    }

    // Add custom permissions if they exist
    if (customPermissions != null && customPermissions!.isNotEmpty) {
      final Map<String, int> permissionsMap = {};
      customPermissions!.forEach((permission, value) {
        permissionsMap[permission.name] = value ? 1 : 0;
      });
      map['customPermissions'] = permissionsMap;
    }

    return map;
  }

  // Create a user from a map
  factory User.fromMap(Map<String, dynamic> map) {
    // Parse custom permissions if they exist
    Map<Permission, bool>? customPermissions;
    if (map['customPermissions'] != null) {
      customPermissions = {};
      final permissionsMap = map['customPermissions'] as Map<String, dynamic>;
      permissionsMap.forEach((key, value) {
        try {
          final permission = Permission.values.firstWhere(
            (p) => p.name == key,
            orElse: () => throw Exception('Unknown permission: $key'),
          );
          customPermissions![permission] = value == 1 || value == true;
        } catch (e) {
          // Skip invalid permissions
          debugPrint('Error parsing permission: $key - $e');
        }
      });
    }

    return User(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      password: map['password'],
      rank: map['rank'],
      corps: map['corps'],
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth']),
      yearOfEnlistment: map['yearOfEnlistment'],
      armyNumber: map['armyNumber'],
      unit: map['unit'],
      unitId: map['unitId'] ?? '',
      role: map['role'] != null
          ? UserRole.values.firstWhere(
              (e) => e.name == map['role'],
              orElse: () => UserRole.admin,
            )
          : UserRole.admin,
      // Convert integer values back to boolean
      isActive: map['isActive'] == null
          ? true
          : (map['isActive'] is bool ? map['isActive'] : map['isActive'] == 1),
      isApproved: map['isApproved'] == null
          ? false
          : (map['isApproved'] is bool
              ? map['isApproved']
              : map['isApproved'] == 1),
      registrationDate: map['registrationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
          : null,
      approvalDate: map['approvalDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvalDate'])
          : null,
      approvedBy: map['approvedBy'],
      customPermissions: customPermissions,
      lastLogin: map['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
          : null,
      deviceInfo: map['deviceInfo'] as String?,
      lastLoginIp: map['lastLoginIp'] as String?,
    );
  }
}
