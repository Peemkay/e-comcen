import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../services/dispatch_service.dart';
import '../../services/report_generation_service.dart';
import '../../widgets/report_settings_dialog.dart';
import '../reports/pdf_preview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DispatchService _dispatchService = DispatchService();
  final ReportGenerationService _reportService = ReportGenerationService();
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  String _selectedReportType = 'Dispatch Summary';
  String _selectedTimeRange = 'Last 7 Days';
  String? _lastGeneratedReportPath;

  // Report filter variables
  String _senderUnitFilter = 'All';
  String _receiverUnitFilter = 'All';
  String _categoryFilter = 'All';
  String _priorityFilter = 'All';
  String _statusFilter = 'All';
  String _sortBy = 'Date (Newest)';
  bool _isFilterActive = false;

  final List<String> _reportTypes = [
    'Dispatch Summary',
    'Dispatch Status',
    'User Activity',
    'Communication State',
    'Delivery Performance',
  ];

  final List<String> _timeRanges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  final List<String> _categories = [
    'All',
    'Incoming',
    'Outgoing',
    'Local',
    'External',
    'Comcen Logs',
  ];

  final List<String> _priorities = [
    'All',
    'Normal',
    'Urgent',
    'Flash',
    'IMM',
  ];

  final List<String> _statuses = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'Delivered',
    'Received',
  ];

  final List<String> _sortOptions = [
    'Date (Newest)',
    'Date (Oldest)',
    'Priority',
    'Reference Number',
  ];

  // Lists for sender and receiver units (will be populated dynamically)
  List<String> _senderUnits = ['All'];
  List<String> _receiverUnits = ['All'];

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 7 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 7));

    // Load sender and receiver units
    _loadUnits();
  }

  // Load sender and receiver units from the dispatch service
  Future<void> _loadUnits() async {
    try {
      // Get all dispatches
      final incomingDispatches = _dispatchService.getIncomingDispatches();
      final outgoingDispatches = _dispatchService.getOutgoingDispatches();

      // Extract unique sender units
      final senderUnits = {'All'};
      for (var dispatch in incomingDispatches) {
        if (dispatch.senderUnit.isNotEmpty) {
          senderUnits.add(dispatch.senderUnit);
        }
      }

      // Extract unique receiver units
      final receiverUnits = {'All'};
      for (var dispatch in outgoingDispatches) {
        if (dispatch.recipientUnit.isNotEmpty) {
          receiverUnits.add(dispatch.recipientUnit);
        }
      }

      setState(() {
        _senderUnits = senderUnits.toList();
        _receiverUnits = receiverUnits.toList();
      });
    } catch (e) {
      debugPrint('Error loading units: $e');
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _isGeneratingPdf = true;
    });

    // Apply filters to the report
    _applyFilters();

    try {
      // Get date range based on selected time range
      final dateRange = _getDateRangeFromTimeRange();

      // Generate the report
      final pdf = await _reportService.generateDispatchReport(
        startDate: dateRange.start,
        endDate: dateRange.end,
        senderUnit: _senderUnitFilter != 'All' ? _senderUnitFilter : null,
        receiverUnit: _receiverUnitFilter != 'All' ? _receiverUnitFilter : null,
        category: _categoryFilter != 'All' ? _categoryFilter : null,
        priority: _priorityFilter != 'All' ? _priorityFilter : null,
        status: _statusFilter != 'All' ? _statusFilter : null,
        sortBy: _getSortByValue(),
        sortAscending: _sortBy.contains('Oldest'),
      );

      // Generate filename with current date
      final currentDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Dispatch_Report_$currentDate.pdf';

      // Store the generated PDF and filename for use after setState
      final generatedPdf = pdf;
      final generatedFileName = fileName;

      setState(() {
        _isLoading = false;
        _isGeneratingPdf = false;
      });

      // Show the PDF preview screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfDocument: generatedPdf,
              defaultFileName: generatedFileName,
              title: 'Dispatch Report Preview',
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
        _isGeneratingPdf = false;
      });
    }
  }

  // Get date range from selected time range
  DateTimeRange _getDateRangeFromTimeRange() {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate = now;

    switch (_selectedTimeRange) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        final lastMonth = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate =
            DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'Custom Range':
        startDate = _startDate ?? now.subtract(const Duration(days: 7));
        endDate = _endDate ?? now;
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return DateTimeRange(start: startDate, end: endDate);
  }

  // Get sort by value for report generation
  String _getSortByValue() {
    if (_sortBy.contains('Date')) {
      return 'date';
    } else if (_sortBy.contains('Priority')) {
      return 'priority';
    } else if (_sortBy.contains('Reference')) {
      return 'reference';
    } else {
      return 'date';
    }
  }

  // Open the generated report
  Future<void> _openGeneratedReport() async {
    if (_lastGeneratedReportPath != null) {
      try {
        // Open the file with the default application
        final opened =
            await _reportService.openReport(_lastGeneratedReportPath!);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Could not open the file. Try opening it manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Show report settings dialog
  void _showReportSettings() {
    showDialog(
      context: context,
      builder: (context) => ReportSettingsDialog(
        settings: _reportService.settings,
        onSettingsUpdated: (newSettings) {
          // Update report settings
          _reportService.updateSettings(newSettings);

          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report settings updated'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  // Apply filters to the report
  void _applyFilters() {
    // Check if any filter is active
    _isFilterActive = _senderUnitFilter != 'All' ||
        _receiverUnitFilter != 'All' ||
        _categoryFilter != 'All' ||
        _priorityFilter != 'All' ||
        _statusFilter != 'All';

    // Apply filters based on report type
    switch (_selectedReportType) {
      case 'Dispatch Summary':
        // Apply dispatch summary filters
        break;
      case 'Dispatch Status':
        // Apply dispatch status filters
        break;
      case 'User Activity':
        // Apply user activity filters
        break;
      case 'Communication State':
        // Apply communication state filters
        break;
      case 'Delivery Performance':
        // Apply delivery performance filters
        break;
    }
  }

  // Show advanced filter dialog
  void _showFilterDialog() {
    // Create temporary variables to hold filter values
    String tempSenderUnitFilter = _senderUnitFilter;
    String tempReceiverUnitFilter = _receiverUnitFilter;
    String tempCategoryFilter = _categoryFilter;
    String tempPriorityFilter = _priorityFilter;
    String tempStatusFilter = _statusFilter;
    String tempSortBy = _sortBy;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
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
                    tempSenderUnitFilter = 'All';
                    tempReceiverUnitFilter = 'All';
                    tempCategoryFilter = 'All';
                    tempPriorityFilter = 'All';
                    tempStatusFilter = 'All';
                    tempSortBy = 'Date (Newest)';
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
                    value: tempSenderUnitFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _senderUnits.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempSenderUnitFilter = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Receiver Unit filter section
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Receiver Unit (ADDR TO)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: tempReceiverUnitFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _receiverUnits.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempReceiverUnitFilter = value!;
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
                    children: _categories
                        .map((category) => _buildFilterChip(
                              category,
                              tempCategoryFilter == category,
                              (selected) {
                                setState(() {
                                  tempCategoryFilter =
                                      selected ? category : tempCategoryFilter;
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Priority filter section
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Priority',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: _priorities
                        .map((priority) => _buildFilterChip(
                              priority,
                              tempPriorityFilter == priority,
                              (selected) {
                                setState(() {
                                  tempPriorityFilter =
                                      selected ? priority : tempPriorityFilter;
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

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
                    children: _statuses
                        .map((status) => _buildFilterChip(
                              status,
                              tempStatusFilter == status,
                              (selected) {
                                setState(() {
                                  tempStatusFilter =
                                      selected ? status : tempStatusFilter;
                                });
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Sort by section
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Sort By',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: tempSortBy,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _sortOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        tempSortBy = value!;
                      });
                    },
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
                  _senderUnitFilter = tempSenderUnitFilter;
                  _receiverUnitFilter = tempReceiverUnitFilter;
                  _categoryFilter = tempCategoryFilter;
                  _priorityFilter = tempPriorityFilter;
                  _statusFilter = tempStatusFilter;
                  _sortBy = tempSortBy;

                  // Apply filters and regenerate report
                  _generateReport();
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
      }),
    );
  }

  // Build filter chip widget
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

  // Build active filter chip widget
  Widget _buildActiveFilterChip(String label, VoidCallback? onRemove) {
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
        FontAwesomeIcons.xmark,
        size: 12,
        color: AppTheme.primaryColor,
      ),
      onDeleted: onRemove,
      deleteButtonTooltipMessage: onRemove != null ? 'Remove filter' : null,
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedTimeRange = 'Custom Range';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              FontAwesomeIcons.filter,
              size: 18,
              color: _isFilterActive ? AppTheme.accentColor : Colors.white,
            ),
            tooltip: 'Filter Reports',
            onPressed: _showFilterDialog,
          ),

          // Report Library button
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.folderOpen,
              size: 18,
            ),
            tooltip: 'Report Library',
            onPressed: () {
              Navigator.pushNamed(context, '/report_library');
            },
          ),

          // Settings button
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.gear,
              size: 18,
            ),
            tooltip: 'Report Settings',
            onPressed: _showReportSettings,
          ),

          // Export button
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.fileExport,
              size: 18,
            ),
            tooltip: 'Export Report',
            onPressed: () {
              if (_lastGeneratedReportPath != null) {
                _openGeneratedReport();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generate a report first'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _reportTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedReportType = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Range Selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    DropdownButtonFormField<String>(
                      value: _selectedTimeRange,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _timeRanges.map((String range) {
                        return DropdownMenuItem<String>(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTimeRange = newValue!;

                          // Update date range based on selection
                          _endDate = DateTime.now();
                          switch (_selectedTimeRange) {
                            case 'Today':
                              _startDate = DateTime(_endDate!.year,
                                  _endDate!.month, _endDate!.day);
                              break;
                            case 'Last 7 Days':
                              _startDate =
                                  _endDate!.subtract(const Duration(days: 7));
                              break;
                            case 'Last 30 Days':
                              _startDate =
                                  _endDate!.subtract(const Duration(days: 30));
                              break;
                            case 'This Month':
                              _startDate =
                                  DateTime(_endDate!.year, _endDate!.month, 1);
                              break;
                            case 'Last Month':
                              final lastMonth = _endDate!.month == 1
                                  ? DateTime(_endDate!.year - 1, 12, 1)
                                  : DateTime(
                                      _endDate!.year, _endDate!.month - 1, 1);
                              _startDate = lastMonth;
                              _endDate =
                                  DateTime(_endDate!.year, _endDate!.month, 1)
                                      .subtract(const Duration(days: 1));
                              break;
                            case 'Custom Range':
                              // Do nothing, let user select
                              break;
                          }
                        });
                      },
                    ),
                    if (_selectedTimeRange == 'Custom Range') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDateRange(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                      : 'Select date range',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.calendar),
                            onPressed: () => _selectDateRange(context),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Report Preview
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedReportType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                      : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),

                            // Active filters display
                            if (_isFilterActive) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.filter,
                                          size: 14,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Active Filters:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _senderUnitFilter = 'All';
                                              _receiverUnitFilter = 'All';
                                              _categoryFilter = 'All';
                                              _priorityFilter = 'All';
                                              _statusFilter = 'All';
                                              _sortBy = 'Date (Newest)';
                                              _isFilterActive = false;
                                              _generateReport();
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text('Clear All'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (_senderUnitFilter != 'All')
                                          _buildActiveFilterChip(
                                            'Sender: $_senderUnitFilter',
                                            () {
                                              setState(() {
                                                _senderUnitFilter = 'All';
                                                _applyFilters();
                                                _generateReport();
                                              });
                                            },
                                          ),
                                        if (_receiverUnitFilter != 'All')
                                          _buildActiveFilterChip(
                                            'Receiver: $_receiverUnitFilter',
                                            () {
                                              setState(() {
                                                _receiverUnitFilter = 'All';
                                                _applyFilters();
                                                _generateReport();
                                              });
                                            },
                                          ),
                                        if (_categoryFilter != 'All')
                                          _buildActiveFilterChip(
                                            'Category: $_categoryFilter',
                                            () {
                                              setState(() {
                                                _categoryFilter = 'All';
                                                _applyFilters();
                                                _generateReport();
                                              });
                                            },
                                          ),
                                        if (_priorityFilter != 'All')
                                          _buildActiveFilterChip(
                                            'Priority: $_priorityFilter',
                                            () {
                                              setState(() {
                                                _priorityFilter = 'All';
                                                _applyFilters();
                                                _generateReport();
                                              });
                                            },
                                          ),
                                        if (_statusFilter != 'All')
                                          _buildActiveFilterChip(
                                            'Status: $_statusFilter',
                                            () {
                                              setState(() {
                                                _statusFilter = 'All';
                                                _applyFilters();
                                                _generateReport();
                                              });
                                            },
                                          ),
                                        _buildActiveFilterChip(
                                          'Sort: $_sortBy',
                                          null, // Sort option cannot be removed
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Report content placeholder
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.chartColumn,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Generate a report to view data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(FontAwesomeIcons.fileExport),
                label: const Text('Generate Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
