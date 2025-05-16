import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../models/unit.dart';
import '../screens/units/unit_form_dialog.dart';
import '../services/unit_service.dart';

class UnitSelector extends StatefulWidget {
  final String? selectedUnitId;
  final Function(Unit unit) onUnitSelected;
  final String label;
  final bool isRequired;
  final bool allowAddNew;
  final UnitType? filterByType;

  const UnitSelector({
    super.key,
    this.selectedUnitId,
    required this.onUnitSelected,
    required this.label,
    this.isRequired = false,
    this.allowAddNew = true,
    this.filterByType,
  });

  @override
  State<UnitSelector> createState() => _UnitSelectorState();
}

class _UnitSelectorState extends State<UnitSelector> {
  final UnitService _unitService = UnitService();
  List<Unit> _units = [];
  List<Unit> _filteredUnits = [];
  Unit? _selectedUnit;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _searchController.addListener(_filterUnits);
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
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _filteredUnits = _units.where((unit) {
        return unit.name.toLowerCase().contains(searchText) ||
            unit.code.toLowerCase().contains(searchText);
      }).toList();
      _isSearching = true;
    });
  }

  Future<void> _loadUnits() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('UnitSelector: Initializing unit service...');
      await _unitService.initialize();

      debugPrint('UnitSelector: Loading units...');
      List<Unit> units = [];

      // Create default units in memory if none exist
      // This ensures we always have some units to display
      final defaultUnits = [
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

      if (widget.filterByType != null) {
        debugPrint(
            'UnitSelector: Loading units by type: ${widget.filterByType}');
        units = await _unitService.getUnitsByType(widget.filterByType!);
      } else {
        debugPrint('UnitSelector: Loading all units');
        units = await _unitService.getAllUnits();
      }

      debugPrint('UnitSelector: Loaded ${units.length} units');

      // If no units were loaded, use the default units
      if (units.isEmpty) {
        debugPrint('UnitSelector: No units found, using default units');

        // Add default units to database
        for (final unit in defaultUnits) {
          await _unitService.addUnit(unit);
        }

        // Use default units in memory immediately
        units = List.from(defaultUnits);
      }

      // Sort units by name
      if (units.isNotEmpty) {
        units.sort((a, b) => a.name.compareTo(b.name));
      }

      // Find selected unit
      Unit? selectedUnit;
      if (widget.selectedUnitId != null && units.isNotEmpty) {
        try {
          debugPrint(
              'UnitSelector: Looking for selected unit with ID: ${widget.selectedUnitId}');
          selectedUnit = units.firstWhere(
            (unit) => unit.id == widget.selectedUnitId,
          );
          debugPrint('UnitSelector: Found selected unit: ${selectedUnit.name}');
        } catch (_) {
          // If not found, use first unit or null
          debugPrint('UnitSelector: Selected unit not found, using first unit');
          selectedUnit = units.isNotEmpty ? units.first : null;
        }
      } else if (units.isNotEmpty) {
        // Default to primary unit if available
        try {
          debugPrint('UnitSelector: Looking for primary unit');
          selectedUnit = units.firstWhere(
            (unit) => unit.isPrimary,
          );
          debugPrint('UnitSelector: Found primary unit: ${selectedUnit.name}');
        } catch (_) {
          // If no primary unit, use first unit
          debugPrint('UnitSelector: No primary unit found, using first unit');
          selectedUnit = units.first;
        }
      }

      if (mounted) {
        setState(() {
          _units = units;
          _filteredUnits = List.from(units); // Initialize filtered units
          _selectedUnit = selectedUnit;
          _isLoading = false;
        });

        // Notify parent if a unit is selected
        if (_selectedUnit != null) {
          debugPrint(
              'UnitSelector: Notifying parent of selected unit: ${_selectedUnit!.name}');
          widget.onUnitSelected(_selectedUnit!);
        }
      }
    } catch (e) {
      debugPrint('UnitSelector: Error loading units: $e');
      if (mounted) {
        // Create fallback units in memory
        final fallbackUnits = [
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

        setState(() {
          _isLoading = false;
          _units = fallbackUnits;
          _filteredUnits = List.from(fallbackUnits);
          _selectedUnit = fallbackUnits.first;
        });

        // Notify parent of selected unit
        widget.onUnitSelected(fallbackUnits.first);

        _showErrorSnackBar('Using fallback units due to loading error');
      }
    }
  }

  // Removed unused method

  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

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

      if (newUnit != null && mounted) {
        _showSuccessSnackBar(
            isNew ? 'Unit added successfully' : 'Unit updated successfully');

        // Reload units and select the new one
        await _loadUnits();
        setState(() {
          _selectedUnit = newUnit;
        });
        widget.onUnitSelected(newUnit);
      } else if (mounted) {
        _showErrorSnackBar(
            isNew ? 'Failed to add unit' : 'Failed to update unit');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _isLoading ? const LinearProgressIndicator() : _buildUnitDropdown(),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    return Column(
      children: [
        // Search field
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

        // Dropdown or list view
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _units.isEmpty
              ? _buildNoUnitsAvailable()
              : (_filteredUnits.isEmpty && _searchController.text.isNotEmpty
                  ? _buildNoResultsFound()
                  : _buildUnitsList()),
        ),
      ],
    );
  }

  Widget _buildNoUnitsAvailable() {
    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _buildUnitsList() {
    // If there are no units available, show a message and add unit button
    if (_filteredUnits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
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
              'No units available',
              textAlign: TextAlign.center,
              style: TextStyle(
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

    // Normal dropdown with units
    return DropdownButtonHideUnderline(
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
    );
  }
}
