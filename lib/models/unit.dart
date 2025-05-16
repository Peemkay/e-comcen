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

  // Create a copy of the unit with updated fields
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

  // Convert unit to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'commanderId': commanderId,
      'parentUnitId': parentUnitId,
      'unitType': unitType.name,
      'isPrimary': isPrimary ? 1 : 0, // Convert to int for SQLite
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a unit from a map
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      code: map['code'] ??
          map['name'].toString().substring(
              0,
              map['name'].toString().length > 5
                  ? 5
                  : map['name'].toString().length),
      location: map['location'],
      commanderId: map['commanderId'],
      parentUnitId: map['parentUnitId'],
      unitType: map['unitType'] != null
          ? UnitType.values.firstWhere(
              (e) => e.name == map['unitType'],
              orElse: () => UnitType.other,
            )
          : UnitType.other,
      isPrimary: map['isPrimary'] != null
          ? (map['isPrimary'] is bool
              ? map['isPrimary']
              : map['isPrimary'] == 1)
          : false,
      description: map['description'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Get unit type display name
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
