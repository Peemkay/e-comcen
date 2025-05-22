import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';
import 'comcen_log_form.dart';
import 'comcen_report_screen.dart';

class ComcenLogScreen extends StatefulWidget {
  const ComcenLogScreen({super.key});

  @override
  State<ComcenLogScreen> createState() => _ComcenLogScreenState();
}

class _ComcenLogScreenState extends State<ComcenLogScreen> {
  final DispatchService _dispatchService = DispatchService();
  late List<DispatchLog> _logs;
  String _searchQuery = '';
  String _filterAction = 'All';
  String _sortBy = 'Date (Newest)';
  bool _isLoading = false;
  Map<String, dynamic>? _communicationState;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadCommunicationState();
  }

  void _loadLogs() {
    setState(() {
      _logs = _dispatchService.getComcenLogs();
      _applyFiltersAndSort();
    });
  }

  Future<void> _loadCommunicationState() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _dispatchService.generateCommunicationStateReport();
      if (mounted) {
        setState(() {
          _communicationState = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading communication state: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _logs = _logs.where((log) {
        return log.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            log.performedBy
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            log.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply action filter
    if (_filterAction != 'All') {
      _logs = _logs.where((log) {
        return log.action.toLowerCase().contains(_filterAction.toLowerCase());
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Date (Newest)':
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'Date (Oldest)':
        _logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'Action':
        _logs.sort((a, b) => a.action.compareTo(b.action));
        break;
      case 'User':
        _logs.sort((a, b) => a.performedBy.compareTo(b.performedBy));
        break;
    }
  }

  void _addNewLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComcenLogForm(),
      ),
    ).then((_) {
      _loadLogs();
      _loadCommunicationState();
    });
  }

  void _viewCommunicationReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ComcenReportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMCEN Log'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.chartLine),
            onPressed: _viewCommunicationReport,
            tooltip: 'View Report',
          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewLog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Communication State Card
          if (_communicationState != null) _buildCommunicationStateCard(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs by action, user, or notes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _loadLogs();
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
                _buildFilterChip('Added'),
                _buildFilterChip('Updated'),
                _buildFilterChip('Deleted'),
                _buildFilterChip('Created'),
                _buildFilterChip('Received'),
                _buildFilterChip('Sent'),
                _buildFilterChip('System'),
                _buildFilterChip('Communication'),
                _buildFilterChip('Rear Link'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationStateCard() {
    if (_communicationState == null) return const SizedBox.shrink();

    final status = _communicationState!['currentStatus'] as String;
    final lastChecked = _communicationState!['lastChecked'] as DateTime;
    final lastCheckedBy = _communicationState!['lastCheckedBy'] as String;
    final uptimePercentage = _communicationState!['uptimePercentage'] as double;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Operational':
        statusColor = Colors.green;
        statusIcon = FontAwesomeIcons.circleCheck;
        break;
      case 'Down':
        statusColor = Colors.red;
        statusIcon = FontAwesomeIcons.circleXmark;
        break;
      case 'Intermittent':
        statusColor = Colors.orange;
        statusIcon = FontAwesomeIcons.circleExclamation;
        break;
      case 'Under Maintenance':
        statusColor = Colors.blue;
        statusIcon = FontAwesomeIcons.screwdriverWrench;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = FontAwesomeIcons.circleQuestion;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.towerBroadcast,
                    color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Communication Link Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.arrowsRotate, size: 16),
                  onPressed: _loadCommunicationState,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last checked: ${DateFormat('dd MMM yyyy HH:mm').format(lastChecked)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'By: $lastCheckedBy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Uptime',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${uptimePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _viewCommunicationReport,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
              ),
              child: const Text('View Full Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterAction == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterAction = selected ? label : 'All';
            _loadLogs();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withAlpha(50),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLogCard(DispatchLog log) {
    IconData actionIcon;
    Color actionColor;

    // Determine icon and color based on action
    if (log.action.toLowerCase().contains('add') ||
        log.action.toLowerCase().contains('creat')) {
      actionIcon = FontAwesomeIcons.plus;
      actionColor = Colors.green;
    } else if (log.action.toLowerCase().contains('updat') ||
        log.action.toLowerCase().contains('edit')) {
      actionIcon = FontAwesomeIcons.penToSquare;
      actionColor = Colors.blue;
    } else if (log.action.toLowerCase().contains('delet')) {
      actionIcon = FontAwesomeIcons.trash;
      actionColor = Colors.red;
    } else if (log.action.toLowerCase().contains('receiv')) {
      actionIcon = FontAwesomeIcons.inbox;
      actionColor = Colors.purple;
    } else if (log.action.toLowerCase().contains('sent') ||
        log.action.toLowerCase().contains('send')) {
      actionIcon = FontAwesomeIcons.paperPlane;
      actionColor = Colors.orange;
    } else if (log.action.toLowerCase().contains('system')) {
      actionIcon = FontAwesomeIcons.gear;
      actionColor = Colors.grey;
    } else if (log.action.toLowerCase().contains('communication') ||
        log.action.toLowerCase().contains('rear link')) {
      actionIcon = FontAwesomeIcons.towerBroadcast;
      actionColor = Colors.deepPurple;
    } else {
      actionIcon = FontAwesomeIcons.clockRotateLeft;
      actionColor = Colors.teal;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show detailed view with options
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => _buildLogDetailSheet(log),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: actionColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  actionIcon,
                  color: actionColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Log Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action and User
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log.action,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          log.performedBy,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      DateFormat('dd MMM yyyy HH:mm:ss').format(log.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),

                    // Notes (if any)
                    if (log.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        log.notes,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetailSheet(DispatchLog log) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Log Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),

          // Log details
          ListTile(
            leading: const Icon(FontAwesomeIcons.tag),
            title: const Text('Action'),
            subtitle: Text(log.action),
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.userGear),
            title: const Text('Performed By'),
            subtitle: Text(log.performedBy),
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.clock),
            title: const Text('Timestamp'),
            subtitle:
                Text(DateFormat('dd MMM yyyy HH:mm:ss').format(log.timestamp)),
          ),
          if (log.notes.isNotEmpty)
            ListTile(
              leading: const Icon(FontAwesomeIcons.noteSticky),
              title: const Text('Notes'),
              subtitle: Text(log.notes),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComcenLogForm(log: log),
                    ),
                  ).then((_) {
                    _loadLogs();
                    _loadCommunicationState();
                  });
                },
                icon: const Icon(FontAwesomeIcons.penToSquare),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Log'),
                      content: const Text(
                          'Are you sure you want to delete this log? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _dispatchService.deleteComcenLog(log.id);
                            Navigator.pop(context);
                            _loadLogs();
                            _loadCommunicationState();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Log deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All'),
              _buildFilterOption('Added'),
              _buildFilterOption('Updated'),
              _buildFilterOption('Deleted'),
              _buildFilterOption('Created'),
              _buildFilterOption('Received'),
              _buildFilterOption('Sent'),
              _buildFilterOption('System'),
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

  Widget _buildFilterOption(String action) {
    return RadioListTile<String>(
      title: Text(action),
      value: action,
      groupValue: _filterAction,
      onChanged: (value) {
        setState(() {
          _filterAction = value!;
          _loadLogs();
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
              _buildSortOption('Action'),
              _buildSortOption('User'),
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
          _loadLogs();
        });
        Navigator.pop(context);
      },
    );
  }
}
