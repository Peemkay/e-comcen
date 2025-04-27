class AdminUser {
  final String username;
  final String password;
  final String name;
  final String corps;
  final DateTime dateOfBirth;
  final int yearOfEnlistment;
  final String unit;
  final String rank;
  final String armyNumber;

  AdminUser({
    required this.username,
    required this.password,
    required this.name,
    required this.corps,
    required this.dateOfBirth,
    required this.yearOfEnlistment,
    required this.unit,
    required this.rank,
    required this.armyNumber,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password, // In a real app, this should be hashed
      'name': name,
      'corps': corps,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'yearOfEnlistment': yearOfEnlistment,
      'unit': unit,
      'rank': rank,
      'armyNumber': armyNumber,
    };
  }

  // Create from Map for retrieval
  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      username: map['username'],
      password: map['password'],
      name: map['name'],
      corps: map['corps'],
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      yearOfEnlistment: map['yearOfEnlistment'],
      unit: map['unit'],
      rank: map['rank'],
      armyNumber: map['armyNumber'],
    );
  }
}
