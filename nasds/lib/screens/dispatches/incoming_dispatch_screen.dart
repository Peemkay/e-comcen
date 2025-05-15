import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../services/dispatch_service.dart';
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

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                ...DispatchStatus.values
                    .map((status) => _buildFilterChip(status.label))
                    ,
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

  Widget _buildFilterChip(String label) {
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterOption('All'),
                ...DispatchStatus.values
                    .map((status) => _buildFilterOption(status.label)),
              ],
            ),
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

  Widget _buildFilterOption(String status) {
    return RadioListTile<String>(
      title: Text(status),
      value: status,
      groupValue: _filterStatus,
      onChanged: (value) {
        setState(() {
          _filterStatus = value!;
          _loadDispatches();
        });
        Navigator.pop(context);
      },
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
}
