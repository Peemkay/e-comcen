import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/unit.dart';
import 'user_service.dart';

/// Service for handling local storage operations
/// This replaces the Firebase service with a local implementation
class LocalStorageService {
  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  // Current unit ID
  String? _currentUnitId = 'unit_001'; // Default value
  Unit? _currentUnit;

  // Database
  Database? _database;
  final String _usersTable = 'users';
  final String _unitsTable = 'units';
  final String _dispatchesTable = 'dispatches';
  final String _notificationsTable = 'notifications';

  // Getters
  String? get currentUnitId => _currentUnitId;
  Unit? get currentUnit => _currentUnit;

  LocalStorageService._internal();

  /// Initialize local storage services
  Future<void> initialize() async {
    debugPrint('Initializing local storage services');

    try {
      // Initialize database
      await _initDatabase();

      // Load current unit from shared preferences
      await _loadCurrentUnit();

      debugPrint('Local storage services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local storage services: $e');
      // Re-throw the exception to be handled by the caller
      rethrow;
    }
  }

  /// Get the database instance, initializing it if needed
  Future<Database> _getDatabase() async {
    if (_database == null) {
      await _initDatabase();
    }

    if (_database == null) {
      throw Exception('Failed to initialize database');
    }

    return _database!;
  }

  /// Initialize the SQLite database
  Future<void> _initDatabase() async {
    if (_database != null) return;

    try {
      // Get the database path
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'nasds.db');

      debugPrint('Opening database at: $path');

      // Open the database
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          debugPrint('Creating database tables');
          // Create users table with all necessary fields
          await db.execute('''
            CREATE TABLE $_usersTable (
              id TEXT PRIMARY KEY,
              username TEXT NOT NULL,
              password TEXT NOT NULL,
              fullName TEXT,
              name TEXT,
              email TEXT,
              phoneNumber TEXT,
              rank TEXT,
              corps TEXT,
              role TEXT,
              unitId TEXT,
              unit TEXT,
              armyNumber TEXT,
              dateOfBirth INTEGER,
              yearOfEnlistment INTEGER,
              isActive INTEGER,
              isApproved INTEGER,
              registrationDate INTEGER,
              approvalDate INTEGER,
              approvedBy TEXT,
              lastLogin TEXT,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');

          // Create units table
          await db.execute('''
            CREATE TABLE $_unitsTable (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              code TEXT NOT NULL,
              location TEXT,
              commanderId TEXT,
              parentUnitId TEXT,
              unitType TEXT,
              isPrimary INTEGER DEFAULT 0,
              description TEXT,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');

          // Create dispatches table
          await db.execute('''
            CREATE TABLE $_dispatchesTable (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT,
              senderId TEXT,
              recipientId TEXT,
              status TEXT,
              priority TEXT,
              category TEXT,
              attachmentUrls TEXT,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');

          // Create notifications table
          await db.execute('''
            CREATE TABLE $_notificationsTable (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              body TEXT,
              senderId TEXT,
              recipientId TEXT,
              isRead INTEGER,
              data TEXT,
              createdAt TEXT
            )
          ''');

          // Insert sample data
          await _insertSampleData(db);
          debugPrint('Database tables created and sample data inserted');
        },
      );

      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Insert sample data into the database
  Future<void> _insertSampleData(Database db) async {
    // Insert default unit
    await db.insert(_unitsTable, {
      'id': 'unit_001',
      'name': 'Nigerian Army School of Signals',
      'code': 'NASS',
      'location': 'Abuja',
      'commanderId': 'user_001',
      'parentUnitId': null,
      'unitType': 'headquarters',
      'isPrimary': 1,
      'description': 'Headquarters of the Nigerian Army Signal Corps',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Insert additional sample units
    await db.insert(_unitsTable, {
      'id': 'unit_002',
      'name': '521 Signal Regiment',
      'code': '521SR',
      'location': 'Lagos',
      'commanderId': null,
      'parentUnitId': 'unit_001',
      'unitType': 'forwardLink',
      'isPrimary': 0,
      'description': 'Forward link signal regiment',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await db.insert(_unitsTable, {
      'id': 'unit_003',
      'name': '522 Signal Regiment',
      'code': '522SR',
      'location': 'Port Harcourt',
      'commanderId': null,
      'parentUnitId': 'unit_001',
      'unitType': 'rearLink',
      'isPrimary': 0,
      'description': 'Rear link signal regiment',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Insert System Administrator with super admin privileges
    // SYSTEM ADMINISTRATOR CREDENTIALS:
    // Username: admin
    // Password: admin123
    await db.insert(_usersTable, {
      'id': 'user_001',
      'username': 'admin',
      'password': 'admin123', // In a real app, this would be hashed
      'fullName': 'System Administrator',
      'email': 'admin@nasds.mil.ng',
      'phoneNumber': '+2348012345678',
      'rank': 'Colonel',
      'role': 'superadmin', // System Administrator has super admin privileges
      'unitId': 'unit_001',
      'isActive': 1,
      'isApproved': 1, // Always approved
      'lastLogin': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Load current unit from shared preferences
  Future<void> _loadCurrentUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUnitId = prefs.getString('currentUnitId') ?? 'unit_001';

      // Load unit details
      if (_currentUnitId != null) {
        _currentUnit = await getUnitById(_currentUnitId!);
        debugPrint('Loaded current unit: ${_currentUnit?.name ?? "Unknown"}');
      }
    } catch (e) {
      debugPrint('Error loading current unit: $e');
      // Set default unit ID if loading fails
      _currentUnitId = 'unit_001';
    }
  }

  /// Set current unit
  Future<void> setCurrentUnit(String unitId) async {
    try {
      _currentUnitId = unitId;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUnitId', unitId);

      // Load unit details
      _currentUnit = await getUnitById(unitId);
      debugPrint('Set current unit to: ${_currentUnit?.name ?? "Unknown"}');
    } catch (e) {
      debugPrint('Error setting current unit: $e');
    }
  }

  /// Sign in with username and password
  Future<User?> signInWithUsernameAndPassword(
      String username, String password) async {
    try {
      final db = await _getDatabase();

      final result = await db.query(
        _usersTable,
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (result.isNotEmpty) {
        final userData = result.first;
        final user = User.fromMap(userData);

        // Update last login
        await db.update(
          _usersTable,
          {'lastLogin': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [user.id],
        );

        return user;
      }

      return null;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Nothing to do for local storage
    debugPrint('User signed out');
  }

  /// Register user
  Future<User?> registerUser(User user) async {
    try {
      final db = await _getDatabase();

      // Check if username already exists
      final existingUser = await db.query(
        _usersTable,
        where: 'username = ?',
        whereArgs: [user.username],
      );

      if (existingUser.isNotEmpty) {
        debugPrint('Username already exists');
        return null;
      }

      // Insert new user
      await db.insert(_usersTable, user.toMap());

      return user;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return null;
    }
  }

  /// Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final db = await _getDatabase();
      final result = await db.query(_usersTable);

      // Handle potential null values in the database
      List<User> users = [];

      // First, try to get users from the in-memory cache in UserService
      final userService = UserService();
      final cachedUsers = userService.getAllUsers();
      if (cachedUsers.isNotEmpty) {
        return cachedUsers;
      }

      // If no cached users, try to parse from database
      for (var userData in result) {
        try {
          // Check if this is a new schema user record
          if (userData['name'] != null) {
            // Ensure all required fields are present
            if (userData['id'] != null &&
                userData['name'] != null &&
                userData['username'] != null &&
                userData['password'] != null &&
                userData['rank'] != null) {
              // Handle missing fields with defaults
              final user = User(
                id: userData['id'] as String,
                name: userData['name'] as String,
                username: userData['username'] as String,
                password: userData['password'] as String,
                rank: userData['rank'] as String,
                corps: userData['corps'] as String? ?? 'Signals',
                dateOfBirth: userData['dateOfBirth'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        userData['dateOfBirth'] as int)
                    : DateTime(1980, 1, 1),
                yearOfEnlistment: userData['yearOfEnlistment'] as int? ?? 2000,
                armyNumber: userData['armyNumber'] as String? ?? 'NA/00000',
                unit: userData['unit'] as String? ??
                    'Nigerian Army School of Signals',
                unitId: userData['unitId'] as String? ?? 'unit_001',
                role: userData['role'] != null
                    ? UserRole.values.firstWhere(
                        (e) => e.name == userData['role'],
                        orElse: () => UserRole.admin,
                      )
                    : UserRole.admin,
                isActive: userData['isActive'] == null
                    ? true
                    : (userData['isActive'] is bool
                        ? userData['isActive'] as bool
                        : (userData['isActive'] as int) == 1),
                isApproved: userData['isApproved'] == null
                    ? false
                    : (userData['isApproved'] is bool
                        ? userData['isApproved'] as bool
                        : (userData['isApproved'] as int) == 1),
                registrationDate: userData['registrationDate'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        userData['registrationDate'] as int)
                    : null,
                approvalDate: userData['approvalDate'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        userData['approvalDate'] as int)
                    : null,
                approvedBy: userData['approvedBy'] as String?,
              );
              users.add(user);
            }
          }
          // Check if this is an old schema user record (from sample data)
          else if (userData['fullName'] != null) {
            // Convert old schema to new schema
            final user = User(
              id: userData['id'] as String,
              name: userData['fullName'] as String,
              username: userData['username'] as String,
              password: userData['password'] as String,
              rank: userData['rank'] as String? ?? 'Officer',
              corps: 'Signals',
              dateOfBirth: DateTime(1980, 1, 1),
              yearOfEnlistment: 2000,
              armyNumber: 'NA/00000',
              unit: 'Nigerian Army School of Signals',
              unitId: userData['unitId'] as String? ?? 'unit_001',
              role: userData['role'] != null
                  ? UserRole.values.firstWhere(
                      (e) => e.name == userData['role'],
                      orElse: () => UserRole.admin,
                    )
                  : UserRole.admin,
              isActive: userData['isActive'] == null
                  ? true
                  : (userData['isActive'] is bool
                      ? userData['isActive'] as bool
                      : (userData['isActive'] as int) == 1),
              isApproved: true,
              registrationDate: DateTime.now(),
              approvalDate: DateTime.now(),
              approvedBy: 'System',
            );
            users.add(user);
          } else {
            debugPrint(
                'Skipping user with missing required fields: ${userData['id']}');
          }
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // Skip this user and continue with the next one
        }
      }

      // If we found users in the database, return them
      if (users.isNotEmpty) {
        return users;
      }

      // If no users found, return the default users
      return _createDefaultUsers();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      // Return default users if there's an error
      return _createDefaultUsers();
    }
  }

  /// Create default users if none exist
  List<User> _createDefaultUsers() {
    final now = DateTime.now();

    return [
      // System Administrator (Super Admin)
      // SYSTEM ADMINISTRATOR CREDENTIALS:
      // Username: admin
      // Password: admin123
      User(
        id: 'sysadmin_001',
        name: 'System Administrator',
        username: 'admin',
        password: 'admin123',
        rank: 'Colonel',
        corps: 'Signals',
        dateOfBirth: DateTime(1975, 5, 15),
        yearOfEnlistment: 1995,
        armyNumber: 'NA/00001',
        unit: 'Nigerian Army School of Signals',
        unitId: 'unit_001',
        role: UserRole
            .superadmin, // System Administrator has super admin privileges
        isActive: true,
        isApproved: true,
        registrationDate: now,
        approvalDate: now,
        approvedBy: 'System',
      ),
    ];
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final db = await _getDatabase();
      final result = await db.query(
        _usersTable,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        return User.fromMap(result.first);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  /// Update user
  Future<bool> updateUser(User user) async {
    try {
      debugPrint(
          'Updating user: ${user.id}, ${user.name}, role: ${user.role.name}');
      final db = await _getDatabase();

      // Check if the user exists in the database
      final existingUser = await db.query(
        _usersTable,
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Convert user to database map
      final userMap = _convertUserToDbMap(user);

      if (existingUser.isEmpty) {
        debugPrint('User not found in database, creating new record');
        // User doesn't exist, insert instead of update
        try {
          await db.insert(_usersTable, userMap);
          debugPrint('Successfully inserted new user record');
        } catch (insertError) {
          debugPrint('Error inserting user: $insertError');
          // Print the map for debugging
          userMap.forEach((key, value) {
            debugPrint('  $key: $value (${value.runtimeType})');
          });
          rethrow;
        }
      } else {
        // Check if this is an old schema record (has fullName instead of name)
        final hasOldSchema = existingUser.first.containsKey('fullName') &&
            !existingUser.first.containsKey('name');

        if (hasOldSchema) {
          debugPrint('Converting old schema user to new schema');
          // Delete old record and insert new one
          await db.delete(
            _usersTable,
            where: 'id = ?',
            whereArgs: [user.id],
          );

          try {
            await db.insert(_usersTable, userMap);
            debugPrint('Successfully inserted converted user record');
          } catch (insertError) {
            debugPrint('Error inserting converted user: $insertError');
            // Print the map for debugging
            userMap.forEach((key, value) {
              debugPrint('  $key: $value (${value.runtimeType})');
            });
            rethrow;
          }
        } else {
          // Normal update for existing user with compatible schema
          try {
            final updateCount = await db.update(
              _usersTable,
              userMap,
              where: 'id = ?',
              whereArgs: [user.id],
            );
            debugPrint(
                'Successfully updated user record. Rows affected: $updateCount');
          } catch (updateError) {
            debugPrint('Error updating user: $updateError');
            // Print the map for debugging
            userMap.forEach((key, value) {
              debugPrint('  $key: $value (${value.runtimeType})');
            });
            rethrow;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error in updateUser method: $e');
      return false;
    }
  }

  /// Convert User model to a database-compatible map
  Map<String, dynamic> _convertUserToDbMap(User user) {
    // Create a completely new map with all fields explicitly set
    // This ensures we have full control over the data types and format
    final map = <String, dynamic>{
      'id': user.id,
      'name': user.name,
      'username': user.username,
      'password': user.password,
      'fullName': user.name, // For backward compatibility
      'rank': user.rank,
      'corps': user.corps,
      'dateOfBirth': user.dateOfBirth.millisecondsSinceEpoch,
      'yearOfEnlistment': user.yearOfEnlistment,
      'armyNumber': user.armyNumber,
      'unit': user.unit,
      'unitId': user.unitId,
      'role': user.role.name,
      // Convert boolean values to integers for SQLite compatibility
      'isActive': user.isActive ? 1 : 0,
      'isApproved': user.isApproved ? 1 : 0,
      // Add timestamps
      'updatedAt': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Add optional fields only if they're not null
    if (user.registrationDate != null) {
      map['registrationDate'] = user.registrationDate!.millisecondsSinceEpoch;
    }

    if (user.approvalDate != null) {
      map['approvalDate'] = user.approvalDate!.millisecondsSinceEpoch;
    }

    if (user.approvedBy != null) {
      map['approvedBy'] = user.approvedBy;
    }

    // Debug output to help diagnose issues
    debugPrint(
        'Converting user to DB map: ${user.id}, isActive: ${user.isActive}, isApproved: ${user.isApproved}');
    debugPrint(
        'Converted map: isActive: ${map['isActive']}, isApproved: ${map['isApproved']}');

    return map;
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      final db = await _getDatabase();

      await db.delete(
        _usersTable,
        where: 'id = ?',
        whereArgs: [userId],
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  /// Get all units
  Future<List<Unit>> getAllUnits() async {
    try {
      final db = await _getDatabase();
      final result = await db.query(_unitsTable);

      debugPrint(
          'LocalStorageService: Found ${result.length} units in database');

      if (result.isEmpty) {
        debugPrint(
            'LocalStorageService: No units found in database, inserting default units');
        // Insert default units if none exist
        await _insertDefaultUnits();

        // Query again after inserting defaults
        final newResult = await db.query(_unitsTable);
        debugPrint(
            'LocalStorageService: Inserted ${newResult.length} default units');

        return newResult.map((unitData) => Unit.fromMap(unitData)).toList();
      }

      return result.map((unitData) => Unit.fromMap(unitData)).toList();
    } catch (e) {
      debugPrint('Error getting all units: $e');

      // Return default units in memory as fallback
      return _createDefaultUnitsInMemory();
    }
  }

  /// Create default units in memory as fallback
  List<Unit> _createDefaultUnitsInMemory() {
    debugPrint('LocalStorageService: Creating default units in memory');
    return [
      Unit(
        id: 'unit_hq_default',
        name: 'Nigerian Army School of Signals',
        code: 'NASS',
        location: 'Abuja',
        unitType: UnitType.headquarters,
        isPrimary: true,
        description: 'Headquarters of the Nigerian Army Signal Corps',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Unit(
        id: 'unit_forward_default',
        name: '521 Signal Regiment',
        code: '521SR',
        location: 'Lagos',
        parentUnitId: 'unit_hq_default',
        unitType: UnitType.forwardLink,
        isPrimary: false,
        description: 'Forward link signal regiment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Unit(
        id: 'unit_rear_default',
        name: '522 Signal Regiment',
        code: '522SR',
        location: 'Port Harcourt',
        parentUnitId: 'unit_hq_default',
        unitType: UnitType.rearLink,
        isPrimary: false,
        description: 'Rear link signal regiment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Insert default units into the database
  Future<void> _insertDefaultUnits() async {
    try {
      final db = await _getDatabase();

      // Check if units table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_unitsTable'");

      if (tables.isEmpty) {
        debugPrint(
            'LocalStorageService: Units table does not exist, creating it');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_unitsTable (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            code TEXT NOT NULL,
            location TEXT,
            commanderId TEXT,
            parentUnitId TEXT,
            unitType TEXT,
            isPrimary INTEGER DEFAULT 0,
            description TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      }

      // Insert default units
      final defaultUnits = _createDefaultUnitsInMemory();

      for (final unit in defaultUnits) {
        try {
          // Check if unit already exists
          final existing = await db.query(
            _unitsTable,
            where: 'id = ?',
            whereArgs: [unit.id],
          );

          if (existing.isEmpty) {
            final unitMap = unit.toMap();
            await db.insert(_unitsTable, unitMap);
            debugPrint('LocalStorageService: Inserted unit ${unit.name}');
          }
        } catch (e) {
          debugPrint(
              'LocalStorageService: Error inserting unit ${unit.name}: $e');
        }
      }
    } catch (e) {
      debugPrint('LocalStorageService: Error inserting default units: $e');
    }
  }

  /// Get unit by ID
  Future<Unit?> getUnitById(String unitId) async {
    try {
      final db = await _getDatabase();
      final result = await db.query(
        _unitsTable,
        where: 'id = ?',
        whereArgs: [unitId],
      );

      if (result.isNotEmpty) {
        return Unit.fromMap(result.first);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting unit by ID: $e');
      return null;
    }
  }

  /// Add a new unit
  Future<bool> addUnit(Unit unit) async {
    try {
      final db = await _getDatabase();

      debugPrint('Adding unit: ${unit.name} (${unit.code})');
      debugPrint('Unit data: ${unit.toMap()}');

      // Check if unit with same code already exists
      final existingUnits = await db.query(
        _unitsTable,
        where: 'code = ?',
        whereArgs: [unit.code],
      );

      if (existingUnits.isNotEmpty) {
        debugPrint('Unit with code ${unit.code} already exists');
        return false;
      }

      // Insert the unit
      final unitMap = unit.toMap();

      // Ensure all required fields are present and have valid types
      if (unitMap['id'] == null || unitMap['id'] == '') {
        debugPrint('Unit ID is missing or empty');
        return false;
      }

      if (unitMap['name'] == null || unitMap['name'] == '') {
        debugPrint('Unit name is missing or empty');
        return false;
      }

      if (unitMap['code'] == null || unitMap['code'] == '') {
        debugPrint('Unit code is missing or empty');
        return false;
      }

      // Ensure isPrimary is an integer (0 or 1)
      if (unitMap['isPrimary'] is bool) {
        unitMap['isPrimary'] = unitMap['isPrimary'] ? 1 : 0;
      }

      try {
        final id = await db.insert(_unitsTable, unitMap);
        debugPrint('Unit inserted with row ID: $id');
        return true;
      } catch (insertError) {
        debugPrint('Error during insert operation: $insertError');
        // Print the map for debugging
        unitMap.forEach((key, value) {
          debugPrint('  $key: $value (${value?.runtimeType})');
        });
        return false;
      }
    } catch (e) {
      debugPrint('Error adding unit: $e');
      return false;
    }
  }

  /// Update an existing unit
  Future<bool> updateUnit(Unit unit) async {
    try {
      final db = await _getDatabase();

      // Check if unit exists
      final existingUnit = await getUnitById(unit.id);
      if (existingUnit == null) {
        debugPrint('Unit not found: ${unit.id}');
        return false;
      }

      // Check if another unit with the same code exists
      final existingUnits = await db.query(
        _unitsTable,
        where: 'code = ? AND id != ?',
        whereArgs: [unit.code, unit.id],
      );

      if (existingUnits.isNotEmpty) {
        debugPrint('Another unit with code ${unit.code} already exists');
        return false;
      }

      // Update the unit
      final count = await db.update(
        _unitsTable,
        unit.toMap(),
        where: 'id = ?',
        whereArgs: [unit.id],
      );

      // If this is the current unit, update the current unit
      if (_currentUnitId == unit.id) {
        _currentUnit = unit;
      }

      return count > 0;
    } catch (e) {
      debugPrint('Error updating unit: $e');
      return false;
    }
  }

  /// Delete a unit
  Future<bool> deleteUnit(String unitId) async {
    try {
      final db = await _getDatabase();

      // Check if unit exists
      final existingUnit = await getUnitById(unitId);
      if (existingUnit == null) {
        debugPrint('Unit not found: $unitId');
        return false;
      }

      // Check if this is the current unit
      if (_currentUnitId == unitId) {
        debugPrint('Cannot delete current unit');
        return false;
      }

      // Check if there are users assigned to this unit
      final usersWithUnit = await db.query(
        _usersTable,
        where: 'unitId = ?',
        whereArgs: [unitId],
      );

      if (usersWithUnit.isNotEmpty) {
        debugPrint('Cannot delete unit with assigned users');
        return false;
      }

      // Delete the unit
      final count = await db.delete(
        _unitsTable,
        where: 'id = ?',
        whereArgs: [unitId],
      );

      return count > 0;
    } catch (e) {
      debugPrint('Error deleting unit: $e');
      return false;
    }
  }

  /// Get units by type
  Future<List<Unit>> getUnitsByType(String unitType) async {
    try {
      final db = await _getDatabase();
      final result = await db.query(
        _unitsTable,
        where: 'unitType = ?',
        whereArgs: [unitType],
      );

      return result.map((unitData) => Unit.fromMap(unitData)).toList();
    } catch (e) {
      debugPrint('Error getting units by type: $e');
      return [];
    }
  }
}
