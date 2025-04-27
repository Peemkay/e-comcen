/// Enum for user roles
enum UserRole { superadmin, admin, dispatcher }

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
        // Dispatcher can only access dispatch-related features
        return permission == Permission.viewDispatch ||
            permission == Permission.manageDispatch;
    }
  }
}

/// Enum for permissions in the application
enum Permission {
  viewAdmin,
  manageAdmin,
  viewDispatch,
  manageDispatch,
  manageUsers,
  manageUserPrivileges,
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
  final UserRole role;
  final bool isActive;
  final bool isApproved;
  final DateTime? registrationDate;
  final DateTime? approvalDate;
  final String? approvedBy;

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
    this.role = UserRole.admin,
    this.isActive = true,
    this.isApproved = false,
    this.registrationDate,
    this.approvalDate,
    this.approvedBy,
  });

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
    UserRole? role,
    bool? isActive,
    bool? isApproved,
    DateTime? registrationDate,
    DateTime? approvalDate,
    String? approvedBy,
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
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }

  // Convert user to a map for storage
  Map<String, dynamic> toMap() {
    return {
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
      'role': role.name,
      'isActive': isActive,
      'isApproved': isApproved,
      'registrationDate': registrationDate?.millisecondsSinceEpoch,
      'approvalDate': approvalDate?.millisecondsSinceEpoch,
      'approvedBy': approvedBy,
    };
  }

  // Create a user from a map
  factory User.fromMap(Map<String, dynamic> map) {
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
      role: map['role'] != null
          ? UserRole.values.firstWhere(
              (e) => e.name == map['role'],
              orElse: () => UserRole.admin,
            )
          : UserRole.admin,
      isActive: map['isActive'] ?? true,
      isApproved: map['isApproved'] ?? false,
      registrationDate: map['registrationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
          : null,
      approvalDate: map['approvalDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvalDate'])
          : null,
      approvedBy: map['approvedBy'],
    );
  }
}
