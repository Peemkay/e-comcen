import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'dart:ui' as ui;

import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/unit.dart';
import '../../services/dispatch_service.dart';
import '../../services/unit_manager.dart';
import '../../utils/responsive_util.dart';

class InFileSlipGenerator extends StatefulWidget {
  const InFileSlipGenerator({super.key});

  @override
  State<InFileSlipGenerator> createState() => _InFileSlipGeneratorState();
}

class _InFileSlipGeneratorState extends State<InFileSlipGenerator> {
  final DispatchService _dispatchService = DispatchService();
  final UnitManager _unitManager = UnitManager();

  // Key for capturing the preview section
  final GlobalKey _previewKey = GlobalKey();

  // List of all dispatches and units
  List<IncomingDispatch> _allDispatches = [];
  List<IncomingDispatch> _filteredDispatches = [];
  List<Unit> _allUnits = [];
  Unit? _primaryUnit;

  // Selected date for the slip title
  DateTime _selectedDate = DateTime.now();

  // Page settings
  PdfPageFormat _pageFormat = PdfPageFormat.a4;
  double _marginSize = 50.0;
  String _orientation = 'Portrait';
  String _fontFamily = 'Courier';
  double _fontSize = 10.0;
  double _headerFontSize = 16.0;
  double _tableBorderWidth = 1.0;

  // Saved slips history
  List<Map<String, dynamic>> _savedSlips = [];

  // Loading states
  bool _isLoading = true;
  bool _isGenerating = false;

  // Filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPriority;
  String? _selectedFromUnit;
  String? _selectedToUnit;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load units
      final units = await _unitManager.getAllUnits();
      final primaryUnit = units.firstWhere(
        (unit) => unit.isPrimary,
        orElse: () => units.isNotEmpty
            ? units.first
            : Unit(
                id: 'default',
                name: 'Default Unit',
                code: 'DEF',
              ),
      );

      // Load dispatches
      final dispatches = _dispatchService.getIncomingDispatches();

      // Load saved slips history (would be from a service in a real app)
      final savedSlips = [
        {
          'id': '1',
          'name':
              'IN FILE Slip - ${DateFormat('yyyy-MM-dd').format(DateTime(2023, 1, 15))}',
          'path': '/path/to/file1.pdf',
          'date': DateTime(2023, 1, 15),
        },
        {
          'id': '2',
          'name':
              'IN FILE Slip - ${DateFormat('yyyy-MM-dd').format(DateTime(2023, 2, 20))}',
          'path': '/path/to/file2.pdf',
          'date': DateTime(2023, 2, 20),
        },
      ];

