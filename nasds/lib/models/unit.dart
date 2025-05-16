/// Enum for unit types
enum UnitType {
  forwardLink,
  rearLink,
  headquarters,
  other,
}

/// Model class for a military unit
class Unit {
  final String id;
  final String name;
  final String code; // Unit code/formation code
  final String? location;
  final String? commanderId;
  final String? parentUnitId;
  final UnitType unitType;
  final bool isPrimary; // Whether this is the user's primary unit
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Unit({
    required this.id,
    required this.name,
    required this.code,
    this.location,
    this.commanderId,
    this.parentUnitId,
    this.unitType = UnitType.other,
    this.isPrimary = false,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a copy with updated fields
  Unit copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    String? commanderId,
    String? parentUnitId,
    UnitType? unitType,
    bool? isPrimary,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      commanderId: commanderId ?? this.commanderId,
      parentUnitId: parentUnitId ?? this.parentUnitId,
      unitType: unitType ?? this.unitType,
      isPrimary: isPrimary ?? this.isPrimary,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'commanderId': commanderId,
      'parentUnitId': parentUnitId,
      'unitType': unitType.index,
      'isPrimary': isPrimary ? 1 : 0,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from map
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      location: map['location'] as String?,
      commanderId: map['commanderId'] as String?,
      parentUnitId: map['parentUnitId'] as String?,
      unitType: UnitType.values[map['unitType'] as int],
      isPrimary: (map['isPrimary'] as int) == 1,
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Get display name for unit type
  String get unitTypeDisplay {
    switch (unitType) {
      case UnitType.forwardLink:
        return 'Forward Link';
      case UnitType.rearLink:
        return 'Rear Link';
      case UnitType.headquarters:
        return 'Headquarters';
      case UnitType.other:
        return 'Other';
    }
  }
}
