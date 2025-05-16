import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
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
  String _performedByFilter = '';
  String _sortBy = 'date';
  bool _sortAscending = false;

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
