import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/transit_slip_service.dart';
import '../services/dispatch_service.dart';
import '../screens/reports/pdf_preview_screen.dart';
import '../widgets/report_settings_dialog.dart';

/// Dialog for generating Transit Slip reports
class TransitSlipDialog extends StatefulWidget {
  const TransitSlipDialog({super.key});

  @override
  State<TransitSlipDialog> createState() => _TransitSlipDialogState();
}

class _TransitSlipDialogState extends State<TransitSlipDialog> {
  final TransitSlipService _transitSlipService = TransitSlipService();
  final DispatchService _dispatchService = DispatchService();

  final TextEditingController _unitCodeController = TextEditingController();

  String _destinationUnit = '';
  List<String> _selectedToUnits = ['All Units'];
  List<String> _selectedFromUnits = ['All Units'];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  String? _generatedFilePath;

  // Lists of units for filtering
  List<String> _toUnits = ['All Units'];
  List<String> _fromUnits = ['All Units'];

  // List of Nigerian Army Signal Units
  final List<String> _armySignalUnits = [
    'Select Unit',
    '521 Signal Regiment',
    '522 Signal Regiment',
    '523 Signal Regiment',
    '524 Signal Regiment',
    '54 Signal Brigade',
    'Nigerian Army Signal School',
    'Nigerian Army Signal Corps HQ',
    'Other (Enter Manually)',
  ];

  @override
  void initState() {
    super.initState();
    _destinationUnit = _armySignalUnits.first;
    _unitCodeController.text = '521SR'; // Default unit code (Signal Regiment)
    _loadFilterUnits();
  }

  // Load unique "To" and "From" units from outgoing dispatches
  void _loadFilterUnits() {
    final dispatches = _dispatchService.getOutgoingDispatches();
    final Set<String> uniqueToUnits = {'All Units'};
    final Set<String> uniqueFromUnits = {'All Units'};

    // Debug the number of dispatches
    debugPrint(
        'Number of outgoing dispatches for filtering: ${dispatches.length}');

    for (final dispatch in dispatches) {
      // Add recipient units (To units)
      if (dispatch.recipient.isNotEmpty) {
        uniqueToUnits.add(dispatch.recipient);
      }
      if (dispatch.recipientUnit.isNotEmpty) {
        uniqueToUnits.add(dispatch.recipientUnit);
      }

      // Add sender units (From units)
      if (dispatch.sender.isNotEmpty) {
        uniqueFromUnits.add(dispatch.sender);
      }
    }

    // Debug the unique units found
    debugPrint('Unique To Units: ${uniqueToUnits.length}');
    debugPrint('Unique From Units: ${uniqueFromUnits.length}');

    setState(() {
      _toUnits = uniqueToUnits.toList()..sort();
      _fromUnits = uniqueFromUnits.toList()..sort();
    });
  }

  @override
  void dispose() {
    _unitCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const FaIcon(FontAwesomeIcons.fileExport, size: 20),
          const SizedBox(width: 8),
          const Text('Generate Transit Slip'),
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
              // Unit Code field
              const Text(
                'Unit Code:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _unitCodeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your unit code (e.g., 521SR)',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              // Destination Unit dropdown
              const Text(
                'Destination Unit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _destinationUnit,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _armySignalUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _destinationUnit = value!;
                  });
                },
              ),

              // Manual destination unit input (if "Other" is selected)
              if (_destinationUnit == 'Other (Enter Manually)') ...[
                const SizedBox(height: 16),
                const Text(
                  'Enter Destination Unit:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter destination unit name',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    // Store the manually entered value
                    _destinationUnit = value;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Filter To Units
              const Text(
                'Filter To Units:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // "Select All" option
                    CheckboxListTile(
                      title: const Text('All Units'),
                      value: _selectedToUnits.contains('All Units'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedToUnits = ['All Units'];
                          } else {
                            _selectedToUnits.remove('All Units');
                            if (_selectedToUnits.isEmpty) {
                              _selectedToUnits = ['All Units'];
                            }
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const Divider(height: 1),
                    // List of units (only show if "All Units" is not selected)
                    if (!_selectedToUnits.contains('All Units'))
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _toUnits
                              .where((unit) => unit != 'All Units')
                              .length,
                          itemBuilder: (context, index) {
                            final unit = _toUnits
                                .where((unit) => unit != 'All Units')
                                .toList()[index];
                            return CheckboxListTile(
                              title: Text(unit),
                              value: _selectedToUnits.contains(unit),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedToUnits.add(unit);
                                  } else {
                                    _selectedToUnits.remove(unit);
                                    if (_selectedToUnits.isEmpty) {
                                      _selectedToUnits = ['All Units'];
                                    }
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filter From Units
              const Text(
                'Filter From Units:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // "Select All" option
                    CheckboxListTile(
                      title: const Text('All Units'),
                      value: _selectedFromUnits.contains('All Units'),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFromUnits = ['All Units'];
                          } else {
                            _selectedFromUnits.remove('All Units');
                            if (_selectedFromUnits.isEmpty) {
                              _selectedFromUnits = ['All Units'];
                            }
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const Divider(height: 1),
                    // List of units (only show if "All Units" is not selected)
                    if (!_selectedFromUnits.contains('All Units'))
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _fromUnits
                              .where((unit) => unit != 'All Units')
                              .length,
                          itemBuilder: (context, index) {
                            final unit = _fromUnits
                                .where((unit) => unit != 'All Units')
                                .toList()[index];
                            return CheckboxListTile(
                              title: Text(unit),
                              value: _selectedFromUnits.contains(unit),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedFromUnits.add(unit);
                                  } else {
                                    _selectedFromUnits.remove(unit);
                                    if (_selectedFromUnits.isEmpty) {
                                      _selectedFromUnits = ['All Units'];
                                    }
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date Range
              const Text(
                'Date Range:',
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_endDate),
                        ),
                      ),
                    ),
                  ),
                ],
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
                              'Transit Slip Generated Successfully',
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
          onPressed: _isGenerating ? null : _generateTransitSlip,
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
          label:
              Text(_isGenerating ? 'Generating...' : 'Generate Transit Slip'),
        ),
      ],
    );
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
        settings: _transitSlipService.settings,
        onSettingsUpdated: (newSettings) {
          // Update report settings
          _transitSlipService.updateSettings(newSettings);

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

  // Generate transit slip
  Future<void> _generateTransitSlip() async {
    // Validate inputs
    if (_unitCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a unit code')),
      );
      return;
    }

    if (_destinationUnit.isEmpty || _destinationUnit == 'Select Unit') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination unit')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate the transit slip
      final pdf = await _transitSlipService.generateTransitSlip(
        unitCode: _unitCodeController.text,
        destinationUnit: _destinationUnit,
        startDate: _startDate,
        endDate: _endDate,
        filterToUnits:
            _selectedToUnits.contains('All Units') ? null : _selectedToUnits,
        filterFromUnits: _selectedFromUnits.contains('All Units')
            ? null
            : _selectedFromUnits,
      );

      // Generate filename with current date
      final currentDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          'Transit_Slip_${_unitCodeController.text}_$currentDate.pdf';

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
              title: 'Transit Slip Preview',
            ),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Transit Slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isGenerating = false;
      });
    }
  }
}
