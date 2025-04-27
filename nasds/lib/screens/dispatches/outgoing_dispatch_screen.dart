import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../services/dispatch_service.dart';
import 'dispatch_detail_screen.dart';
import 'outgoing_dispatch_form.dart';

class OutgoingDispatchScreen extends StatefulWidget {
  const OutgoingDispatchScreen({super.key});

  @override
  State<OutgoingDispatchScreen> createState() => _OutgoingDispatchScreenState();
}

class _OutgoingDispatchScreenState extends State<OutgoingDispatchScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<OutgoingDispatch> _dispatches;
  String _searchQuery = '';
  String _filterStatus = 'All';
  final String _sortBy = 'Date (Newest)';

  @override
  void initState() {
    super.initState();
    _loadDispatches();
  }

  void _loadDispatches() {
    setState(() {
      _dispatches = _dispatchService.getOutgoingDispatches();
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
            dispatch.recipient
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            dispatch.recipientUnit
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
        title: const Text('Outgoing Dispatches'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.filter),
            onPressed: () {
              // Show filter dialog
            },
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowDownWideShort),
            onPressed: () {
              // Show sort dialog
            },
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
                hintText: 'Search by reference, subject, or recipient',
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
                    .map((status) => _buildFilterChip(status.label)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Dispatches List
          Expanded(
            child: _dispatches.isEmpty
                ? const Center(
                    child: Text(
                      'No outgoing dispatches found',
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
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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
          color: dispatch.getPriorityColor().withOpacity(0.5),
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

              // Recipient info
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.user,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'To: ${dispatch.recipient}, ${dispatch.recipientUnit}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Sent by info
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.paperPlane,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sent by: ${dispatch.sentBy} (${dispatch.deliveryMethod})',
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
                          color: dispatch.getPriorityColor().withOpacity(0.2),
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
        builder: (context) => const OutgoingDispatchForm(),
      ),
    ).then((_) => _loadDispatches());
  }
}
