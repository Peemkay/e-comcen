import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/unit.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'unit_form_dialog.dart';

class UnitsManagementScreenNew extends StatefulWidget {
  const UnitsManagementScreenNew({super.key});

  @override
  State<UnitsManagementScreenNew> createState() =>
      _UnitsManagementScreenNewState();
}

class _UnitsManagementScreenNewState extends State<UnitsManagementScreenNew>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _localStorageService = LocalStorageService();
  List<Unit> _units = [];
  List<Unit> _filteredUnits = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;
  Unit? _primaryUnit;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add a new tab for Primary Unit
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUnits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _filterUnitsByTab();
      });
    }
  }

  Future<void> _loadUnits() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all units directly from local storage
      final units = await _localStorageService.getAllUnits();
      print('Loaded ${units.length} units');

      // Find primary unit (first unit with isPrimary = true)
      Unit? primaryUnit;
      for (var unit in units) {
        if (unit.isPrimary) {
          primaryUnit = unit;
          break;
        }
      }

      // If no primary unit found, use the first unit
      if (primaryUnit == null && units.isNotEmpty) {
        primaryUnit = units.first;
      }

      if (mounted) {
        setState(() {
          _units = units;
          _primaryUnit = primaryUnit;
          _filterUnitsByTab();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadUnits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load units: $e';
        });
      }
    }
  }

  void _filterUnitsByTab() {
    if (_units.isEmpty) {
      _filteredUnits = [];
      return;
    }

    switch (_tabController.index) {
      case 0: // All
        _filteredUnits = List.from(_units);
        break;
      case 1: // Primary Unit
        _filteredUnits = _units.where((unit) => unit.isPrimary).toList();
        break;
      case 2: // Forward Link
        _filteredUnits = _units
            .where((unit) => unit.unitType == UnitType.forwardLink)
            .toList();
        break;
      case 3: // Rear Link
        _filteredUnits =
            _units.where((unit) => unit.unitType == UnitType.rearLink).toList();
        break;
      case 4: // Headquarters
        _filteredUnits = _units
            .where((unit) => unit.unitType == UnitType.headquarters)
            .toList();
        break;
      case 5: // Other
        _filteredUnits =
            _units.where((unit) => unit.unitType == UnitType.other).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredUnits = _filteredUnits
          .where((unit) =>
              unit.name.toLowerCase().contains(query) ||
              unit.code.toLowerCase().contains(query) ||
              (unit.location?.toLowerCase().contains(query) ?? false))
          .toList();
    }
  }

  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

  void _showEditUnitDialog(Unit unit) {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        unit: unit,
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

  Future<void> _handleUnitSaved(Unit unit, bool isNew) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Handling unit save: ${unit.name} (${unit.code}), isNew: $isNew');

      bool success = false;
      if (isNew) {
        // Generate a unique ID if not provided
        final newUnit = unit.id.isEmpty
            ? unit.copyWith(
                id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
            : unit;

        success = await _localStorageService.addUnit(newUnit);
        print('Add unit result: ${success ? 'Success' : 'Failed'}');
      } else {
        success = await _localStorageService.updateUnit(unit);
        print('Update unit result: ${success ? 'Success' : 'Failed'}');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar(
            isNew ? 'Unit added successfully' : 'Unit updated successfully');
        await _loadUnits();
      } else {
        _showErrorSnackBar(
            isNew ? 'Failed to add unit' : 'Failed to update unit');
      }
    } catch (e) {
      print('Error in _handleUnitSaved: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _handleDeleteUnit(Unit unit) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text(
            'Are you sure you want to delete ${unit.name} (${unit.code})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _localStorageService.deleteUnit(unit.id);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar('Unit deleted successfully');
        await _loadUnits();
      } else {
        _showErrorSnackBar('Failed to delete unit');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _handleSetPrimaryUnit(Unit unit) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update the unit to set isPrimary to true
      final updatedUnit = unit.copyWith(isPrimary: true);
      final success = await _localStorageService.updateUnit(updatedUnit);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessSnackBar('${unit.name} set as primary unit');
        await _loadUnits();
      } else {
        _showErrorSnackBar('Failed to set primary unit');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filterUnitsByTab();
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Units',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Tab bar with gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withAlpha(230),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.yellow,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withAlpha(180),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'All Units'),
              Tab(text: 'Primary Unit'),
              Tab(text: 'Forward Link'),
              Tab(text: 'Rear Link'),
              Tab(text: 'Headquarters'),
              Tab(text: 'Other'),
            ],
          ),
        ),

        // Search bar with stats
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              CustomSearchBar(
                hintText: 'Search units by name, code or location...',
                onChanged: _handleSearch,
              ),
              const SizedBox(height: 8),
              if (!_isLoading && _units.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Text(
                        'Total: ${_units.length} units',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'Found: ${_filteredUnits.length} units',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: _isLoading
              ? const LoadingIndicator(message: 'Loading units...')
              : _filteredUnits.isEmpty
                  ? EmptyState(
                      icon: FontAwesomeIcons.buildingFlag,
                      title: 'No Units Found',
                      message: _searchQuery.isNotEmpty
                          ? 'No units match your search criteria'
                          : 'Add your first unit by clicking the + button below',
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Unit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _showAddUnitDialog,
                      ),
                    )
                  : _buildUnitsList(),
        ),
      ],
    );
  }

  Widget _buildUnitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _filteredUnits.length,
      itemBuilder: (context, index) {
        final unit = _filteredUnits[index];
        final isPrimary = unit.isPrimary;
        final unitColor = _getUnitTypeColor(unit.unitType);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary
                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showEditUnitDialog(unit),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with unit name, code and actions
                  Row(
                    children: [
                      // Unit type icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: unitColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getUnitTypeIcon(unit.unitType),
                          color: unitColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Unit name and code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    unit.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: unitColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: unitColor.withAlpha(100),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    unit.code,
                                    style: TextStyle(
                                      color: unitColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  unit.unitTypeDisplay,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditUnitDialog(unit);
                              break;
                            case 'delete':
                              _handleDeleteUnit(unit);
                              break;
                            case 'primary':
                              _handleSetPrimaryUnit(unit);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 20, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          if (!isPrimary)
                            const PopupMenuItem(
                              value: 'primary',
                              child: Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 20, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text('Set as Primary'),
                                ],
                              ),
                            ),
                          if (!isPrimary)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.grey[300], height: 1),
                  ),

                  // Details section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                unit.location ?? 'No location',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick action buttons
                      Row(
                        children: [
                          // Edit button
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: Colors.blue[700], size: 18),
                            tooltip: 'Edit Unit',
                            onPressed: () => _showEditUnitDialog(unit),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 16),

                          // Set as primary button (if not primary)
                          if (!isPrimary)
                            IconButton(
                              icon: const Icon(Icons.star_outline,
                                  color: Colors.amber, size: 18),
                              tooltip: 'Set as Primary Unit',
                              onPressed: () => _handleSetPrimaryUnit(unit),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Description (if available)
                  if (unit.description != null &&
                      unit.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      unit.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Primary unit badge
                  if (isPrimary) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Primary Unit',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getUnitTypeColor(UnitType type) {
    switch (type) {
      case UnitType.forwardLink:
        return Colors.blue;
      case UnitType.rearLink:
        return Colors.green;
      case UnitType.headquarters:
        return Colors.purple;
      case UnitType.other:
        return Colors.orange;
    }
  }

  IconData _getUnitTypeIcon(UnitType type) {
    switch (type) {
      case UnitType.forwardLink:
        return FontAwesomeIcons.arrowTrendUp;
      case UnitType.rearLink:
        return FontAwesomeIcons.arrowTrendDown;
      case UnitType.headquarters:
        return FontAwesomeIcons.buildingFlag;
      case UnitType.other:
        return FontAwesomeIcons.building;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Units Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUnits,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _errorMessage != null ? _buildErrorState() : _buildMainContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUnitDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Unit'),
        elevation: 4,
      ),
    );
  }
}
