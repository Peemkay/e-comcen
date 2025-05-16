import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';

class ComcenReportScreen extends StatefulWidget {
  const ComcenReportScreen({super.key});

  @override
  State<ComcenReportScreen> createState() => _ComcenReportScreenState();
}

class _ComcenReportScreenState extends State<ComcenReportScreen> {
  final DispatchService _dispatchService = DispatchService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  // Filtering and sorting state
  String _timeRange = 'Last 7 Days';
  final List<String> _timeRanges = [
    'Last 24 Hours',
    'Last 7 Days',
    'Last 30 Days',
    'All Time',
    'Custom Range'
  ];
  DateTime? _startDate;
  DateTime? _endDate;
  String _serviceTypeFilter = 'All';
  final List<String> _serviceTypes = [
    'All',
    'Communication',
    'Creation',
    'Update',
    'Deletion',
    'Receipt',
    'Transmission',
    'System',
    'Security',
    'Other'
  ];
  String _performedByFilter = '';
  String _sortBy = 'date';
  bool _sortAscending = false;

  // Custom date range
  bool _showCustomDateRange = false;

  @override
  void initState() {
    super.initState();
    _setDateRangeFromTimeRange();
    _loadReport();
  }

  void _setDateRangeFromTimeRange() {
    final now = DateTime.now();

    switch (_timeRange) {
      case 'Last 24 Hours':
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now;
        break;
      case 'Last 7 Days':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'Last 30 Days':
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case 'All Time':
        _startDate = null;
        _endDate = null;
        break;
      case 'Custom Range':
        // Keep existing dates or set defaults if null
        _startDate ??= now.subtract(const Duration(days: 30));
        _endDate ??= now;
        _showCustomDateRange = true;
        break;
    }
  }

  Future<void> _loadReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _dispatchService.generateCommunicationStateReport(
        startDate: _startDate,
        endDate: _endDate,
        serviceType: _serviceTypeFilter != 'All' ? _serviceTypeFilter : null,
        performedBy: _performedByFilter.isNotEmpty ? _performedByFilter : null,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
      );

