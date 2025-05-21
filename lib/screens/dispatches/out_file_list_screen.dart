import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';
import 'dispatch_detail_screen.dart';
import 'out_file_form.dart';

class OutFileListScreen extends StatefulWidget {
  const OutFileListScreen({super.key});

  @override
  State<OutFileListScreen> createState() => _OutFileListScreenState();
}

class _OutFileListScreenState extends State<OutFileListScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<OutgoingDispatch> _dispatches;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Date (Newest)';

  // Filter variables
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
      // Get outgoing dispatches
      _dispatches = _dispatchService.getOutgoingDispatches();
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    // Start with all dispatches
    List<OutgoingDispatch> filteredDispatches =
        _dispatchService.getOutgoingDispatches();

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredDispatches = filteredDispatches.where((dispatch) {
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
      filteredDispatches = filteredDispatches
          .where((dispatch) => dispatch.status == _filterStatus)
          .toList();
    }

    // Apply sender unit filter
    if (_filterSenderUnit != 'All') {
      filteredDispatches = filteredDispatches
          .where((dispatch) => dispatch.sentBy == _filterSenderUnit)
          .toList();
    }

    // Apply recipient unit filter
    if (_filterRecipientUnit != 'All') {
      filteredDispatches = filteredDispatches
          .where((dispatch) => dispatch.recipientUnit == _filterRecipientUnit)
          .toList();
    }

    // Apply category filter
    if (_filterCategory != 'All') {
      // Implement category filtering when categories are added
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        filteredDispatches.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        break;
      case 'Date (Oldest)':
        filteredDispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        break;
      case 'Priority (Highest)':
        filteredDispatches.sort((a, b) => _getPriorityValue(b.priority)
            .compareTo(_getPriorityValue(a.priority)));
        break;
      case 'Priority (Lowest)':
        filteredDispatches.sort((a, b) => _getPriorityValue(a.priority)
            .compareTo(_getPriorityValue(b.priority)));
        break;
      case 'Reference Number':
        filteredDispatches
            .sort((a, b) => a.referenceNumber.compareTo(b.referenceNumber));
        break;
    }

    setState(() {
      _dispatches = filteredDispatches;
    });
  }

  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'IMM':
        return 4;
      case 'FLASH':
        return 3;
      case 'PRIORITY':
        return 2;
      case 'ROUTINE':
        return 1;
      default:
        return 0;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Dispatches'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status filter
              const Text('Status:'),
              DropdownButton<String>(
                value: _filterStatus,
                isExpanded: true,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() {
                    _filterStatus = value!;
                    _isFilterActive = true;
                    _applyFiltersAndSort();
                  });
                },
                items:
                    ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
              ),
              const SizedBox(height: 16),
              // Add more filters as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearFilters();
            },
            child: const Text('Clear Filters'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Dispatches'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sort options
              for (final option in [
                'Date (Newest)',
                'Date (Oldest)',
                'Priority (Highest)',
                'Priority (Lowest)',
                'Reference Number',
              ])
                RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    Navigator.pop(context);
                    setState(() {
                      _sortBy = value!;
                      _applyFiltersAndSort();
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    // Implement report generation
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
          IconButton(
            icon: const Icon(FontAwesomeIcons.fileLines),
            onPressed: () {
              Navigator.pushNamed(
                  context, AppConstants.outFileSlipGeneratorRoute);
            },
            tooltip: 'Generate OUT FILE Slip',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search OUT FILE dispatches...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _isFilterActive
                    ? IconButton(
                        icon: const Icon(Icons.filter_list_off),
                        onPressed: _clearFilters,
                        tooltip: 'Clear Filters',
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
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
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: dispatch.getStatusColor().withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dispatch.status,
                      style: TextStyle(
                        color: dispatch.getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sender and date info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From: ${dispatch.sentBy}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'To: ${dispatch.recipientUnit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    dispatch.formattedDate,
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
      ),
    );
  }
}
