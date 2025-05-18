import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/unit.dart';

/// Service for managing unit data
class UnitService {
  // Singleton pattern
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  // In-memory cache for units
  List<Unit> _unitsCache = [];
  Unit? _primaryUnit;
  bool _isInitialized = false;

  // Storage keys
  static const String _unitsKey = 'units';
  static const String _primaryUnitIdKey = 'primary_unit_id';

  // Getters
  Unit? get primaryUnit => _primaryUnit;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing unit service...');

      // Load units from storage
      await _loadUnits();

      // If no units were loaded, create default units
      if (_unitsCache.isEmpty) {
        debugPrint('No units found, creating default units');
        await _createDefaultUnits();
      }

      // Load primary unit
      await _loadPrimaryUnit();

      _isInitialized = true;
      debugPrint(
          'Unit service initialized successfully with ${_unitsCache.length} units');
    } catch (e) {
      debugPrint('Error initializing unit service: $e');
      // Reset initialization flag to allow retry
      _isInitialized = false;

      // Try to create default units in memory if database operations failed
      if (_unitsCache.isEmpty) {
        _createDefaultUnitsInMemory();
      }

      // Rethrow to allow caller to handle
      rethrow;
    }
  }

  /// Load units from storage
  Future<void> _loadUnits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitStrings = prefs.getStringList(_unitsKey) ?? [];

      _unitsCache = [];
      for (final unitString in unitStrings) {
        try {
          final unitMap = Map<String, dynamic>.from(
              Map<String, dynamic>.from(Map.castFrom(unitString as Map)));
          final unit = Unit.fromMap(unitMap);
          _unitsCache.add(unit);
        } catch (e) {
          debugPrint('Error parsing unit: $e');
        }
      }

      debugPrint('Loaded ${_unitsCache.length} units from storage');
    } catch (e) {
      debugPrint('Error loading units: $e');
      _unitsCache = [];
    }
  }

  /// Load primary unit
  Future<void> _loadPrimaryUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final primaryUnitId = prefs.getString(_primaryUnitIdKey);

      if (primaryUnitId != null && primaryUnitId.isNotEmpty) {
        _primaryUnit = _unitsCache.firstWhere(
          (unit) => unit.id == primaryUnitId,
          orElse: () => _findPrimaryUnitInCache(),
        );
      } else {
        _primaryUnit = _findPrimaryUnitInCache();
      }

      debugPrint('Primary unit: ${_primaryUnit?.name ?? "None"}');
    } catch (e) {
      debugPrint('Error loading primary unit: $e');
      _primaryUnit = _findPrimaryUnitInCache();
    }
  }

  /// Find primary unit in cache
  Unit _findPrimaryUnitInCache() {
    // First try to find a unit marked as primary
    try {
      return _unitsCache.firstWhere((unit) => unit.isPrimary);
    } catch (e) {
      // If no primary unit found, use the first unit or create a default one
      if (_unitsCache.isNotEmpty) {
        return _unitsCache.first;
      } else {
        // Create a default unit
        final defaultUnit = Unit(
          id: 'unit_default',
          name: 'Nigerian Army School of Signals',
          code: 'NASS',
          unitType: UnitType.headquarters,
          isPrimary: true,
        );
        _unitsCache.add(defaultUnit);
        return defaultUnit;
      }
    }
  }

  /// Create default units
  Future<void> _createDefaultUnits() async {
    try {
      // Create default headquarters unit
      final hqUnit = Unit(
        id: 'unit_hq_default',
        name: 'Nigerian Army School of Signals',
        code: 'NASS',
        location: 'Abuja',
        unitType: UnitType.headquarters,
        isPrimary: true,
        description: 'Headquarters of the Nigerian Army Signal Corps',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to database
      final addedHqUnit = await addUnit(hqUnit);

      if (addedHqUnit != null) {
        // Create forward and rear link units
        final forwardUnit = Unit(
          id: 'unit_forward_default',
          name: '521 Signal Regiment',
          code: '521SR',
          location: 'Lagos',
          parentUnitId: hqUnit.id,
          unitType: UnitType.forwardLink,
          isPrimary: false,
          description: 'Forward link signal regiment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final rearUnit = Unit(
          id: 'unit_rear_default',
          name: '103 Signal Battalion',
          code: '103SB',
          location: 'Kaduna',
          parentUnitId: hqUnit.id,
          unitType: UnitType.rearLink,
          isPrimary: false,
          description: 'Rear link signal battalion',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await addUnit(forwardUnit);
        await addUnit(rearUnit);

        // Reload units to update cache
        await _loadUnits();
      } else {
        debugPrint('Failed to create default HQ unit');
      }
    } catch (e) {
      debugPrint('Error creating default units: $e');
    }
  }

  /// Create default units in memory
  void _createDefaultUnitsInMemory() {
    try {
      debugPrint('Creating default units in memory');

      // Create default headquarters unit
      final hqUnit = Unit(
        id: 'unit_hq_default',
        name: 'Nigerian Army School of Signals',
        code: 'NASS',
        location: 'Abuja',
        unitType: UnitType.headquarters,
        isPrimary: true,
        description: 'Headquarters of the Nigerian Army Signal Corps',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create forward and rear link units
      final forwardUnit = Unit(
        id: 'unit_forward_default',
        name: '521 Signal Regiment',
        code: '521SR',
        location: 'Lagos',
        parentUnitId: hqUnit.id,
        unitType: UnitType.forwardLink,
        isPrimary: false,
        description: 'Forward link signal regiment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rearUnit = Unit(
        id: 'unit_rear_default',
        name: '103 Signal Battalion',
        code: '103SB',
        location: 'Kaduna',
        parentUnitId: hqUnit.id,
        unitType: UnitType.rearLink,
        isPrimary: false,
        description: 'Rear link signal battalion',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to in-memory cache
      _unitsCache = [hqUnit, forwardUnit, rearUnit];
      _primaryUnit = hqUnit;

      debugPrint('Created ${_unitsCache.length} default units in memory');

      // Try to save these units to the database
      _saveUnitsToStorage();
    } catch (e) {
      debugPrint('Error creating default units in memory: $e');
      // Create minimal fallback
      _unitsCache = [
        Unit(
          id: 'unit_fallback_1',
          name: 'Nigerian Army School of Signals',
          code: 'NASS',
          unitType: UnitType.headquarters,
          isPrimary: true,
        ),
        Unit(
          id: 'unit_fallback_2',
          name: '521 Signal Regiment',
          code: '521SR',
          unitType: UnitType.forwardLink,
          isPrimary: false,
        ),
      ];
      _primaryUnit = _unitsCache.first;
    }
  }

  /// Save units to storage
  Future<bool> _saveUnitsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitMaps = _unitsCache.map((unit) => unit.toMap()).toList();
      final success = await prefs.setStringList(
          _unitsKey, unitMaps.map((map) => map.toString()).toList());

      debugPrint('Saved ${_unitsCache.length} units to storage: $success');
      return success;
    } catch (e) {
      debugPrint('Error saving units to storage: $e');
      return false;
    }
  }

  /// Get all units
  Future<List<Unit>> getAllUnits() async {
    try {
      // Initialize if not already initialized
      if (!_isInitialized) {
        debugPrint('UnitService not initialized, initializing now...');
        await initialize();
      }

      // Refresh cache if needed
      if (_unitsCache.isEmpty) {
        debugPrint('Unit cache is empty, loading units from storage...');
        await _loadUnits();

        // If still empty after loading, create default units
        if (_unitsCache.isEmpty) {
          debugPrint('No units found after loading, creating default units...');
          await _createDefaultUnits();

          // If still empty, create in memory
          if (_unitsCache.isEmpty) {
            debugPrint(
                'Failed to create units in database, creating in memory...');
            _createDefaultUnitsInMemory();
          }
        }
      }

      debugPrint('Returning ${_unitsCache.length} units from cache');
      return List.from(_unitsCache);
    } catch (e) {
      debugPrint('Error getting all units: $e');

      // If we have units in cache despite the error, return them
      if (_unitsCache.isNotEmpty) {
        debugPrint(
            'Returning ${_unitsCache.length} units from cache despite error');
        return List.from(_unitsCache);
      }

      // Create and return default units in memory as a last resort
      debugPrint('Creating default units in memory as fallback');
      _createDefaultUnitsInMemory();
      return List.from(_unitsCache);
    }
  }

  /// Add a new unit
  Future<Unit?> addUnit(Unit unit) async {
    try {
      // Generate a new ID if not provided
      final newUnit = unit.id.isEmpty
          ? unit.copyWith(
              id: _generateId(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : unit;

      debugPrint('Adding unit: ${newUnit.name} (${newUnit.code})');

      // If this unit is marked as primary, update all other units to not be primary
      if (newUnit.isPrimary) {
        debugPrint('New unit is marked as primary, updating other units');
        for (int i = 0; i < _unitsCache.length; i++) {
          if (_unitsCache[i].isPrimary) {
            _unitsCache[i] = _unitsCache[i].copyWith(isPrimary: false);
          }
        }
      }

      // Add to cache
      _unitsCache.add(newUnit);

      // Save to storage
      final success = await _saveUnitsToStorage();

      if (!success) {
        debugPrint('Failed to save unit to storage');
        // Remove from cache if save failed
        _unitsCache.removeWhere((u) => u.id == newUnit.id);
        return null;
      }

      debugPrint('Unit added to cache, total units: ${_unitsCache.length}');

      // If this is the first unit, set it as primary
      if (_unitsCache.length == 1) {
        await setPrimaryUnit(newUnit.id);
      } else if (newUnit.isPrimary) {
        // Update the primary unit reference
        _primaryUnit = newUnit;

        // Save primary unit ID to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_primaryUnitIdKey, newUnit.id);

        debugPrint('Set ${newUnit.name} as primary unit');
      }

      return newUnit;
    } catch (e) {
      debugPrint('Error adding unit: $e');
      return null;
    }
  }

  /// Update an existing unit
  Future<bool> updateUnit(Unit unit) async {
    try {
      debugPrint('Updating unit: ${unit.name} (${unit.code})');

      // Find the unit in the cache
      final index = _unitsCache.indexWhere((u) => u.id == unit.id);
      if (index == -1) {
        debugPrint('Unit not found in cache');
        return false;
      }

      // Update the unit with the current timestamp
      final updatedUnit = unit.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update the cache
      _unitsCache[index] = updatedUnit;

      // Save to storage
      final success = await _saveUnitsToStorage();

      if (!success) {
        debugPrint('Failed to save updated unit to storage');
        // Revert cache update if save failed
        await _loadUnits();
        return false;
      }

      // If this is the primary unit, update the primary unit reference
      if (_primaryUnit?.id == unit.id) {
        _primaryUnit = updatedUnit;
      }

      debugPrint('Unit updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating unit: $e');
      return false;
    }
  }

  /// Delete a unit
  Future<bool> deleteUnit(String unitId) async {
    try {
      debugPrint('Deleting unit with ID: $unitId');

      // Check if this is the primary unit
      if (_primaryUnit?.id == unitId) {
        debugPrint('Cannot delete primary unit');
        return false;
      }

      // Find the unit in the cache
      final index = _unitsCache.indexWhere((u) => u.id == unitId);
      if (index == -1) {
        debugPrint('Unit not found in cache');
        return false;
      }

      // Remove from cache
      _unitsCache.removeAt(index);

      // Save to storage
      final success = await _saveUnitsToStorage();

      if (!success) {
        debugPrint('Failed to save after deleting unit');
        // Revert cache update if save failed
        await _loadUnits();
        return false;
      }

      debugPrint('Unit deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting unit: $e');
      return false;
    }
  }

  /// Set a unit as the primary unit
  Future<bool> setPrimaryUnit(String unitId) async {
    try {
      debugPrint('Setting unit with ID: $unitId as primary');

      // Find the unit in the cache
      final unit = _unitsCache.firstWhere(
        (u) => u.id == unitId,
        orElse: () => throw Exception('Unit not found'),
      );

      // Update all units to not be primary
      for (int i = 0; i < _unitsCache.length; i++) {
        if (_unitsCache[i].isPrimary) {
          _unitsCache[i] = _unitsCache[i].copyWith(isPrimary: false);
        }
      }

      // Set the selected unit as primary
      final index = _unitsCache.indexWhere((u) => u.id == unitId);
      _unitsCache[index] = unit.copyWith(isPrimary: true);
      _primaryUnit = _unitsCache[index];

      // Save to storage
      final success = await _saveUnitsToStorage();

      if (!success) {
        debugPrint('Failed to save primary unit to storage');
        // Revert cache update if save failed
        await _loadUnits();
        return false;
      }

      // Save primary unit ID to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryUnitIdKey, unitId);

      debugPrint('Primary unit set successfully: ${unit.name}');
      return true;
    } catch (e) {
      debugPrint('Error setting primary unit: $e');
      return false;
    }
  }

  /// Find a unit by its code
  Future<Unit?> findUnitByCode(String code) async {
    try {
      // Initialize if not already initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Normalize code for comparison
      final normalizedCode = code.trim().toUpperCase();

      // Search in cache
      for (final unit in _unitsCache) {
        if (unit.code.trim().toUpperCase() == normalizedCode) {
          return unit;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding unit by code: $e');
      return null;
    }
  }

  /// Generate a unique ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'unit_${timestamp}_$random';
  }
}
