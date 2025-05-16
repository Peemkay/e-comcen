import 'package:flutter/material.dart';
import 'user.dart';
import 'dispatch_tracking.dart';

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
    super.isActive = true,
    super.isApproved = false,
    super.registrationDate,
    super.approvalDate,
    super.approvedBy,
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
    UserRole? role,
    bool? isActive,
    bool? isApproved,
    DateTime? registrationDate,
    DateTime? approvalDate,
    String? approvedBy,
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
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
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
      isActive: map['isActive'] ?? true,
      isApproved: map['isApproved'] ?? false,
      registrationDate: map['registrationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
          : null,
      approvalDate: map['approvalDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvalDate'])
          : null,
      approvedBy: map['approvedBy'],
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
      isActive: user.isActive,
      isApproved: user.isApproved,
      registrationDate: user.registrationDate,
      approvalDate: user.approvalDate,
      approvedBy: user.approvedBy,
      assignedDispatches: assignedDispatches,
      completedDispatches: completedDispatches,
      dispatcherCode: dispatcherCode,
    );
  }
}
