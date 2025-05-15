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
    super.email = '',
    required super.password,
    required super.rank,
    required super.corps,
    required super.dateOfBirth,
    required super.yearOfEnlistment,
    required super.armyNumber,
    required super.unitId,
    super.isActive = true,
    super.isApproved = false,
    super.registrationDate,
    super.approvalDate,
    super.approvedBy,
    super.photoUrl,
    super.metadata,
    super.firebaseUid,
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
    String? email,
    String? password,
    String? rank,
    String? corps,
    DateTime? dateOfBirth,
    int? yearOfEnlistment,
    String? armyNumber,
    String? unitId,
    UserRole? role,
    bool? isActive,
    bool? isApproved,
    DateTime? registrationDate,
    DateTime? approvalDate,
    String? approvedBy,
    String? photoUrl,
    Map<String, dynamic>? metadata,
    String? firebaseUid,
    List<String>? assignedDispatches,
    List<String>? completedDispatches,
    String? dispatcherCode,
  }) {
    return Dispatcher(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      rank: rank ?? this.rank,
      corps: corps ?? this.corps,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      yearOfEnlistment: yearOfEnlistment ?? this.yearOfEnlistment,
      armyNumber: armyNumber ?? this.armyNumber,
      unitId: unitId ?? this.unitId,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      registrationDate: registrationDate ?? this.registrationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
      firebaseUid: firebaseUid ?? this.firebaseUid,
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
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      rank: map['rank'] ?? '',
      corps: map['corps'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : DateTime.now(),
      yearOfEnlistment: map['yearOfEnlistment'] ?? 0,
      armyNumber: map['armyNumber'] ?? '',
      unitId: map['unitId'] ?? map['unit'] ?? '', // Support legacy 'unit' field
      isActive: map['isActive'] ?? true,
      isApproved: map['isApproved'] ?? false,
      registrationDate: map['registrationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
          : null,
      approvalDate: map['approvalDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvalDate'])
          : null,
      approvedBy: map['approvedBy'],
      photoUrl: map['photoUrl'],
      metadata: map['metadata'],
      firebaseUid: map['firebaseUid'],
      assignedDispatches: List<String>.from(map['assignedDispatches'] ?? []),
      completedDispatches: List<String>.from(map['completedDispatches'] ?? []),
      dispatcherCode: map['dispatcherCode'] ?? '',
    );
  }

  // Create from Firestore document
  factory Dispatcher.fromFirestore(
      Map<String, dynamic> map, String documentId) {
    return Dispatcher.fromMap({
      ...map,
      'id': documentId,
    });
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
      email: user.email,
      password: user.password,
      rank: user.rank,
      corps: user.corps,
      dateOfBirth: user.dateOfBirth,
      yearOfEnlistment: user.yearOfEnlistment,
      armyNumber: user.armyNumber,
      unitId: user.unitId,
      isActive: user.isActive,
      isApproved: user.isApproved,
      registrationDate: user.registrationDate,
      approvalDate: user.approvalDate,
      approvedBy: user.approvedBy,
      photoUrl: user.photoUrl,
      metadata: user.metadata,
      firebaseUid: user.firebaseUid,
      assignedDispatches: assignedDispatches,
      completedDispatches: completedDispatches,
      dispatcherCode: dispatcherCode,
    );
  }
}