      if (mounted) {
        setState(() {
          _allUnits = units;
          _primaryUnit = primaryUnit;
          _allDispatches = dispatches;
          _filteredDispatches = List.from(dispatches);
          _savedSlips = savedSlips;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Apply filters to the dispatches
  void _applyFilters() {
    setState(() {
      _filteredDispatches = _allDispatches.where((dispatch) {
        // Date range filter
        if (_startDate != null && dispatch.dateTime.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null &&
            dispatch.dateTime.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }

        // Priority filter
        if (_selectedPriority != null &&
            _selectedPriority!.isNotEmpty &&
            dispatch.priority != _selectedPriority) {
          return false;
        }

        // From unit filter
        if (_selectedFromUnit != null &&
            _selectedFromUnit!.isNotEmpty &&
            dispatch.senderUnit != _selectedFromUnit) {
          return false;
        }

        // To unit filter
        if (_selectedToUnit != null &&
            _selectedToUnit!.isNotEmpty &&
            dispatch.addrTo != _selectedToUnit) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  // Generate and save the IN FILE slip as PDF
  Future<void> _generateInFileSlip() async {
    if (_primaryUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary unit not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Capture the preview as an image
      final RenderRepaintBoundary boundary = _previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to capture preview as image');
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Create PDF document
      final pdf = pw.Document();

      // Add the captured image to the PDF with A4 size
      final pdfImage = pw.MemoryImage(pngBytes);

      // Create a page format with the selected margins
      final pageFormat = _pageFormat.copyWith(
        marginLeft: _marginSize,
        marginTop: _marginSize,
        marginRight: _marginSize,
        marginBottom: _marginSize,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      // Generate default filename and path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'in_file_slip_${DateFormat('yyyyMMdd').format(_selectedDate)}.pdf';

      // Get the Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();

      // Create the Dispatches/InFile directory if it doesn't exist
      final saveDir = Directory('${documentsDir.path}/Dispatches/InFile');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Default save path
      final defaultSavePath = '${saveDir.path}/$fileName';

      // Prompt user for save location
      String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save IN FILE Slip',
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
            'IN FILE Slip - ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
        'path': file.path,
        'date': _selectedDate,
        'dispatches': _filteredDispatches
            .map((dispatch) => {
                  'referenceNumber': dispatch.referenceNumber,
                  'originatorsNumber': dispatch.originatorsNumber,
                  'priority': dispatch.priority,
                  'addrFrom': dispatch.senderUnit,
                  'addrTo': dispatch.addrTo,
                  'thi': dispatch.timeHandedIn != null
                      ? DateFormat('HH:mm').format(dispatch.timeHandedIn!)
                      : '',
                  'tcl': dispatch.timeCleared != null
                      ? DateFormat('HH:mm').format(dispatch.timeCleared!)
                      : '',
                })
            .toList(),
      };

      setState(() {
        _savedSlips.add(newSlip);
        _isGenerating = false;
      });

      // Show success message with option to view the PDF
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('IN FILE slip saved to: ${file.path}'),
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
      debugPrint('Error generating IN FILE slip: $e');
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating IN FILE slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // View a PDF file
  Future<void> _viewPdf(String filePath) async {
    try {
      // First check if the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File not found: $filePath'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if the file has content
      if (await file.length() == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF file is empty'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Normalize file path for Windows
      String normalizedPath = filePath;
      if (Platform.isWindows) {
        normalizedPath = normalizedPath.replaceAll('/', '\\');
      }

      // Try to open the file
      final result = await OpenFile.open(normalizedPath);
      if (result.type != ResultType.done && mounted) {
        // If opening fails, show detailed error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${result.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _viewPdf(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error with stack trace for debugging
        debugPrint('Error viewing PDF: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtil.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IN FILE Slip Generator'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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

                                    // IN FILE Slip Preview
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
                                          child: _buildInFileSlipPreview(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              // Side-by-side layout for larger screens
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column - IN FILE Slip Preview
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Filter Bar
                                          _buildFilterBar(),
                                          const SizedBox(height: 16),

                                          // IN FILE Slip Preview
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
                                                    _buildInFileSlipPreview(),
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
                                    'Saved IN FILE Slips',
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
                                          'No saved IN FILE slips yet',
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

        // Date Selection
        const Text(
          'Slip Date:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null && pickedDate != _selectedDate) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Page Size Settings
        const Text(
          'Page Size:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PdfPageFormat>(
              value: _pageFormat,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _pageFormat = value;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: PdfPageFormat.a4,
                  child: const Row(
                    children: [
                      Icon(Icons.description,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('A4 (210 × 297 mm)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PdfPageFormat.letter,
                  child: const Row(
                    children: [
                      Icon(Icons.description,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Letter (215.9 × 279.4 mm)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PdfPageFormat.legal,
                  child: const Row(
                    children: [
                      Icon(Icons.description,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Legal (215.9 × 355.6 mm)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Page Orientation
        const Text(
          'Orientation:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _orientation,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _orientation = value;
                    // Update page format based on orientation
                    if (value == 'Landscape') {
                      _pageFormat = _pageFormat.landscape;
                    } else {
                      _pageFormat = _pageFormat.portrait;
                    }
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'Portrait',
                  child: Row(
                    children: [
                      Icon(Icons.stay_current_portrait,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Portrait'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Landscape',
                  child: Row(
                    children: [
                      Icon(Icons.stay_current_landscape,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Landscape'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Margins
        const Text(
          'Margins:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: _marginSize,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _marginSize = value;
                  });
                }
              },
              items: [
                for (double margin in [20.0, 30.0, 40.0, 50.0, 60.0])
                  DropdownMenuItem(
                    value: margin,
                    child: Row(
                      children: [
                        const Icon(Icons.margin,
                            size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text('$margin pixels on all sides'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Font Settings
        const Text(
          'Font:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _fontFamily,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _fontFamily = value;
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'Courier',
                  child: Row(
                    children: [
                      Icon(Icons.font_download,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Courier (Monospace)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Helvetica',
                  child: Row(
                    children: [
                      Icon(Icons.font_download,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Helvetica (Sans-serif)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Times',
                  child: Row(
                    children: [
                      Icon(Icons.font_download,
                          size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Times (Serif)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Font Size
        const Text(
          'Font Size:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.format_size,
                  size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 8.0,
                  max: 14.0,
                  divisions: 6,
                  label: _fontSize.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
              ),
              Text(_fontSize.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Generate Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateInFileSlip,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
                _isGenerating ? 'Generating...' : 'Generate & Save A4 PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                          : 'Date Range',
                      style: TextStyle(
                        color: _startDate != null && _endDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Priority Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedPriority,
                hint: const Text('Priority'),
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                  _applyFilters();
                },
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  ...['IMM', 'FLASH', 'PRIORITY', 'ROUTINE'].map((priority) {
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Clear Filters Button
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Filters',
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _selectedPriority = null;
                _selectedFromUnit = null;
                _selectedToUnit = null;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInFileSlipPreview() {
    return RepaintBoundary(
      key: _previewKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              'IN MESSAGE OF: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
              style: TextStyle(
                fontFamily: _fontFamily == 'Courier'
                    ? 'monospace'
                    : _fontFamily.toLowerCase(),
                fontSize: _headerFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Table
          Table(
            border:
                TableBorder.all(color: Colors.black, width: _tableBorderWidth),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1), // S/N
              1: FlexColumnWidth(1.5), // P/ACTION
              2: FlexColumnWidth(2.5), // ORIGINATOR'S NUMBER
              3: FlexColumnWidth(2), // ADD FROM
              4: FlexColumnWidth(2), // ADD TO
              5: FlexColumnWidth(1.5), // THI
              6: FlexColumnWidth(1.5), // TCL
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  _buildTableCellPreview('S/N', isHeader: true),
                  _buildTableCellPreview('P/ACTION', isHeader: true),
                  _buildTableCellPreview('ORIGINATOR\'S NUMBER',
                      isHeader: true),
                  _buildTableCellPreview('ADD FROM', isHeader: true),
                  _buildTableCellPreview('ADD TO', isHeader: true),
                  _buildTableCellPreview('THI', isHeader: true),
                  _buildTableCellPreview('TCL', isHeader: true),
                ],
              ),

              // Data rows - generate 50 rows if needed
              ..._generatePreviewTableRows(),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build a table cell for the preview
  Widget _buildTableCellPreview(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _fontFamily == 'Courier'
              ? 'monospace'
              : _fontFamily.toLowerCase(),
          fontSize: _fontSize,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
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
            _buildTableCellPreview(dispatch.priority),
            _buildTableCellPreview(dispatch.originatorsNumber),
            _buildTableCellPreview(dispatch.senderUnit),
            _buildTableCellPreview(dispatch.addrTo),
            _buildTableCellPreview(dispatch.timeHandedIn != null
                ? DateFormat('HH:mm').format(dispatch.timeHandedIn!)
                : ''),
            _buildTableCellPreview(dispatch.timeCleared != null
                ? DateFormat('HH:mm').format(dispatch.timeCleared!)
                : ''),
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
              _buildTableCellPreview(''),
              _buildTableCellPreview(''),
            ],
          ),
        );
      }
    }

    return rows;
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
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _viewPdf(slip['path']),
                    tooltip: 'View',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      // Share functionality would go here
                    },
                    tooltip: 'Share',
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
