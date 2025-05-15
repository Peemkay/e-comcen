import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/incoming_report_service.dart';
import '../services/dispatch_service.dart';
import '../screens/reports/pdf_preview_screen.dart';
import '../widgets/report_settings_dialog.dart';

/// Dialog for generating Incoming Dispatch reports
class IncomingReportDialog extends StatefulWidget {
  const IncomingReportDialog({super.key});

  @override
  State<IncomingReportDialog> createState() => _IncomingReportDialogState();
}

class _IncomingReportDialogState extends State<IncomingReportDialog> {
  final IncomingReportService _reportService = IncomingReportService();
  final DispatchService _dispatchService = DispatchService();

  String _senderUnitFilter = 'All';
  String _addrToFilter = 'All';
  String _priorityFilter = 'All';
  String _statusFilter = 'All';
  String _sortBy = 'Date (Newest)';
  String _timeRange = 'Last 7 Days';

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isCustomDateRange = false;
  bool _isGenerating = false;
  String? _generatedFilePath;

  // Lists for filter options
  List<String> _senderUnits = ['All'];
  List<String> _addrToUnits = ['All'];

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

  final List<String> _timeRanges = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  // Load sender and receiver units
  Future<void> _loadUnits() async {
    try {
      // Get all dispatches
      final incomingDispatches = _dispatchService.getIncomingDispatches();

      // Extract unique sender units
      final senderUnits = {'All'};
      for (var dispatch in incomingDispatches) {
        if (dispatch.senderUnit.isNotEmpty) {
          senderUnits.add(dispatch.senderUnit);
        }
      }

      // Extract unique addr to units
      final addrToUnits = {'All'};
      for (var dispatch in incomingDispatches) {
        if (dispatch.addrTo.isNotEmpty) {
          addrToUnits.add(dispatch.addrTo);
        }
      }

      setState(() {
        _senderUnits = senderUnits.toList();
        _addrToUnits = addrToUnits.toList();
      });
    } catch (e) {
      debugPrint('Error loading units: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const FaIcon(FontAwesomeIcons.fileExport, size: 20),
          const SizedBox(width: 8),
          const Text('Generate Incoming Dispatch Report'),
          const Spacer(),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear, size: 18),
            onPressed: _showReportSettings,
            tooltip: 'Report Settings',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range
              const Text(
                'Time Range:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _timeRange,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _timeRanges.map((range) {
                  return DropdownMenuItem<String>(
                    value: range,
                    child: Text(range),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _timeRange = value!;
                    _isCustomDateRange = value == 'Custom Range';
                    _updateDateRange();
                  });
                },
              ),

              // Custom Date Range
              if (_isCustomDateRange) ...[
                const SizedBox(height: 16),
                const Text(
                  'Custom Date Range:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_endDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Sender Unit filter
              const Text(
                'Sender Unit (ADDR FROM):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _senderUnitFilter,
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
                    _senderUnitFilter = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Address To filter
              const Text(
                'Address To (ADDR TO):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _addrToFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _addrToUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _addrToFilter = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Priority filter
              const Text(
                'Priority:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _priorityFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priorityFilter = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Status filter
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _statusFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Sort By
              const Text(
                'Sort By:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
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
                    _sortBy = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Generated file info
              if (_generatedFilePath != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26), // 0.1 opacity
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Report Generated Successfully',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saved to: $_generatedFilePath',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const FaIcon(FontAwesomeIcons.fileExport, size: 16),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
        ),
      ],
    );
  }

  // Update date range based on selected time range
  void _updateDateRange() {
    final now = DateTime.now();

    switch (_timeRange) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
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
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last Month':
        final lastMonth = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate =
            DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
        break;
      case 'Custom Range':
        // Keep existing dates
        break;
    }
  }

  // Select date
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
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

  // Generate report
  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate the report
      final pdf = await _reportService.generateIncomingReport(
        startDate: _startDate,
        endDate: _endDate,
        senderUnit: _senderUnitFilter != 'All' ? _senderUnitFilter : null,
        addrTo: _addrToFilter != 'All' ? _addrToFilter : null,
        priority: _priorityFilter != 'All' ? _priorityFilter : null,
        status: _statusFilter != 'All' ? _statusFilter : null,
        sortBy: _getSortByValue(),
        sortAscending: _sortBy.contains('Oldest'),
      );

      // Generate filename with current date
      final currentDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'Incoming_Dispatch_Report_$currentDate.pdf';

      // Store the generated PDF and filename for use after setState
      final generatedPdf = pdf;
      final generatedFileName = fileName;

      setState(() {
        _isGenerating = false;
      });

      // Check if still mounted before proceeding
      if (mounted) {
        // Close the dialog and show the PDF preview screen
        Navigator.pop(context);

        // Show the PDF preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfDocument: generatedPdf,
              defaultFileName: generatedFileName,
              title: 'Incoming Dispatch Report Preview',
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
        _isGenerating = false;
      });
    }
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
}
