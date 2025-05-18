import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../models/unit.dart';
import '../screens/units/unit_form_dialog.dart';
import '../services/unit_service.dart';

/// A widget for selecting units from the Units Management system
///
/// This widget displays a dropdown of units with search functionality
/// and the ability to add new units directly from the dropdown.
class UnitSelectorUpdated extends StatefulWidget {
  final String? selectedUnitId;
  final Function(Unit unit) onUnitSelected;
  final String label;
  final bool isRequired;
  final bool allowAddNew;
  final UnitType? filterByType;

  const UnitSelectorUpdated({
    super.key,
    this.selectedUnitId,
    required this.onUnitSelected,
    required this.label,
    this.isRequired = false,
    this.allowAddNew = true,
    this.filterByType,
  });

  @override
  State<UnitSelectorUpdated> createState() => _UnitSelectorUpdatedState();
}

class _UnitSelectorUpdatedState extends State<UnitSelectorUpdated> {
  final UnitService _unitService = UnitService();
  List<Unit> _units = [];
  List<Unit> _filteredUnits = [];
  Unit? _selectedUnit;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _searchController.addListener(_filterUnits);
  }

  @override
  void didUpdateWidget(UnitSelectorUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload units if the filter type changed
    if (oldWidget.filterByType != widget.filterByType) {
      debugPrint('UnitSelectorUpdated: Filter type changed, reloading units');
      _loadUnits();
    }

    // Update selected unit if the selectedUnitId changed
    if (oldWidget.selectedUnitId != widget.selectedUnitId &&
        widget.selectedUnitId != null &&
        _units.isNotEmpty) {
      debugPrint(
          'UnitSelectorUpdated: Selected unit ID changed, updating selection');
      final newSelectedUnit = _units.firstWhere(
        (unit) => unit.id == widget.selectedUnitId,
        orElse: () => _units.firstWhere(
          (unit) => unit.isPrimary,
          orElse: () => _units.first,
        ),
      );

      if (newSelectedUnit.id != _selectedUnit?.id) {
        setState(() {
          _selectedUnit = newSelectedUnit;
        });
        widget.onUnitSelected(newSelectedUnit);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Filter units based on search text
  void _filterUnits() {
    if (_units.isEmpty) return;

    final searchText = _searchController.text.toLowerCase();

    if (searchText.isEmpty) {
      setState(() {
        _filteredUnits = List.from(_units);
      });
      return;
    }

    setState(() {
      _filteredUnits = _units.where((unit) {
        return unit.name.toLowerCase().contains(searchText) ||
            unit.code.toLowerCase().contains(searchText);
      }).toList();
    });
  }

  // Create default units
  List<Unit> _createDefaultUnits() {
    debugPrint('UnitSelectorUpdated: Creating default units');

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final hqId = 'unit_hq_$timestamp';

    return [
      Unit(
        id: hqId,
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
        id: 'unit_forward_$timestamp',
        name: '521 Signal Regiment',
        code: '521SR',
        location: 'Lagos',
        parentUnitId: hqId,
        unitType: UnitType.forwardLink,
        isPrimary: false,
        description: 'Forward link signal regiment',
        createdAt: now,
        updatedAt: now,
      ),
      Unit(
        id: 'unit_rear_$timestamp',
        name: '522 Signal Regiment',
        code: '522SR',
        location: 'Port Harcourt',
        parentUnitId: hqId,
        unitType: UnitType.rearLink,
        isPrimary: false,
        description: 'Rear link signal regiment',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // Load units from the UnitService
  Future<void> _loadUnits() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('UnitSelectorUpdated: Loading units...');

      // Force UnitService to initialize
      debugPrint('UnitSelectorUpdated: Initializing UnitService...');
      try {
        await _unitService.initialize();
      } catch (e) {
        debugPrint('UnitSelectorUpdated: Error initializing UnitService: $e');
        // Continue anyway, we'll handle empty units below
      }

      // Load units based on filter
      List<Unit> units = [];
      try {
        if (widget.filterByType != null) {
          debugPrint(
              'UnitSelectorUpdated: Loading units by type: ${widget.filterByType}');
          units = await _unitService.getUnitsByType(widget.filterByType!);
        } else {
          debugPrint('UnitSelectorUpdated: Loading all units');
          units = await _unitService.getAllUnits();
        }
        debugPrint('UnitSelectorUpdated: Loaded ${units.length} units');
      } catch (e) {
        debugPrint('UnitSelectorUpdated: Error loading units: $e');
        // Continue with empty units list, we'll handle it below
      }

      // If no units were loaded, create and add default units
      if (units.isEmpty) {
        debugPrint(
            'UnitSelectorUpdated: No units found, creating default units...');

        // Create default units directly
        final defaultUnits = _createDefaultUnits();

        // Save these units to the database
        for (final unit in defaultUnits) {
          try {
            final addedUnit = await _unitService.addUnit(unit);
            if (addedUnit != null) {
              debugPrint('UnitSelectorUpdated: Added unit: ${unit.name}');
            } else {
              debugPrint(
                  'UnitSelectorUpdated: Failed to add unit: ${unit.name}');
            }
          } catch (e) {
            debugPrint('UnitSelectorUpdated: Error adding unit: $e');
          }
        }

        // Try to get units again after adding default units
        try {
          if (widget.filterByType != null) {
            units = await _unitService.getUnitsByType(widget.filterByType!);
          } else {
            units = await _unitService.getAllUnits();
          }
        } catch (e) {
          debugPrint(
              'UnitSelectorUpdated: Error loading units after adding defaults: $e');
        }

        // If still no units, use the default units directly
        if (units.isEmpty) {
          units = defaultUnits;
          debugPrint('UnitSelectorUpdated: Using default units directly');
        }

        debugPrint('UnitSelectorUpdated: Now have ${units.length} units');
      }

      // Sort units by name
      if (units.isNotEmpty) {
        units.sort((a, b) => a.name.compareTo(b.name));
      }

      // Find selected unit
      Unit? selectedUnit;
      if (widget.selectedUnitId != null && units.isNotEmpty) {
        debugPrint(
            'UnitSelectorUpdated: Looking for selected unit with ID: ${widget.selectedUnitId}');
        try {
          selectedUnit = units.firstWhere(
            (unit) => unit.id == widget.selectedUnitId,
          );
          debugPrint(
              'UnitSelectorUpdated: Found selected unit: ${selectedUnit.name}');
        } catch (_) {
          debugPrint(
              'UnitSelectorUpdated: Selected unit not found, using primary or first unit');
          // If not found, use primary unit or first unit
          selectedUnit = units.firstWhere(
            (unit) => unit.isPrimary,
            orElse: () => units.first,
          );
        }
      } else if (units.isNotEmpty) {
        // Default to primary unit if available
        debugPrint(
            'UnitSelectorUpdated: No selected unit ID provided, using primary or first unit');
        selectedUnit = units.firstWhere(
          (unit) => unit.isPrimary,
          orElse: () => units.first,
        );
      }

      if (mounted) {
        setState(() {
          _units = units;
          _filteredUnits = List.from(units);
          _selectedUnit = selectedUnit;
          _isLoading = false;
        });

        // Notify parent if a unit is selected
        if (_selectedUnit != null) {
          debugPrint(
              'UnitSelectorUpdated: Notifying parent of selected unit: ${_selectedUnit!.name}');
          widget.onUnitSelected(_selectedUnit!);
        }
      }
    } catch (e) {
      debugPrint('UnitSelectorUpdated: Error loading units: $e');

      // Create default units as a fallback
      final defaultUnits = _createDefaultUnits();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _units = defaultUnits;
          _filteredUnits = defaultUnits;
          _selectedUnit = defaultUnits.first;
        });

        // Notify parent of selected unit
        if (_selectedUnit != null) {
          widget.onUnitSelected(_selectedUnit!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default units due to loading error'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Show dialog to add a new unit
  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

  // Handle unit saved from dialog
  Future<void> _handleUnitSaved(Unit unit, bool isNew) async {
    try {
      Unit? newUnit;
      if (isNew) {
        newUnit = await _unitService.addUnit(unit);
      } else {
        final success = await _unitService.updateUnit(unit);
        if (success) {
          newUnit = unit;
        }
      }

      // We need to check if the widget is still mounted before accessing context
      if (!mounted) return;

      if (newUnit != null) {
        _showSnackBar(
          isNew ? 'Unit added successfully' : 'Unit updated successfully',
          Colors.green,
        );

        // Reload units and select the new one
        await _loadUnits();

        if (!mounted) return;

        setState(() {
          _selectedUnit = newUnit;
        });
        widget.onUnitSelected(newUnit);
      } else {
        _showSnackBar(
          isNew ? 'Failed to add unit' : 'Failed to update unit',
          Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Error saving unit: $e');
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  // Helper method to show snackbar
  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Loading indicator or dropdown
        _isLoading ? const LinearProgressIndicator() : _buildUnitSelector(),
      ],
    );
  }

  Widget _buildUnitSelector() {
    return Column(
      children: [
        // Search field with add button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by name or code...',
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _filterUnits();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (widget.allowAddNew)
                IconButton(
                  icon: const Icon(
                    FontAwesomeIcons.circlePlus,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Add New Unit',
                  onPressed: _showAddUnitDialog,
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Units dropdown or empty state
        _buildUnitsDropdown(),
      ],
    );
  }

  Widget _buildUnitsDropdown() {
    if (_units.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredUnits.isEmpty && _searchController.text.isNotEmpty) {
      return _buildNoResultsFound();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<Unit>(
            value: _selectedUnit,
            isExpanded: true,
            hint: const Text('Select a unit'),
            icon: const Icon(Icons.arrow_drop_down),
            items: _filteredUnits.map((Unit unit) {
              return DropdownMenuItem<Unit>(
                value: unit,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        unit.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unit.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit.isPrimary) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: (Unit? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedUnit = newValue;
                  // Clear search when a unit is selected
                  _searchController.clear();
                  _filterUnits();
                });
                widget.onUnitSelected(newValue);
                // Unfocus search field
                _searchFocusNode.unfocus();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          const Text(
            'No units available in the system',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.allowAddNew)
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Unit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: _showAddUnitDialog,
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Loading Units'),
            onPressed: _loadUnits,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'No units found matching "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.allowAddNew)
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Unit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: _showAddUnitDialog,
            ),
        ],
      ),
    );
  }
}
