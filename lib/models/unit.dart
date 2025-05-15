/// Model class for a military unit
class Unit {
  final String id;
  final String name;
  final String? location;
  final String? commanderId;
  final String? parentUnitId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Unit({
    required this.id,
    required this.name,
    this.location,
    this.commanderId,
    this.parentUnitId,
    this.createdAt,
    this.updatedAt,
  });

  // Create a copy of the unit with updated fields
  Unit copyWith({
    String? id,
    String? name,
    String? location,
    String? commanderId,
    String? parentUnitId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      commanderId: commanderId ?? this.commanderId,
      parentUnitId: parentUnitId ?? this.parentUnitId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert unit to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'commanderId': commanderId,
      'parentUnitId': parentUnitId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a unit from a map
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      location: map['location'],
      commanderId: map['commanderId'],
      parentUnitId: map['parentUnitId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
