import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/unit.dart';
import 'local_storage_service.dart';

/// Service for managing unit data
class UnitService {
  // Singleton pattern
  static final UnitService _instance = UnitService._internal();
  factory UnitService() => _instance;
  UnitService._internal();

  // Local storage service
  final LocalStorageService _localStorageService = LocalStorageService();

  // In-memory cache for units
  List<Unit> _unitsCache = [];
  Unit? _primaryUnit;
  bool _isInitialized = false;

  // Getters
  Unit? get primaryUnit => _primaryUnit;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    // If already initialized, return immediately
    if (_isInitialized) {
      debugPrint('Unit service already initialized');
      return;
    }

    try {
      debugPrint('Initializing unit service...');

      // Initialize local storage service
      await _localStorageService.initialize();

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

  /// Create default units in the database
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
        debugPrint('Default HQ unit created successfully');

        // Create additional units
        final forwardUnit = Unit(
          id: 'unit_forward_default',
          name: '521 Signal Regiment',
          code: '521SR',
          location: 'Lagos',
          parentUnitId: addedHqUnit.id,
          unitType: UnitType.forwardLink,
          isPrimary: false,
          description: 'Forward link signal regiment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final rearUnit = Unit(
          id: 'unit_rear_default',
          name: '522 Signal Regiment',
          code: '522SR',
          location: 'Port Harcourt',
          parentUnitId: addedHqUnit.id,
          unitType: UnitType.rearLink,
          isPrimary: false,
          description: 'Rear link signal regiment',
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

  /// Create default units in memory if database operations failed
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

      // Create additional units
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
        name: '522 Signal Regiment',
        code: '522SR',
        location: 'Port Harcourt',
        parentUnitId: hqUnit.id,
        unitType: UnitType.rearLink,
        isPrimary: false,
        description: 'Rear link signal regiment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add more units for better selection options
      final additionalUnits = [
        Unit(
          id: 'unit_additional_1',
          name: '523 Signal Regiment',
          code: '523SR',
          location: 'Kaduna',
          parentUnitId: hqUnit.id,
          unitType: UnitType.forwardLink,
          isPrimary: false,
          description: 'Forward link signal regiment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Unit(
          id: 'unit_additional_2',
          name: '524 Signal Regiment',
          code: '524SR',
          location: 'Enugu',
          parentUnitId: hqUnit.id,
          unitType: UnitType.rearLink,
          isPrimary: false,
          description: 'Rear link signal regiment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Unit(
          id: 'unit_additional_3',
          name: 'Nigerian Defence Academy',
          code: 'NDA',
          location: 'Kaduna',
          unitType: UnitType.headquarters,
          isPrimary: false,
          description: 'Military university',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Add to in-memory cache
      _unitsCache = [hqUnit, forwardUnit, rearUnit, ...additionalUnits];
      _primaryUnit = hqUnit;

      debugPrint('Created ${_unitsCache.length} default units in memory');

      // Try to save these units to the database
      _saveUnitsToDatabase();
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

  /// Save in-memory units to database
  Future<void> _saveUnitsToDatabase() async {
    try {
      for (final unit in _unitsCache) {
        await _localStorageService.addUnit(unit);
      }
      debugPrint('Saved ${_unitsCache.length} units to database');
    } catch (e) {
      debugPrint('Error saving units to database: $e');
    }
  }

  /// Load all units from storage
  Future<void> _loadUnits() async {
    try {
      _unitsCache = await _localStorageService.getAllUnits();
      debugPrint('Loaded ${_unitsCache.length} units');
    } catch (e) {
      debugPrint('Error loading units: $e');
      _unitsCache = [];
    }
  }

  /// Load primary unit from preferences
  Future<void> _loadPrimaryUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final primaryUnitId = prefs.getString('primaryUnitId');

      if (primaryUnitId != null) {
        _primaryUnit = await getUnitById(primaryUnitId);
        debugPrint('Loaded primary unit: ${_primaryUnit?.name ?? "Unknown"}');
      } else if (_unitsCache.isNotEmpty) {
        // Set first unit as primary if none is set
        _primaryUnit = _unitsCache.first;
        await setPrimaryUnit(_primaryUnit!.id);
      }
    } catch (e) {
      debugPrint('Error loading primary unit: $e');
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

  /// Get unit by ID
  Future<Unit?> getUnitById(String unitId) async {
    if (!_isInitialized) await initialize();

    try {
      // Check cache first
      final cachedUnit = _unitsCache.firstWhere(
        (unit) => unit.id == unitId,
        orElse: () => throw Exception('Unit not found in cache'),
      );
      return cachedUnit;
    } catch (_) {
      // If not in cache, try to get from storage
      try {
        final unit = await _localStorageService.getUnitById(unitId);
        if (unit != null) {
          // Update cache
          _unitsCache.removeWhere((u) => u.id == unitId);
          _unitsCache.add(unit);
        }
        return unit;
      } catch (e) {
        debugPrint('Error getting unit by ID: $e');
        return null;
      }
    }
  }

  /// Get units by type
  Future<List<Unit>> getUnitsByType(UnitType type) async {
    try {
      debugPrint('Getting units by type: ${type.name}');

      // Get all units first
      final units = await getAllUnits();

      // Filter by type
      final filteredUnits =
          units.where((unit) => unit.unitType == type).toList();
      debugPrint('Found ${filteredUnits.length} units of type ${type.name}');

      // If no units of this type, create some default units of this type
      if (filteredUnits.isEmpty) {
        debugPrint(
            'No units found of type ${type.name}, creating default units of this type');

        // Create default units of the requested type
        final defaultUnits = _createDefaultUnitsOfType(type);

        // Try to save these units to the database
        for (final unit in defaultUnits) {
          await addUnit(unit);
        }

        // Return the newly created units
        return defaultUnits;
      }

      return filteredUnits;
    } catch (e) {
      debugPrint('Error getting units by type: $e');

      // Try to get units from cache as fallback
      try {
        final cachedUnits =
            _unitsCache.where((unit) => unit.unitType == type).toList();
        if (cachedUnits.isNotEmpty) {
          debugPrint(
              'Returning ${cachedUnits.length} units from cache despite error');
          return cachedUnits;
        }
      } catch (_) {
        // Ignore errors in fallback
      }

      // Create default units of the requested type as fallback
      final defaultUnits = _createDefaultUnitsOfType(type);

      // Add to cache
      _unitsCache.addAll(defaultUnits);

      return defaultUnits;
    }
  }

  /// Create default units of a specific type
  List<Unit> _createDefaultUnitsOfType(UnitType type) {
    debugPrint('Creating default units of type: ${type.name}');

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();

    switch (type) {
      case UnitType.headquarters:
        return [
          Unit(
            id: 'unit_hq_${timestamp}_1',
            name: 'Nigerian Army School of Signals',
            code: 'NASS',
            location: 'Abuja',
            unitType: UnitType.headquarters,
            isPrimary: true,
            description: 'Headquarters of the Nigerian Army Signal Corps',
            createdAt: now,
            updatedAt: now,
          ),
          Unit(
            id: 'unit_hq_${timestamp}_2',
            name: 'Nigerian Defence Academy',
            code: 'NDA',
            location: 'Kaduna',
            unitType: UnitType.headquarters,
            isPrimary: false,
            description: 'Military university',
            createdAt: now,
            updatedAt: now,
          ),
          Unit(
            id: 'unit_hq_${timestamp}_3',
            name: 'Defence Headquarters',
            code: 'DHQ',
            location: 'Abuja',
            unitType: UnitType.headquarters,
            isPrimary: false,
            description: 'Defence Headquarters',
            createdAt: now,
            updatedAt: now,
          ),
        ];

      case UnitType.forwardLink:
        return [
          Unit(
            id: 'unit_forward_${timestamp}_1',
            name: '521 Signal Regiment',
            code: '521SR',
            location: 'Lagos',
            unitType: UnitType.forwardLink,
            isPrimary: false,
            description: 'Forward link signal regiment',
            createdAt: now,
            updatedAt: now,
          ),
          Unit(
            id: 'unit_forward_${timestamp}_2',
            name: '523 Signal Regiment',
            code: '523SR',
            location: 'Kaduna',
            unitType: UnitType.forwardLink,
            isPrimary: false,
            description: 'Forward link signal regiment',
            createdAt: now,
            updatedAt: now,
          ),
        ];

      case UnitType.rearLink:
        return [
          Unit(
            id: 'unit_rear_${timestamp}_1',
            name: '522 Signal Regiment',
            code: '522SR',
            location: 'Port Harcourt',
            unitType: UnitType.rearLink,
            isPrimary: false,
            description: 'Rear link signal regiment',
            createdAt: now,
            updatedAt: now,
          ),
          Unit(
            id: 'unit_rear_${timestamp}_2',
            name: '524 Signal Regiment',
            code: '524SR',
            location: 'Enugu',
            unitType: UnitType.rearLink,
            isPrimary: false,
            description: 'Rear link signal regiment',
            createdAt: now,
            updatedAt: now,
          ),
        ];

      case UnitType.other:
        return [
          Unit(
            id: 'unit_other_${timestamp}_1',
            name: 'Other Military Unit',
            code: 'OMU',
            location: 'Various',
            unitType: UnitType.other,
            isPrimary: false,
            description: 'Other military unit',
            createdAt: now,
            updatedAt: now,
          ),
        ];
    }
  }

  /// Add a new unit
  Future<Unit?> addUnit(Unit unit) async {
    if (!_isInitialized) await initialize();

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

      // Add to database
      final success = await _localStorageService.addUnit(newUnit);

      if (!success) {
        debugPrint('Failed to add unit to database');
        return null;
      }

      // Update cache
      _unitsCache.add(newUnit);
      debugPrint('Unit added to cache, total units: ${_unitsCache.length}');

      // If this is the first unit, set it as primary
      if (_unitsCache.length == 1) {
        await setPrimaryUnit(newUnit.id);
      }

      return newUnit;
    } catch (e) {
      debugPrint('Error adding unit: $e');
      return null;
    }
  }

  /// Update an existing unit
  Future<bool> updateUnit(Unit unit) async {
    if (!_isInitialized) await initialize();

    try {
      // Update with current timestamp
      final updatedUnit = unit.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in database
      final success = await _localStorageService.updateUnit(updatedUnit);

      if (success) {
        // Update cache
        final index = _unitsCache.indexWhere((u) => u.id == unit.id);
        if (index != -1) {
          _unitsCache[index] = updatedUnit;
        } else {
          _unitsCache.add(updatedUnit);
        }

        // Update primary unit if needed
        if (_primaryUnit?.id == unit.id) {
          _primaryUnit = updatedUnit;
        }
      }

      return success;
    } catch (e) {
      debugPrint('Error updating unit: $e');
      return false;
    }
  }

  /// Delete a unit
  Future<bool> deleteUnit(String unitId) async {
    if (!_isInitialized) await initialize();

    try {
      // Check if this is the primary unit
      if (_primaryUnit?.id == unitId) {
        // Cannot delete primary unit
        return false;
      }

      // Delete from database
      final success = await _localStorageService.deleteUnit(unitId);

      if (success) {
        // Update cache
        _unitsCache.removeWhere((unit) => unit.id == unitId);
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting unit: $e');
      return false;
    }
  }

  /// Set primary unit
  Future<bool> setPrimaryUnit(String unitId) async {
    if (!_isInitialized) await initialize();

    try {
      // Get the unit
      final unit = await getUnitById(unitId);
      if (unit == null) return false;

      // Update all units to set isPrimary to false
      for (final u in _unitsCache) {
        if (u.isPrimary && u.id != unitId) {
          await updateUnit(u.copyWith(isPrimary: false));
        }
      }

      // Update the selected unit to set isPrimary to true
      final updatedUnit = unit.copyWith(isPrimary: true);
      final success = await updateUnit(updatedUnit);

      if (success) {
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('primaryUnitId', unitId);

        // Update current unit in LocalStorageService
        await _localStorageService.setCurrentUnit(unitId);

        // Update primary unit
        _primaryUnit = updatedUnit;
      }

      return success;
    } catch (e) {
      debugPrint('Error setting primary unit: $e');
      return false;
    }
  }

  /// Generate a unique ID
  String _generateId() {
    return 'unit_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}
