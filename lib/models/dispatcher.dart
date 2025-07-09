import 'package:flutter/foundation.dart';
import 'user.dart';

/// Dispatcher model extending the base User model
class Dispatcher extends User {
  final List<String> assignedDispatches;
  final List<String> completedDispatches;
  final String dispatcherCode;

  Dispatcher({
    required super.id,
    required super.name,
    required super.username,
    required super.password,
    required super.rank,
    required super.corps,
    required super.dateOfBirth,
    required super.yearOfEnlistment,
    required super.armyNumber,
    required super.unit,
    required super.unitId,
    super.isActive = true,
    super.isApproved = false,
    super.registrationDate,
    super.approvalDate,
    super.approvedBy,
    super.customPermissions,
    super.lastLogin,
    super.deviceInfo,
    super.lastLoginIp,
    this.assignedDispatches = const [],
    this.completedDispatches = const [],
    required this.dispatcherCode,
  }) : super(role: UserRole.dispatcher);

  // Create a copy with updated fields
  @override
  Dispatcher copyWith({
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
    List<String>? assignedDispatches,
    List<String>? completedDispatches,
    String? dispatcherCode,
  }) {
    return Dispatcher(
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
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      customPermissions: customPermissions ?? this.customPermissions,
      lastLogin: lastLogin ?? this.lastLogin,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      assignedDispatches: assignedDispatches ?? this.assignedDispatches,
      completedDispatches: completedDispatches ?? this.completedDispatches,
      dispatcherCode: dispatcherCode ?? this.dispatcherCode,
    );
  }

  // Convert to map for storage
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'assignedDispatches': assignedDispatches,
      'completedDispatches': completedDispatches,
      'dispatcherCode': dispatcherCode,
    };
  }

  // Create from map
  factory Dispatcher.fromMap(Map<String, dynamic> map) {
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

    return Dispatcher(
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
      assignedDispatches: List<String>.from(map['assignedDispatches'] ?? []),
      completedDispatches: List<String>.from(map['completedDispatches'] ?? []),
      dispatcherCode: map['dispatcherCode'],
    );
  }

  // Create from User
  factory Dispatcher.fromUser(
    User user, {
    List<String> assignedDispatches = const [],
    List<String> completedDispatches = const [],
    required String dispatcherCode,
  }) {
    return Dispatcher(
      id: user.id,
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
      isActive: user.isActive,
      isApproved: user.isApproved,
      registrationDate: user.registrationDate,
      approvalDate: user.approvalDate,
      approvedBy: user.approvedBy,
      customPermissions: user.customPermissions,
      lastLogin: user.lastLogin,
      deviceInfo: user.deviceInfo,
      lastLoginIp: user.lastLoginIp,
      assignedDispatches: assignedDispatches,
      completedDispatches: completedDispatches,
      dispatcherCode: dispatcherCode,
    );
  }
}