      if (mounted) {
        setState(() {
          _reportData = report;
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
            content: Text('Error loading report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication State Report'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.filter),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadReport,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.print),
            onPressed: _printReport,
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(
                  child: Text(
                    'No report data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      _buildStatisticsCard(),
                      const SizedBox(height: 16),
                      _buildServiceTypeBreakdownCard(),
                      const SizedBox(height: 16),
                      _buildServicesLogCard(),
                      const SizedBox(height: 16),
                      _buildActionButtonsRow(),
                    ],
                  ),
                ),
    );
  }

  // Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Report'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range
                  const Text('Time Range',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _timeRanges.map((range) {
                      return ChoiceChip(
                        label: Text(range),
                        selected: _timeRange == range,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _timeRange = range;
                              if (range != 'Custom Range') {
                                _showCustomDateRange = false;
                              } else {
                                _showCustomDateRange = true;
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  // Custom Date Range
                  if (_timeRange == 'Custom Range') ...[
                    const SizedBox(height: 16),
                    const Text('Custom Date Range',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_startDate != null
                                ? DateFormat('dd MMM yyyy').format(_startDate!)
                                : 'Start Date'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_endDate != null
                                ? DateFormat('dd MMM yyyy').format(_endDate!)
                                : 'End Date'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _endDate = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Service Type Filter
                  const SizedBox(height: 16),
                  const Text('Service Type',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _serviceTypeFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      'All',
                      'Communication',
                      'Creation',
                      'Update',
                      'Deletion',
                      'Receipt',
                      'Transmission',
                      'System',
                      'Security',
                      'Other'
                    ]
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _serviceTypeFilter = value;
                        });
                      }
                    },
                  ),

                  // Performed By Filter
                  const SizedBox(height: 16),
                  const Text('Performed By',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _performedByFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter name or leave empty',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _performedByFilter = value;
                      });
                    },
                  ),

                  // Sort Options
                  const SizedBox(height: 16),
                  const Text('Sort By',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'date', child: Text('Date')),
                            DropdownMenuItem(
                                value: 'action', child: Text('Action')),
                            DropdownMenuItem(
                                value: 'performedBy',
                                child: Text('Performed By')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_sortAscending
                            ? FontAwesomeIcons.arrowUpWideShort
                            : FontAwesomeIcons.arrowDownWideShort),
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        tooltip: _sortAscending ? 'Ascending' : 'Descending',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setDateRangeFromTimeRange();
                  _loadReport();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _reportData!['currentStatus'] as String;
    final lastChecked = _reportData!['lastChecked'] as DateTime;
    final lastCheckedBy = _reportData!['lastCheckedBy'] as String;

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
                  'Current Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last checked: ${DateFormat('dd MMM yyyy HH:mm').format(lastChecked)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'By: $lastCheckedBy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeRanges.map((range) {
                  final isSelected = _timeRange == range;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(range),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _timeRange = range;
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppTheme.primaryColor.withAlpha(50),
                      labelStyle: TextStyle(
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final uptimePercentage = _reportData!['uptimePercentage'] as double;
    final totalChecks = _reportData!['totalChecks'] as int;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Uptime',
                  '${uptimePercentage.toStringAsFixed(1)}%',
                  FontAwesomeIcons.arrowUp,
                  Colors.green,
                ),
                _buildStatItem(
                  'Checks',
                  '$totalChecks',
                  FontAwesomeIcons.clipboardCheck,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Downtime',
                  '${(100 - uptimePercentage).toStringAsFixed(1)}%',
                  FontAwesomeIcons.arrowDown,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogsCard() {
    final logs = _reportData!['logs'] as List<DispatchLog>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Communication Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No communication logs found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length > 5 ? 5 : logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: const Icon(FontAwesomeIcons.towerBroadcast,
                            size: 20),
                        title: Text(log.action),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy HH:mm')
                                  .format(log.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              log.notes,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        trailing: Text(
                          log.performedBy,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
            if (logs.length > 5)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    // Show all logs in a dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('All Communication Logs'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return ListTile(
                                leading: const Icon(
                                    FontAwesomeIcons.towerBroadcast,
                                    size: 20),
                                title: Text(log.action),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy HH:mm')
                                          .format(log.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      log.notes,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  log.performedBy,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
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
                  },
                  icon: const Icon(FontAwesomeIcons.list, size: 16),
                  label: const Text('View All Logs'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build filter bar showing current filters
  Widget _buildFilterBar() {
    // Format date range for display
    String dateRangeText = 'All Time';
    if (_startDate != null && _endDate != null) {
      final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
      final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
      dateRangeText = '$startFormatted to $endFormatted';
    } else if (_startDate != null) {
      final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
      dateRangeText = 'From $startFormatted';
    } else if (_endDate != null) {
      final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
      dateRangeText = 'Until $endFormatted';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(FontAwesomeIcons.filter, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Current Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showFilterDialog,
                  child: const Text('Change'),
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Date: $_timeRange'),
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  backgroundColor: Colors.blue.withAlpha(25),
                ),
                if (_timeRange == 'Custom Range')
                  Chip(
                    label: Text(dateRangeText),
                    avatar: const Icon(Icons.date_range, size: 16),
                    backgroundColor: Colors.blue.withAlpha(25),
                  ),
                Chip(
                  label: Text('Type: $_serviceTypeFilter'),
                  avatar: const Icon(FontAwesomeIcons.tag, size: 16),
                  backgroundColor: Colors.green.withAlpha(25),
                ),
                if (_performedByFilter.isNotEmpty)
                  Chip(
                    label: Text('By: $_performedByFilter'),
                    avatar: const Icon(FontAwesomeIcons.user, size: 16),
                    backgroundColor: Colors.purple.withAlpha(25),
                  ),
                Chip(
                  label: Text(
                      'Sort: ${_getSortByText()} (${_sortAscending ? 'Asc' : 'Desc'})'),
                  avatar: Icon(
                    _sortAscending
                        ? FontAwesomeIcons.arrowUpWideShort
                        : FontAwesomeIcons.arrowDownWideShort,
                    size: 16,
                  ),
                  backgroundColor: Colors.orange.withAlpha(25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get readable sort text
  String _getSortByText() {
    switch (_sortBy) {
      case 'date':
        return 'Date';
      case 'action':
        return 'Action';
      case 'performedBy':
        return 'User';
      default:
        return 'Date';
    }
  }

  // Build service type breakdown card
  Widget _buildServiceTypeBreakdownCard() {
    final servicesByType = _reportData!['servicesByType'] as Map<String, int>;
    final totalServices = _reportData!['totalServices'] as int;

    if (servicesByType.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No service data available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: servicesByType.length,
              itemBuilder: (context, index) {
                final entry = servicesByType.entries.elementAt(index);
                final serviceType = entry.key;
                final count = entry.value;
                final percentage = totalServices > 0
                    ? (count / totalServices * 100).toStringAsFixed(1)
                    : '0';

                return _buildServiceTypeItem(
                  serviceType,
                  count,
                  '$percentage%',
                  _getServiceTypeColor(serviceType),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get color for service type
  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'communication':
        return Colors.blue;
      case 'creation':
        return Colors.green;
      case 'update':
        return Colors.orange;
      case 'deletion':
        return Colors.red;
      case 'receipt':
        return Colors.purple;
      case 'transmission':
        return Colors.teal;
      case 'system':
        return Colors.grey;
      case 'security':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  // Build service type item
  Widget _buildServiceTypeItem(
      String type, int count, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            type,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build services log card
  Widget _buildServicesLogCard() {
    final logs = _reportData!['logs'] as List<DispatchLog>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Services Log',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${logs.length} entries',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(),
            logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No logs found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length > 10 ? 10 : logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log);
                    },
                  ),
            if (logs.length > 10)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    // Show all logs in a dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('All Services'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 500,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return _buildLogItem(log);
                            },
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
                  },
                  icon: const Icon(FontAwesomeIcons.list, size: 16),
                  label: const Text('View All Services'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build log item
  Widget _buildLogItem(DispatchLog log) {
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

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: actionColor.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(actionIcon, color: actionColor, size: 16),
      ),
      title: Text(log.action),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (log.notes.isNotEmpty)
            Text(
              log.notes,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        log.performedBy,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      onTap: () {
        // Show log details
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Service Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    subtitle: Text(DateFormat('dd MMM yyyy HH:mm:ss')
                        .format(log.timestamp)),
                  ),
                  if (log.notes.isNotEmpty)
                    ListTile(
                      leading: const Icon(FontAwesomeIcons.noteSticky),
                      title: const Text('Notes'),
                      subtitle: Text(log.notes),
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
      },
    );
  }

  // Build action buttons row
  Widget _buildActionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _printReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(FontAwesomeIcons.print),
            label: const Text('Print Report'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _exportReport,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(FontAwesomeIcons.fileExport),
            label: const Text('Export Report'),
          ),
        ),
      ],
    );
  }

  // Print report
  Future<void> _printReport() async {
    // Report functionality has been removed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report printing functionality has been removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Export report as PDF
  Future<void> _exportReport() async {
    // Report functionality has been removed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export functionality has been removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Generate PDF
  Future<pw.Document> _generatePdf() async {
    // Create a new PDF document
    final pdf = pw.Document();

    // Get report data
    final status = _reportData!['currentStatus'] as String;
    final lastChecked = _reportData!['lastChecked'] as DateTime;
    final lastCheckedBy = _reportData!['lastCheckedBy'] as String;
    final uptimePercentage = _reportData!['uptimePercentage'] as double;
    final totalChecks = _reportData!['totalChecks'] as int;
    final logs = _reportData!['logs'] as List<DispatchLog>;
    final servicesByType = _reportData!['servicesByType'] as Map<String, int>;

    // Format date range for display
    String dateRangeText = 'All Time';
    if (_startDate != null && _endDate != null) {
      final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
      final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
      dateRangeText = '$startFormatted to $endFormatted';
    } else if (_startDate != null) {
      final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
      dateRangeText = 'From $startFormatted';
    } else if (_endDate != null) {
      final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
      dateRangeText = 'Until $endFormatted';
    }

    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(
            'Communication State Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Footer(
          trailing: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
            ),
          ),
        ),
        build: (context) => [
          // Report metadata
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Report Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date Range: $_timeRange ($dateRangeText)'),
                    pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Service Type: $_serviceTypeFilter'),
                    pw.Text('Total Services: ${logs.length}'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Current Status
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Current Status',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          status,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: _getPdfStatusColor(status),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Last checked: ${DateFormat('dd MMM yyyy HH:mm').format(lastChecked)}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'By: $lastCheckedBy',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Uptime',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${uptimePercentage.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Total Checks: $totalChecks',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Services by Type
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Services by Type',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Service Type',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Count',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Percentage',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    ...servicesByType.entries.map((entry) {
                      final serviceType = entry.key;
                      final count = entry.value;
                      final percentage = logs.isNotEmpty
                          ? (count / logs.length * 100).toStringAsFixed(1)
                          : '0';

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(serviceType),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(count.toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$percentage%'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Services Log
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Services Log',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Action',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Performed By',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Notes',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Data rows
                    ...logs.map((log) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(DateFormat('dd MMM yyyy HH:mm')
                                .format(log.timestamp)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(log.action),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(log.performedBy),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(log.notes),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  // Helper to get PDF status color
  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case 'Operational':
        return PdfColors.green;
      case 'Down':
        return PdfColors.red;
      case 'Intermittent':
        return PdfColors.orange;
      case 'Under Maintenance':
        return PdfColors.blue;
      default:
        return PdfColors.grey;
    }
  }
}
