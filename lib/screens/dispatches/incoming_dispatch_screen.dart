import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../services/dispatch_service.dart';
import '../../widgets/incoming_report_dialog.dart';
import 'dispatch_detail_screen.dart';
import 'incoming_dispatch_form.dart';

class IncomingDispatchScreen extends StatefulWidget {
  const IncomingDispatchScreen({super.key});

  @override
  State<IncomingDispatchScreen> createState() => _IncomingDispatchScreenState();
}

class _IncomingDispatchScreenState extends State<IncomingDispatchScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<IncomingDispatch> _dispatches;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Date (Newest)';

  // New filter variables
  String _filterSenderUnit = 'All';
  String _filterAddrTo = 'All';
  String _filterCategory = 'All';
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    _loadDispatches();
  }

  void _loadDispatches() {
    setState(() {
      _dispatches = _dispatchService.getIncomingDispatches();
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _dispatches = _dispatches.where((dispatch) {
        return dispatch.subject
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.referenceNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.sender
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.senderUnit
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'All') {
      _dispatches = _dispatches.where((dispatch) {
        return dispatch.status.toLowerCase() == _filterStatus.toLowerCase();
      }).toList();
    }

    // Apply sender unit filter
    if (_filterSenderUnit != 'All') {
      _dispatches = _dispatches.where((dispatch) {
        return dispatch.senderUnit
            .toLowerCase()
            .contains(_filterSenderUnit.toLowerCase());
      }).toList();
    }

    // Apply address to filter
    if (_filterAddrTo != 'All') {
      _dispatches = _dispatches.where((dispatch) {
        // Check if addrTo property contains the filter value
        try {
          return dispatch.addrTo
              .toLowerCase()
              .contains(_filterAddrTo.toLowerCase());
        } catch (e) {
          // If addrTo property doesn't exist or is null, filter it out
          return false;
        }
      }).toList();
    }

    // Apply category filter
    if (_filterCategory != 'All') {
      _dispatches = _dispatches.where((dispatch) {
        // For category filtering, we'll use the priority as a simple example
        // In a real app, you might have a dedicated category field
        if (_filterCategory == 'Urgent') {
          return dispatch.priority.toLowerCase() == 'urgent' ||
              dispatch.priority.toLowerCase() == 'flash';
        } else if (_filterCategory == 'Normal') {
          return dispatch.priority.toLowerCase() == 'normal';
        } else if (_filterCategory == 'With Attachments') {
          return dispatch.attachments.isNotEmpty;
        }
        return true;
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        _dispatches.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'Date (Oldest)':
        _dispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'Priority':
        _dispatches.sort((a, b) {
          final priorityOrder = {'flash': 0, 'urgent': 1, 'normal': 2};
          return (priorityOrder[a.priority.toLowerCase()] ?? 3)
              .compareTo(priorityOrder[b.priority.toLowerCase()] ?? 3);
        });
        break;
      case 'Reference Number':
        _dispatches
            .sort((a, b) => a.referenceNumber.compareTo(b.referenceNumber));
        break;
    }

    // Update filter active status
    _isFilterActive = _filterStatus != 'All' ||
        _filterSenderUnit != 'All' ||
        _filterAddrTo != 'All' ||
        _filterCategory != 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Dispatches'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowDownWideShort),
            onPressed: _showSortDialog,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.fileExport),
            onPressed: _showReportDialog,
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by reference, subject, or sender',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _loadDispatches();
                });
              },
            ),
          ),

          // Filter and Sort Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Filter button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: Icon(
                      FontAwesomeIcons.filter,
                      size: 16,
                      color: _isFilterActive
                          ? AppTheme.accentColor
                          : Colors.grey[700],
                    ),
                    label: Text(
                      _isFilterActive ? 'Filters Active' : 'Filter',
                      style: TextStyle(
                        color: _isFilterActive
                            ? AppTheme.accentColor
                            : Colors.grey[700],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isFilterActive
                            ? AppTheme.accentColor
                            : Colors.grey[300]!,
                      ),
                      backgroundColor: _isFilterActive
                          ? AppTheme.accentColor.withAlpha(20)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showSortDialog,
                    icon: const Icon(
                      FontAwesomeIcons.arrowDownWideShort,
                      size: 16,
                    ),
                    label: Text('Sort: $_sortBy'),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatusFilterChip('All'),
                ...DispatchStatus.values
                    .map((status) => _buildStatusFilterChip(status.label)),
              ],
            ),
          ),

          // Active Filters Display
          if (_isFilterActive)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  if (_filterSenderUnit != 'All')
                    _buildActiveFilterChip('From: $_filterSenderUnit', () {
                      setState(() {
                        _filterSenderUnit = 'All';
                        _loadDispatches();
                      });
                    }),
                  if (_filterAddrTo != 'All')
                    _buildActiveFilterChip('To: $_filterAddrTo', () {
                      setState(() {
                        _filterAddrTo = 'All';
                        _loadDispatches();
                      });
                    }),
                  if (_filterCategory != 'All')
                    _buildActiveFilterChip('Category: $_filterCategory', () {
                      setState(() {
                        _filterCategory = 'All';
                        _loadDispatches();
                      });
                    }),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Dispatches List
          Expanded(
            child: _dispatches.isEmpty
                ? const Center(
                    child: Text(
                      'No incoming dispatches found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _dispatches.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final dispatch = _dispatches[index];
                      return _buildDispatchCard(dispatch);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewDispatch,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? label : 'All';
            _loadDispatches();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withAlpha(51), // 0.2 opacity
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDispatchCard(IncomingDispatch dispatch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dispatch.getPriorityColor().withAlpha(128), // 0.5 opacity
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewDispatchDetails(dispatch),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with reference number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dispatch.referenceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(dispatch.dateTime),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Subject
              Text(
                dispatch.subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),

              // Sender info
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.user,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'From: ${dispatch.sender}, ${dispatch.senderUnit}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Received by info
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.userCheck,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Received by: ${dispatch.receivedBy}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Footer with status, priority, and security classification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  Chip(
                    label: Text(
                      dispatch.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    avatar: Icon(
                      dispatch.getStatusIcon(),
                      size: 14,
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                  ),

                  Row(
                    children: [
                      // Priority indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: dispatch
                              .getPriorityColor()
                              .withAlpha(51), // 0.2 opacity
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dispatch.priority,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: dispatch.getPriorityColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Security classification
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dispatch.securityClassification,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    // Create temporary variables to hold filter values
    String tempFilterStatus = _filterStatus;
    String tempFilterSenderUnit = _filterSenderUnit;
    String tempFilterAddrTo = _filterAddrTo;
    String tempFilterCategory = _filterCategory;

    // Get unique sender units for filter options
    final List<String> senderUnits = ['All'];
    final List<String> addrToUnits = ['All'];

    // Extract unique sender units and addrTo values from dispatches
    for (var dispatch in _dispatchService.getIncomingDispatches()) {
      if (!senderUnits.contains(dispatch.senderUnit)) {
        senderUnits.add(dispatch.senderUnit);
      }

      try {
        if (dispatch.addrTo.isNotEmpty &&
            !addrToUnits.contains(dispatch.addrTo)) {
          addrToUnits.add(dispatch.addrTo);
        }
      } catch (e) {
        // Skip if addrTo doesn't exist
      }
    }

    // Define categories
    final List<String> categories = [
      'All',
      'Urgent',
      'Normal',
      'With Attachments',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(FontAwesomeIcons.filter, size: 20),
                const SizedBox(width: 8),
                const Text('Advanced Filters'),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      tempFilterStatus = 'All';
                      tempFilterSenderUnit = 'All';
                      tempFilterAddrTo = 'All';
                      tempFilterCategory = 'All';
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filter section
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        _buildFilterChip(
                          'All',
                          tempFilterStatus == 'All',
                          (selected) {
                            setState(() {
                              tempFilterStatus =
                                  selected ? 'All' : tempFilterStatus;
                            });
                          },
                        ),
                        ...DispatchStatus.values
                            .map((status) => _buildFilterChip(
                                  status.label,
                                  tempFilterStatus == status.label,
                                  (selected) {
                                    setState(() {
                                      tempFilterStatus = selected
                                          ? status.label
                                          : tempFilterStatus;
                                    });
                                  },
                                )),
                      ],
                    ),
                    const Divider(height: 24),

                    // Sender Unit filter section
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Sender Unit (ADDR FROM)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: tempFilterSenderUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: senderUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tempFilterSenderUnit = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address To filter section
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Address To (ADDR TO)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: tempFilterAddrTo,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: addrToUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          tempFilterAddrTo = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category filter section
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: categories
                          .map((category) => _buildFilterChip(
                                category,
                                tempFilterCategory == category,
                                (selected) {
                                  setState(() {
                                    tempFilterCategory = selected
                                        ? category
                                        : tempFilterCategory;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters
                  this.setState(() {
                    _filterStatus = tempFilterStatus;
                    _filterSenderUnit = tempFilterSenderUnit;
                    _filterAddrTo = tempFilterAddrTo;
                    _filterCategory = tempFilterCategory;
                    _loadDispatches();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryColor.withAlpha(51), // 0.2 opacity
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
        ),
      ),
      backgroundColor: AppTheme.primaryColor.withAlpha(25),
      deleteIcon: const Icon(
        Icons.close,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      onDeleted: onRemove,
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('Date (Newest)'),
              _buildSortOption('Date (Oldest)'),
              _buildSortOption('Priority'),
              _buildSortOption('Reference Number'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOption(String sortOption) {
    return RadioListTile<String>(
      title: Text(sortOption),
      value: sortOption,
      groupValue: _sortBy,
      onChanged: (value) {
        setState(() {
          _sortBy = value!;
          _loadDispatches();
        });
        Navigator.pop(context);
      },
    );
  }

  void _viewDispatchDetails(IncomingDispatch dispatch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchDetailScreen(
          dispatchId: dispatch.id,
          dispatchType: 'incoming',
        ),
      ),
    ).then((_) => _loadDispatches());
  }

  void _addNewDispatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IncomingDispatchForm(),
      ),
    ).then((_) => _loadDispatches());
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => const IncomingReportDialog(),
    );
  }
}
