import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/basic_transit_slip_generator.dart';
import '../screens/reports/pdf_preview_screen.dart';

/// A basic dialog for generating Transit Slip reports with visible black borders
class BasicTransitSlipDialog extends StatefulWidget {
  const BasicTransitSlipDialog({super.key});

  @override
  State<BasicTransitSlipDialog> createState() => _BasicTransitSlipDialogState();
}

class _BasicTransitSlipDialogState extends State<BasicTransitSlipDialog> {
  final BasicTransitSlipGenerator _transitSlipGenerator =
      BasicTransitSlipGenerator();

  final TextEditingController _unitCodeController = TextEditingController();

  String _destinationUnit = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

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
    _unitCodeController.text = '521SR'; // Default unit code
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

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Date:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                ),
                                const Spacer(),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'End Date:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                ),
                                const Spacer(),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generateTransitSlip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isGenerating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Generate Transit Slip'),
        ),
      ],
    );
  }

  // Select date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
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
      final pdf = await _transitSlipGenerator.generateTransitSlip(
        unitCode: _unitCodeController.text,
        destinationUnit: _destinationUnit,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Generate filename with current date
      final currentDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          'Transit_Slip_${_unitCodeController.text}_$currentDate.pdf';

      // Store the generated PDF and filename for use after setState
      final generatedPdf = pdf;
      final generatedFileName = fileName;

      // Save the report to the library
      final savedReport = await _transitSlipGenerator.saveReportToLibrary(
        pdfDocument: generatedPdf,
        unitCode: _unitCodeController.text,
        destinationUnit: _destinationUnit,
      );

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
              savedReport: savedReport,
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
