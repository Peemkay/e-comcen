import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/unit.dart';
import '../../services/dispatch_service.dart';
import '../../services/unit_service.dart';
import '../../services/unit_manager.dart';

class TransitSlipGenerator extends StatefulWidget {
  const TransitSlipGenerator({Key? key}) : super(key: key);

  @override
  State<TransitSlipGenerator> createState() => _TransitSlipGeneratorState();
}

class _TransitSlipGeneratorState extends State<TransitSlipGenerator> {
  final DispatchService _dispatchService = DispatchService();
  final UnitService _unitService = UnitService();
  final UnitManager _unitManager = UnitManager();

  // List of all dispatches and units
  List<OutgoingDispatch> _allDispatches = [];
  List<OutgoingDispatch> _filteredDispatches = [];
  List<Unit> _allUnits = [];
  Unit? _primaryUnit;
  Unit? _selectedToUnit;

  // Saved slips history
  List<Map<String, dynamic>> _savedSlips = [];

  // Loading states
  bool _isLoading = true;
  bool _isGenerating = false;

  // Filter options
  DateTime? _startDate;
  DateTime? _endDate;
  String? _fromUnitFilter;
  String? _toUnitFilter;

  // Sort options
  String _sortBy = 'date';
  bool _sortAscending = false;

  // PDF settings are now directly used in the _generateTransitSlip method

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize unit manager
      await _unitManager.initialize();

      // Load units
      final units = await _unitManager.getAllUnits();

      // Find primary unit
      final primaryUnit = units.firstWhere(
        (unit) => unit.isPrimary,
        orElse: () => units.isNotEmpty
            ? units.first
            : Unit(
                id: 'default',
                name: 'Nigerian Army School of Signals',
                code: 'NAS',
                isPrimary: true,
              ),
      );

      // Load dispatches
      final dispatches = _dispatchService.getOutgoingDispatches();

      // Load saved slips history (would be from a service in a real app)
      final savedSlips = [
        {
          'id': '1',
          'name': 'Transit Slip - NAS to HQ - 2023-01-15',
          'path': '/path/to/file1.pdf',
          'date': DateTime(2023, 1, 15),
          'fromUnit': 'NAS',
          'toUnit': 'HQ',
        },
        {
          'id': '2',
          'name': 'Transit Slip - NAS to DIV - 2023-02-20',
          'path': '/path/to/file2.pdf',
          'date': DateTime(2023, 2, 20),
          'fromUnit': 'NAS',
          'toUnit': 'DIV',
        },
      ];

      if (mounted) {
        setState(() {
          _allUnits = units;
          _primaryUnit = primaryUnit;
          _selectedToUnit = units.length > 1 ? units[1] : units.firstOrNull;
          _allDispatches = dispatches;
          _filteredDispatches = List.from(dispatches);
          _savedSlips = savedSlips;
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
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDispatches = _allDispatches.where((dispatch) {
        // Date filter
        final dateMatches =
            (_startDate == null || dispatch.dateTime.isAfter(_startDate!)) &&
                (_endDate == null ||
                    dispatch.dateTime
                        .isBefore(_endDate!.add(const Duration(days: 1))));

        // From unit filter
        final fromMatches = _fromUnitFilter == null ||
            dispatch.sentBy
                .toLowerCase()
                .contains(_fromUnitFilter!.toLowerCase());

        // To unit filter
        final toMatches = _toUnitFilter == null ||
            dispatch.recipientUnit
                .toLowerCase()
                .contains(_toUnitFilter!.toLowerCase());

        return dateMatches && fromMatches && toMatches;
      }).toList();

      _sortDispatches();
    });
  }

