import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/unit.dart';

/// A simplified unit manager that directly interacts with the database
/// This bypasses the complex caching mechanisms in UnitService
class UnitManager {
  // Singleton pattern
  static final UnitManager _instance = UnitManager._internal();
  factory UnitManager() => _instance;
  UnitManager._internal();

  // Database
  Database? _db;
  final String _unitsTable = 'units';

  // Stream controller for unit changes
  final _unitChangesController = StreamController<bool>.broadcast();
  Stream<bool> get unitChanges => _unitChangesController.stream;

  // Flag to track initialization
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the unit manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('UnitManager: Initializing...');

      // Open the database
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'nasds.db');

      debugPrint('UnitManager: Opening database at $path');
      _db = await openDatabase(path);

      // Check if units table exists
      final tables = await _db!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_unitsTable'");
      if (tables.isEmpty) {
        debugPrint('UnitManager: Units table not found!');
        throw Exception('Units table not found in database');
      }

      _isInitialized = true;
      debugPrint('UnitManager: Initialized successfully');
    } catch (e) {
      debugPrint('UnitManager: Error initializing: $e');
      rethrow;
    }
  }

  /// Get all units directly from the database
  Future<List<Unit>> getAllUnits() async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('UnitManager: Getting all units directly from database');

      // Query all units
      final result = await _db!.query(_unitsTable);

      debugPrint('UnitManager: Found ${result.length} units in database');

      // Print all units for debugging
      if (result.isNotEmpty) {
        debugPrint('UnitManager: Units in database:');
        for (var i = 0; i < result.length; i++) {
          final unit = result[i];
          debugPrint(
              '  Unit ${i + 1}: ID=${unit['id']}, Name=${unit['name']}, Code=${unit['code']}');
        }
      }

      // Convert to Unit objects
      final units = result.map((unitData) => Unit.fromMap(unitData)).toList();
      return units;
    } catch (e) {
      debugPrint('UnitManager: Error getting all units: $e');
      return [];
    }
  }

  /// Add a new unit directly to the database - ENHANCED DEBUGGING
  Future<Unit?> addUnit(Unit unit) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint(
          'UnitManager: Adding unit directly to database: ${unit.name} (${unit.code})');

      // Generate a new ID if not provided
      final newUnit = unit.id.isEmpty
          ? unit.copyWith(
              id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : unit;

      debugPrint('UnitManager: Unit ID: ${newUnit.id}');
      debugPrint('UnitManager: Unit data to insert:');
      final unitMap = newUnit.toMap();
      unitMap.forEach((key, value) {
        debugPrint('  $key: $value (${value?.runtimeType})');
      });

      // Check if the database is open
      if (_db == null) {
        debugPrint('UnitManager: Database is null! Reinitializing...');
        await initialize();
        if (_db == null) {
          debugPrint('UnitManager: Failed to initialize database!');
          return null;
        }
      }

      // Check if the units table exists
      final tables = await _db!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$_unitsTable'");
      if (tables.isEmpty) {
        debugPrint('UnitManager: Units table not found in database!');
        return null;
      }

      debugPrint('UnitManager: Units table exists, proceeding with insert');

      // Use direct SQL query for maximum control
      try {
        // First, check if a unit with this ID already exists
        final existingUnit = await _db!.query(
          _unitsTable,
          where: 'id = ?',
          whereArgs: [newUnit.id],
        );

        if (existingUnit.isNotEmpty) {
          debugPrint(
              'UnitManager: Unit with ID ${newUnit.id} already exists, updating');

          // Update the existing unit
          final updateCount = await _db!.update(
            _unitsTable,
            unitMap,
            where: 'id = ?',
            whereArgs: [newUnit.id],
          );

          debugPrint('UnitManager: Updated $updateCount rows');

          if (updateCount > 0) {
            // Notify listeners
            _unitChangesController.add(true);
            return newUnit;
          } else {
            debugPrint('UnitManager: Failed to update unit');
            return null;
          }
        } else {
          debugPrint(
              'UnitManager: Unit with ID ${newUnit.id} does not exist, inserting new');

          // Insert the new unit
          final insertId = await _db!.insert(_unitsTable, unitMap);

          debugPrint('UnitManager: Inserted with row ID: $insertId');

          if (insertId > 0) {
            // Verify the unit was added
            final verifyQuery = await _db!.query(
              _unitsTable,
              where: 'id = ?',
              whereArgs: [newUnit.id],
            );

            if (verifyQuery.isNotEmpty) {
              debugPrint(
                  'UnitManager: Verified unit was added: ${verifyQuery.first}');

              // Notify listeners
              _unitChangesController.add(true);

              return newUnit;
            } else {
              debugPrint('UnitManager: Failed to verify unit was added');
              return null;
            }
          } else {
            debugPrint('UnitManager: Failed to insert unit');
            return null;
          }
        }
      } catch (sqlError) {
        debugPrint('UnitManager: SQL error: $sqlError');

        // Try one more time with INSERT OR REPLACE as fallback
        try {
          debugPrint('UnitManager: Trying INSERT OR REPLACE as fallback');

          final id = await _db!.rawInsert('''
            INSERT OR REPLACE INTO $_unitsTable (
              id, name, code, location, commanderId, parentUnitId,
              unitType, isPrimary, description, createdAt, updatedAt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', [
            newUnit.id,
            newUnit.name,
            newUnit.code,
            newUnit.location,
            newUnit.commanderId,
            newUnit.parentUnitId,
            newUnit.unitType.name,
            newUnit.isPrimary ? 1 : 0,
            newUnit.description,
            newUnit.createdAt?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ]);

          debugPrint('UnitManager: Unit inserted/replaced with row ID: $id');

          // Notify listeners
          _unitChangesController.add(true);

          return newUnit;
        } catch (fallbackError) {
          debugPrint('UnitManager: Fallback error: $fallbackError');
          return null;
        }
      }
    } catch (e) {
      debugPrint('UnitManager: Error adding unit: $e');
      return null;
    }
  }

  /// Update an existing unit directly in the database
  Future<bool> updateUnit(Unit unit) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint(
          'UnitManager: Updating unit directly in database: ${unit.name} (${unit.code})');

      // Use INSERT OR REPLACE to handle the update
      final id = await _db!.rawInsert('''
        INSERT OR REPLACE INTO $_unitsTable (
          id, name, code, location, commanderId, parentUnitId,
          unitType, isPrimary, description, createdAt, updatedAt
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
        unit.id,
        unit.name,
        unit.code,
        unit.location,
        unit.commanderId,
        unit.parentUnitId,
        unit.unitType.name,
        unit.isPrimary ? 1 : 0,
        unit.description,
        unit.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ]);

      debugPrint('UnitManager: Unit updated with row ID: $id');

      // Notify listeners
      _unitChangesController.add(true);

      return true;
    } catch (e) {
      debugPrint('UnitManager: Error updating unit: $e');
      return false;
    }
  }

  /// Delete a unit directly from the database
  Future<bool> deleteUnit(String unitId) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('UnitManager: Deleting unit directly from database: $unitId');

      // Delete the unit
      final count = await _db!.delete(
        _unitsTable,
        where: 'id = ?',
        whereArgs: [unitId],
      );

      debugPrint('UnitManager: Deleted $count units');

      // Notify listeners
      _unitChangesController.add(true);

      return count > 0;
    } catch (e) {
      debugPrint('UnitManager: Error deleting unit: $e');
      return false;
    }
  }

  /// Manually notify listeners about unit changes
  void notifyUnitChanges() {
    debugPrint('UnitManager: Manually notifying about unit changes');
    _unitChangesController.add(true);
  }

  /// Dispose the unit manager
  void dispose() {
    _unitChangesController.close();
  }
}
