import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';

import 'dispatch_detail_screen.dart';
import 'out_file_form.dart';

class OutFileScreen extends StatefulWidget {
  const OutFileScreen({super.key});

  @override
  State<OutFileScreen> createState() => _OutFileScreenState();
}

class _OutFileScreenState extends State<OutFileScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<OutgoingDispatch> _dispatches;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Date (Newest)';

  // New filter variables
  String _filterSenderUnit = 'All';
  String _filterRecipientUnit = 'All';
  String _filterCategory = 'All';
  bool _isFilterActive = false;

  @override
  void initState() {
    super.initState();
    _loadDispatches();
  }

  void _loadDispatches() {
    setState(() {
      // Load outgoing dispatches
      _dispatches = _dispatchService.getOutgoingDispatches();
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _dispatches = _dispatches.where((dispatch) {
        return dispatch.referenceNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.subject
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.content
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.sentBy
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.recipientUnit
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'All') {
      _dispatches = _dispatches
          .where((dispatch) => dispatch.status == _filterStatus)
          .toList();
    }

    // Apply sender unit filter
    if (_filterSenderUnit != 'All') {
      _dispatches = _dispatches
          .where((dispatch) => dispatch.sentBy == _filterSenderUnit)
          .toList();
    }

    // Apply recipient unit filter
    if (_filterRecipientUnit != 'All') {
      _dispatches = _dispatches
          .where((dispatch) => dispatch.recipientUnit == _filterRecipientUnit)
          .toList();
    }

    // Apply category filter (if implemented)
    if (_filterCategory != 'All') {
      // This would filter by category if categories were implemented
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        _dispatches.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'Date (Oldest)':
        _dispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'Reference Number':
        _dispatches
            .sort((a, b) => a.referenceNumber.compareTo(b.referenceNumber));
        break;
      case 'Priority':
        _dispatches.sort((a, b) {
          final priorityOrder = {'Flash': 0, 'Urgent': 1, 'Normal': 2};
          return (priorityOrder[a.priority] ?? 3)
              .compareTo(priorityOrder[b.priority] ?? 3);
        });
        break;
      case 'Status':
        _dispatches.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OUT FILE'),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by reference, subject, content, or sender',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Filter indicator
          if (_isFilterActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(FontAwesomeIcons.filter,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Filters applied',
                    style: TextStyle(color: Colors.blue),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Dispatches List
          Expanded(
            child: _dispatches.isEmpty
                ? const Center(
                    child: Text(
                      'No OUT FILE dispatches found',
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

  Widget _buildDispatchCard(OutgoingDispatch dispatch) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: dispatch
                          .getPriorityColor()
                          .withAlpha(51), // 0.2 opacity
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      dispatch.getPriorityIcon(),
                      color: dispatch.getPriorityColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dispatch details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dispatch.referenceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dispatch.subject,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: dispatch
                          .getStatusColor()
                          .withAlpha(51), // 0.2 opacity
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dispatch.status,
                      style: TextStyle(
                        color: dispatch.getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Metadata
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.calendar,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(dispatch.dateTime),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    FontAwesomeIcons.buildingUser,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'To: ${dispatch.recipientUnit}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    // Implementation for filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Dispatches'),
        content: const Text('Filter functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    // Implementation for sort dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Dispatches'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date (Newest)'),
              value: 'Date (Newest)',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Date (Oldest)'),
              value: 'Date (Oldest)',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Reference Number'),
              value: 'Reference Number',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Priority'),
              value: 'Priority',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Status'),
              value: 'Status',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _applyFiltersAndSort();
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = 'All';
      _filterSenderUnit = 'All';
      _filterRecipientUnit = 'All';
      _filterCategory = 'All';
      _isFilterActive = false;
      _applyFiltersAndSort();
    });
  }

  void _viewDispatchDetails(OutgoingDispatch dispatch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DispatchDetailScreen(
          dispatchId: dispatch.id,
          dispatchType: 'outgoing',
        ),
      ),
    ).then((_) => _loadDispatches());
  }

  void _addNewDispatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OutFileForm(),
      ),
    ).then((_) => _loadDispatches());
  }

  void _showReportDialog() {
    // Report functionality has been removed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report functionality has been removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