  void _sortDispatches() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredDispatches.sort((a, b) => _sortAscending
              ? a.dateTime.compareTo(b.dateTime)
              : b.dateTime.compareTo(a.dateTime));
          break;
        case 'reference':
          _filteredDispatches.sort((a, b) => _sortAscending
              ? a.referenceNumber.compareTo(b.referenceNumber)
              : b.referenceNumber.compareTo(a.referenceNumber));
          break;
        case 'from':
          _filteredDispatches.sort((a, b) => _sortAscending
              ? a.sentBy.compareTo(b.sentBy)
              : b.sentBy.compareTo(a.sentBy));
          break;
        case 'to':
          _filteredDispatches.sort((a, b) => _sortAscending
              ? a.recipientUnit.compareTo(b.recipientUnit)
              : b.recipientUnit.compareTo(a.recipientUnit));
          break;
      }
    });
  }

  Future<void> _generateTransitSlip() async {
    if (_primaryUnit == null || _selectedToUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From and To units'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create PDF document
      final pdf = pw.Document();

      // Use A4 page format with specific margins to match the preview exactly
      final pageFormat = PdfPageFormat.a4.copyWith(
        marginTop: 50,
        marginBottom: 50,
        marginLeft: 50,
        marginRight: 50,
      );

      // Add page with content that exactly matches the preview
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            // Create a courier font
            final courierFont = pw.Font.courier();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Center(
                  child: pw.Text(
                    'TRANSIT SLIP FROM ${_primaryUnit?.code ?? "NAS"} TO: ${_selectedToUnit?.code ?? ""}',
                    style: pw.TextStyle(
                      font: courierFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1), // S/N
                    1: pw.FlexColumnWidth(2), // DATE
                    2: pw.FlexColumnWidth(2), // FROM
                    3: pw.FlexColumnWidth(2), // TO
                    4: pw.FlexColumnWidth(3), // REFS NO
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'S/N',
                            style: pw.TextStyle(
                              font: courierFont,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'DATE',
                            style: pw.TextStyle(
                              font: courierFont,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'FROM',
                            style: pw.TextStyle(
                              font: courierFont,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'TO',
                            style: pw.TextStyle(
                              font: courierFont,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'REFS NO',
                            style: pw.TextStyle(
                              font: courierFont,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Data rows - add actual dispatch data
                    for (int i = 0; i < _filteredDispatches.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${i + 1}',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(_filteredDispatches[i].dateTime),
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _getSenderUnitCode(_filteredDispatches[i]),
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _getRecipientUnitCode(_filteredDispatches[i]),
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              _filteredDispatches[i].referenceNumber,
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Add empty rows to reach 50 total rows
                    for (int i = 0; i < (50 - _filteredDispatches.length); i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${_filteredDispatches.length + i + 1}',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '',
                              style: pw.TextStyle(
                                font: courierFont,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Signature section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Prepared by
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PREPARED BY:',
                            style: pw.TextStyle(
                                font: courierFont,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('RANK:_______________________',
                            style: pw.TextStyle(font: courierFont)),
                        pw.SizedBox(height: 10),
                        pw.Text('NAME:_______________________',
                            style: pw.TextStyle(font: courierFont)),
                        pw.SizedBox(height: 10),
                        pw.Text('DATE/SIGN:__________________',
                            style: pw.TextStyle(font: courierFont)),
                      ],
                    ),

                    // Received by
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECEIVED BY:',
                            style: pw.TextStyle(
                                font: courierFont,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('RANK:_______________________',
                            style: pw.TextStyle(font: courierFont)),
                        pw.SizedBox(height: 10),
                        pw.Text('NAME:_______________________',
                            style: pw.TextStyle(font: courierFont)),
                        pw.SizedBox(height: 10),
                        pw.Text('DATE/SIGN:__________________',
                            style: pw.TextStyle(font: courierFont)),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Generate default filename and path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'transit_slip_${_primaryUnit!.code}_to_${_selectedToUnit!.code}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      // Get the Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();

      // Create the Dispatches/Transit directory if it doesn't exist
      final saveDir = Directory('${documentsDir.path}/Dispatches/Transit');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Default save path
      final defaultSavePath = '${saveDir.path}/$fileName';

      // Prompt user for save location
      String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Transit Slip',
        fileName: fileName,
        initialDirectory: saveDir.path,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // If user cancelled, use default path
      final savePath = selectedPath ?? defaultSavePath;

      // Save the PDF
      final file = File(savePath);
      await file.writeAsBytes(await pdf.save());

      // Add to saved slips
      final newSlip = {
        'id': timestamp.toString(),
        'name':
            'Transit Slip - ${_primaryUnit!.code} to ${_selectedToUnit!.code} - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        'path': file.path,
        'date': DateTime.now(),
        'fromUnit': _primaryUnit!.code,
        'toUnit': _selectedToUnit!.code,
      };

      setState(() {
        _savedSlips.add(newSlip);
        _isGenerating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transit slip saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _viewPdf(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating transit slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewPdf(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Transit Slip'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withAlpha(13),
                    Colors.white,
                  ],
                ),
              ),
              // Make the entire content scrollable
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Section - Two columns or stacked based on screen size
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: isSmallScreen
                              // Stack layout for small screens
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Settings Section
                                    _buildSettingsSection(),
                                    const SizedBox(height: 24),

                                    // Filter Bar
                                    _buildFilterBar(),
                                    const SizedBox(height: 16),

                                    // Transit Slip Preview
                                    Container(
                                      height: 600, // Fixed height for preview
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withAlpha(40),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(24.0),
                                          child: _buildTransitSlipPreview(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              // Side-by-side layout for larger screens
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column - Transit Slip Preview
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Filter Bar
                                          _buildFilterBar(),
                                          const SizedBox(height: 16),

                                          // Transit Slip Preview
                                          Container(
                                            height:
                                                600, // Fixed height for preview
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Colors.grey.withAlpha(40),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: SingleChildScrollView(
                                                padding:
                                                    const EdgeInsets.all(24.0),
                                                child:
                                                    _buildTransitSlipPreview(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Right Column - Settings and Actions
                                    Expanded(
                                      flex: 1,
                                      child: _buildSettingsSection(),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Second Section - Saved Slips History
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with filter
                              Row(
                                children: [
                                  const Text(
                                    'Saved Transit Slips',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.filter_list),
                                    onPressed: () {
                                      // Show filter dialog for saved slips
                                    },
                                    tooltip: 'Filter',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.sort),
                                    onPressed: () {
                                      // Show sort dialog for saved slips
                                    },
                                    tooltip: 'Sort',
                                  ),
                                ],
                              ),
                              const Divider(),

                              // Saved slips grid - with fixed height
                              SizedBox(
                                height: 300, // Fixed height for history section
                                child: _savedSlips.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No saved transit slips yet',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    : GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isSmallScreen
                                              ? 2
                                              : 4, // Responsive grid
                                          childAspectRatio: 1.2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: _savedSlips.length,
                                        itemBuilder: (context, index) {
                                          final slip = _savedSlips[index];
                                          return _buildSavedSlipCard(slip);
                                        },
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
    );
  }

  // Extracted settings section to a separate method for reuse
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent expansion
      children: [
        // Page Settings
        const Text(
          'Page Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Divider(),

        // Units Selection
        const Text(
          'From Unit:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildUnitDropdown(_primaryUnit, (unit) {
          setState(() {
            _primaryUnit = unit;
          });
        }),

        const SizedBox(height: 16),
        const Text(
          'To Unit:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildUnitDropdown(_selectedToUnit, (unit) {
          setState(() {
            _selectedToUnit = unit;
          });
        }),

        const SizedBox(height: 24),

        // Page Size Settings
        const Text(
          'Page Size:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: 'A4',
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'A4',
              child: Text('A4'),
            ),
            DropdownMenuItem(
              value: 'Letter',
              child: Text('Letter'),
            ),
          ],
          onChanged: (value) {
            // We now use A4 format directly in the _generateTransitSlip method
          },
        ),

        const SizedBox(height: 24),

        // Margins
        const Text(
          'Margins:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '50',
                decoration: const InputDecoration(
                  labelText: 'All',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // We now use fixed margins in the _generateTransitSlip method
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Generate & Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isGenerating ? null : _generateTransitSlip,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text('View PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isGenerating
                ? null
                : () async {
                    // First generate the PDF
                    await _generateTransitSlip();

                    // Then open the last saved slip
                    if (_savedSlips.isNotEmpty) {
                      final lastSlip = _savedSlips.last;
                      await _viewPdf(lastSlip['path']);
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Date Range
          Expanded(
            child: InkWell(
              onTap: () async {
                final dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: _startDate != null && _endDate != null
                      ? DateTimeRange(start: _startDate!, end: _endDate!)
                      : null,
                );

                if (dateRange != null) {
                  setState(() {
                    _startDate = dateRange.start;
                    _endDate = dateRange.end;
                  });
                  _applyFilters();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!)}'
                          : 'Select Date Range',
                      style: TextStyle(
                        color: _startDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // From Unit Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('From Unit'),
                  value: _fromUnitFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Units'),
                    ),
                    ..._allUnits.map((unit) => DropdownMenuItem<String>(
                          value: unit.code,
                          child: Text(unit.code),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _fromUnitFilter = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // To Unit Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('To Unit'),
                  value: _toUnitFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Units'),
                    ),
                    ..._allUnits.map((unit) => DropdownMenuItem<String>(
                          value: unit.code,
                          child: Text(unit.code),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _toUnitFilter = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Sort Button
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sort By'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Date'),
                          leading: Radio<String>(
                            value: 'date',
                            groupValue: _sortBy,
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                              _sortDispatches();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Reference Number'),
                          leading: Radio<String>(
                            value: 'reference',
                            groupValue: _sortBy,
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                              _sortDispatches();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('From Unit'),
                          leading: Radio<String>(
                            value: 'from',
                            groupValue: _sortBy,
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                              _sortDispatches();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('To Unit'),
                          leading: Radio<String>(
                            value: 'to',
                            groupValue: _sortBy,
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                              _sortDispatches();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Ascending Order'),
                          value: _sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _sortAscending = value;
                            });
                            _sortDispatches();
                          },
                        ),
                      ],
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
              tooltip: 'Sort',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitSlipPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Center(
          child: Text(
            'TRANSIT SLIP FROM ${_primaryUnit?.code ?? "NAS"} TO: ${_selectedToUnit?.code ?? ""}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Table
        Table(
          border: TableBorder.all(color: Colors.black, width: 1),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1), // S/N
            1: FlexColumnWidth(2), // DATE
            2: FlexColumnWidth(2), // FROM
            3: FlexColumnWidth(2), // TO
            4: FlexColumnWidth(3), // REFS NO
          },
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                _buildTableCellPreview('S/N', isHeader: true),
                _buildTableCellPreview('DATE', isHeader: true),
                _buildTableCellPreview('FROM', isHeader: true),
                _buildTableCellPreview('TO', isHeader: true),
                _buildTableCellPreview('REFS NO', isHeader: true),
              ],
            ),

            // Data rows - generate 50 rows if needed
            ..._generatePreviewTableRows(),
          ],
        ),
        const SizedBox(height: 20),

        // Signature section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prepared by
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PREPARED BY:',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('RANK:_______________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                SizedBox(height: 6),
                Text('NAME:_______________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                SizedBox(height: 6),
                Text('DATE/SIGN:__________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),

            // Received by
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('RECEIVED BY:',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('RANK:_______________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                SizedBox(height: 6),
                Text('NAME:_______________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                SizedBox(height: 6),
                Text('DATE/SIGN:__________________',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to generate preview table rows, ensuring we have up to 50 rows
  List<TableRow> _generatePreviewTableRows() {
    final rows = <TableRow>[];

    // Add actual dispatch data rows
    for (int i = 0; i < _filteredDispatches.length; i++) {
      final dispatch = _filteredDispatches[i];
      rows.add(
        TableRow(
          children: [
            _buildTableCellPreview('${i + 1}'),
            _buildTableCellPreview(
                DateFormat('dd/MM/yyyy').format(dispatch.dateTime)),
            _buildTableCellPreview(_getSenderUnitCode(dispatch)),
            _buildTableCellPreview(_getRecipientUnitCode(dispatch)),
            _buildTableCellPreview(dispatch.referenceNumber),
          ],
        ),
      );
    }

    // Add empty rows to reach 50 total rows
    final emptyRowsNeeded = 50 - _filteredDispatches.length;
    if (emptyRowsNeeded > 0) {
      for (int i = 0; i < emptyRowsNeeded; i++) {
        rows.add(
          TableRow(
            children: [
              _buildTableCellPreview('${_filteredDispatches.length + i + 1}'),
              _buildTableCellPreview(''),
              _buildTableCellPreview(''),
              _buildTableCellPreview(''),
              _buildTableCellPreview(''),
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildTableCellPreview(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6.0), // Slightly larger padding
      child: Text(
        text,
        style: TextStyle(
          fontFamily:
              'monospace', // Use monospace font which is more widely available
          fontSize: 10, // Slightly larger font size
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(Unit? selectedUnit, Function(Unit?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Unit>(
          value: selectedUnit,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: _allUnits
              .map((unit) => DropdownMenuItem<Unit>(
                    value: unit,
                    child: Text('${unit.code} - ${unit.name}'),
                  ))
              .toList(),
          onChanged: (unit) => onChanged(unit),
        ),
      ),
    );
  }

  // Helper method to get the sender unit code from a dispatch
  String _getSenderUnitCode(OutgoingDispatch dispatch) {
    // The FROM column should show the sender unit code from the transit form
    // This is similar to how the TO column shows the recipient unit

    // In the OutgoingDispatch class, sentBy field contains the sender unit name
    // We need to extract the unit code from this name

    // First, try to find a unit with a matching name in our units list
    for (var unit in _allUnits) {
      if (unit.name.toLowerCase() == dispatch.sentBy.toLowerCase()) {
        return unit.code;
      }
    }

    // If we couldn't find a matching unit, create a code from the first 3 characters
    // of the sentBy field (which should be the sender unit name)
    if (dispatch.sentBy.isNotEmpty) {
      return dispatch.sentBy
          .substring(0, dispatch.sentBy.length > 3 ? 3 : dispatch.sentBy.length)
          .toUpperCase();
    }

    // If all else fails, use the primary unit code as fallback
    return _primaryUnit?.code ?? "NAS";
  }

  // Helper method to get the recipient unit code from a dispatch
  String _getRecipientUnitCode(OutgoingDispatch dispatch) {
    // The TO column should show the recipient unit code from the transit form

    // First, try to find a unit with a matching name
    for (var unit in _allUnits) {
      // Check if this unit's name matches the recipient unit name
      if (unit.name.toLowerCase() == dispatch.recipientUnit.toLowerCase()) {
        return unit.code;
      }
    }

    // If we couldn't find a matching unit, create a code from the first 3 characters
    if (dispatch.recipientUnit.isNotEmpty) {
      return dispatch.recipientUnit
          .substring(
              0,
              dispatch.recipientUnit.length > 3
                  ? 3
                  : dispatch.recipientUnit.length)
          .toUpperCase();
    }

    // If all else fails, use the selected TO unit code as fallback
    return _selectedToUnit?.code ?? "REC";
  }

  Widget _buildSavedSlipCard(Map<String, dynamic> slip) {
    return InkWell(
      onTap: () => _viewPdf(slip['path']),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              const Icon(
                FontAwesomeIcons.filePdf,
                color: AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(height: 8),

              // Name
              Text(
                slip['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Date
              Text(
                DateFormat('dd MMM yyyy').format(slip['date']),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => _viewPdf(slip['path']),
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download, size: 18),
                    onPressed: () {
                      // Download functionality
                    },
                    tooltip: 'Download',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
