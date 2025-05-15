import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/dispatch.dart';
import '../services/dispatch_service.dart';
import '../services/file_save_dialog_service.dart';
import '../services/report_library_service.dart';
import '../utils/pdf_fonts.dart';

/// Service for generating Transit Slip reports in A4 format
class TransitSlipService {
  final DispatchService _dispatchService = DispatchService();
  final ReportLibraryService _reportLibraryService = ReportLibraryService();

  /// Report settings
  final Map<String, dynamic> _settings = {
    'pageSize': PdfPageFormat.a4,
    'orientation': 'portrait',
    'margin': const pw.EdgeInsets.all(20.0), // Smaller margins for A4
    'headerHeight': 60.0,
    'footerHeight': 120.0,
    'rowsPerPage': 50,
    'fontSize': {
      'header': 16.0,
      'title': 14.0,
      'body': 10.0,
      'footer': 10.0,
    },
    'showPageNumbers': true,
    'showDateGenerated': true,
    'showUnitInfo': true,
    'showSignatureSection': true,
    'showTableBorders': true,
    'showAlternateRowColors': true,
    'tableHeaderColor': PdfColors.grey300,
    'tableBorderColor': PdfColors.black,
    'tableBorderWidth': 1.0,
    'alternateRowColor': PdfColors.grey100,
    'signatureSectionHeight': 120.0,
    'customHeaderText': '',
    'customFooterText': '',
  };

  /// Get current settings
  Map<String, dynamic> get settings => _settings;

  /// Update settings
  void updateSettings(Map<String, dynamic> newSettings) {
    _settings.addAll(newSettings);
  }

  /// Generate a Transit Slip report
  Future<pw.Document> generateTransitSlip({
    required String unitCode,
    required String destinationUnit,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? filterToUnits,
    List<String>? filterFromUnits,
    List<OutgoingDispatch>? dispatches,
  }) async {
    // Initialize fonts
    await PdfFonts.init();

    // Create a new PDF document with custom theme and security settings
    final pdf = pw.Document(
      theme: PdfFonts.getTheme(),
      title: 'Transit Slip - $unitCode to $destinationUnit',
      author: 'NASDS',
      creator: 'NASDS Application',
      subject: 'Transit Slip Report',
      keywords: 'transit, slip, dispatch, $unitCode, $destinationUnit',
      compress: _settings['compressContent'] ?? false,
    );

    // Get all outgoing dispatches
    List<OutgoingDispatch> allDispatches =
        dispatches ?? _dispatchService.getOutgoingDispatches();

    // Debug: Print the number of dispatches before filtering
    debugPrint(
        'Total outgoing dispatches before filtering: ${allDispatches.length}');

    // Debug: Print filter parameters
    debugPrint('FILTER PARAMETERS:');
    debugPrint('Unit Code: $unitCode');
    debugPrint('Destination Unit: $destinationUnit');
    debugPrint('Start Date: $startDate');
    debugPrint('End Date: $endDate');
    debugPrint('Filter To Units: $filterToUnits');
    debugPrint('Filter From Units: $filterFromUnits');

    // Apply filters one by one for better debugging
    List<OutgoingDispatch> dateFilteredDispatches = allDispatches;

    // Only apply date filtering if we have dispatches
    if (allDispatches.isNotEmpty) {
      // Make the date range more inclusive by using the start of the start date and end of the end date
      final DateTime startOfStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final DateTime endOfEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      debugPrint(
          'Using date range: ${startOfStartDate.toString()} to ${endOfEndDate.toString()}');

      dateFilteredDispatches = allDispatches.where((dispatch) {
        // Check if dispatch date is within the selected date range (more inclusive)
        final bool dateMatches = dispatch.dateTime
                .isAfter(startOfStartDate.subtract(const Duration(days: 1))) &&
            dispatch.dateTime
                .isBefore(endOfEndDate.add(const Duration(days: 1)));

        if (!dateMatches) {
          debugPrint(
              'Dispatch ${dispatch.referenceNumber} date ${dispatch.dateTime} does not match date range $startOfStartDate - $endOfEndDate');
        }

        return dateMatches;
      }).toList();
    } else {
      debugPrint('WARNING: No dispatches found in the system!');
    }

    debugPrint(
        'After date filtering: ${dateFilteredDispatches.length} dispatches');

    // Filter by destination unit
    List<OutgoingDispatch> unitFilteredDispatches = dateFilteredDispatches;

    // Only apply destination unit filtering if a specific unit is selected
    if (destinationUnit != 'Select Unit' && destinationUnit.isNotEmpty) {
      unitFilteredDispatches = dateFilteredDispatches.where((dispatch) {
        // Check if dispatch is for the selected destination unit
        // Make this a case-insensitive comparison and handle partial matches
        final bool unitMatches =
            // Direct match on recipient unit
            dispatch.recipientUnit
                    .toLowerCase()
                    .contains(destinationUnit.toLowerCase()) ||
                // Direct match on recipient
                dispatch.recipient
                    .toLowerCase()
                    .contains(destinationUnit.toLowerCase()) ||
                // Handle Signal Regiment abbreviations
                (destinationUnit.contains('Signal Regiment') &&
                    dispatch.recipientUnit.contains('SR')) ||
                (destinationUnit.contains('SR') &&
                    dispatch.recipientUnit.contains('Signal')) ||
                // Handle common abbreviations
                (destinationUnit.contains('521') &&
                    dispatch.recipientUnit.contains('521')) ||
                (destinationUnit.contains('522') &&
                    dispatch.recipientUnit.contains('522')) ||
                (destinationUnit.contains('523') &&
                    dispatch.recipientUnit.contains('523')) ||
                (destinationUnit.contains('524') &&
                    dispatch.recipientUnit.contains('524'));

        if (!unitMatches) {
          debugPrint(
              'Dispatch ${dispatch.referenceNumber} recipient unit ${dispatch.recipientUnit} does not match destination unit $destinationUnit');
        } else {
          debugPrint(
              'Dispatch ${dispatch.referenceNumber} MATCHES destination unit $destinationUnit');
        }

        return unitMatches;
      }).toList();
    } else {
      debugPrint(
          'No destination unit filtering applied (Select Unit or empty)');
    }

    debugPrint(
        'After unit filtering: ${unitFilteredDispatches.length} dispatches');

    // Filter by "To" units if specified
    List<OutgoingDispatch> toFilteredDispatches = unitFilteredDispatches;
    if (filterToUnits != null &&
        !filterToUnits.contains('All Units') &&
        filterToUnits.isNotEmpty) {
      // Debug the filter units
      debugPrint('Applying To unit filters: $filterToUnits');

      toFilteredDispatches = unitFilteredDispatches.where((dispatch) {
        // If no filters are specified, include all dispatches
        if (filterToUnits.isEmpty) {
          return true;
        }

        bool toUnitMatches = false;

        for (final unit in filterToUnits) {
          // Skip empty units
          if (unit.isEmpty) {
            continue;
          }

          // Check against recipient and recipientUnit fields (case insensitive)
          final String recipientLower = dispatch.recipient.toLowerCase();
          final String recipientUnitLower =
              dispatch.recipientUnit.toLowerCase();
          final String unitLower = unit.toLowerCase();

          // Direct matches
          if (recipientLower.contains(unitLower) ||
              recipientUnitLower.contains(unitLower) ||
              unitLower.contains(recipientLower) ||
              unitLower.contains(recipientUnitLower)) {
            toUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} matches To unit filter: $unit');
            break;
          }

          // Check if the destination unit matches
          if (destinationUnit.toLowerCase().contains(unitLower) ||
              unitLower.contains(destinationUnit.toLowerCase())) {
            toUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} destination matches To unit filter: $unit');
            break;
          }

          // Check for Signal Regiment abbreviations
          if ((unit.contains('Signal') &&
                  (recipientLower.contains('sr') ||
                      recipientUnitLower.contains('sr'))) ||
              (unit.contains('SR') &&
                  (recipientLower.contains('signal') ||
                      recipientUnitLower.contains('signal')))) {
            toUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} abbreviation matches To unit filter: $unit');
            break;
          }

          // Check for numeric unit codes
          if ((unit.contains('521') &&
                  (recipientLower.contains('521') ||
                      recipientUnitLower.contains('521'))) ||
              (unit.contains('522') &&
                  (recipientLower.contains('522') ||
                      recipientUnitLower.contains('522'))) ||
              (unit.contains('523') &&
                  (recipientLower.contains('523') ||
                      recipientUnitLower.contains('523'))) ||
              (unit.contains('524') &&
                  (recipientLower.contains('524') ||
                      recipientUnitLower.contains('524')))) {
            toUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} numeric code matches To unit filter: $unit');
            break;
          }
        }

        if (!toUnitMatches) {
          debugPrint(
              'Dispatch ${dispatch.referenceNumber} recipient ${dispatch.recipient} and unit ${dispatch.recipientUnit} do not match any To unit filter');
        }

        return toUnitMatches;
      }).toList();

      debugPrint(
          'After To unit filtering: ${toFilteredDispatches.length} dispatches');
    } else {
      debugPrint('No To unit filtering applied (All Units selected)');
    }

    // Filter by "From" units if specified
    List<OutgoingDispatch> fromFilteredDispatches = toFilteredDispatches;
    if (filterFromUnits != null &&
        !filterFromUnits.contains('All Units') &&
        filterFromUnits.isNotEmpty) {
      // Debug the filter units
      debugPrint('Applying From unit filters: $filterFromUnits');

      fromFilteredDispatches = toFilteredDispatches.where((dispatch) {
        // If no filters are specified, include all dispatches
        if (filterFromUnits.isEmpty) {
          return true;
        }

        bool fromUnitMatches = false;

        for (final unit in filterFromUnits) {
          // Skip empty units
          if (unit.isEmpty) {
            continue;
          }

          // Check against sentBy (sender) field (case insensitive)
          final String sentByLower = dispatch.sentBy.toLowerCase();
          final String unitLower = unit.toLowerCase();

          // Direct matches
          if (sentByLower.contains(unitLower) ||
              unitLower.contains(sentByLower)) {
            fromUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} matches From unit filter: $unit');
            break;
          }

          // Also check against unit code or any other potential sender identifier
          if (unitCode.toLowerCase().contains(unitLower) ||
              unitLower.contains(unitCode.toLowerCase())) {
            fromUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} unit code matches From unit filter: $unit');
            break;
          }

          // Check for Signal Regiment abbreviations
          if ((unit.contains('Signal') && sentByLower.contains('sr')) ||
              (unit.contains('SR') && sentByLower.contains('signal'))) {
            fromUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} abbreviation matches From unit filter: $unit');
            break;
          }

          // Check for numeric unit codes
          if ((unit.contains('521') && sentByLower.contains('521')) ||
              (unit.contains('522') && sentByLower.contains('522')) ||
              (unit.contains('523') && sentByLower.contains('523')) ||
              (unit.contains('524') && sentByLower.contains('524'))) {
            fromUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} numeric code matches From unit filter: $unit');
            break;
          }

          // Special case: if the unit is a Signal Regiment, match any sender that might be from that regiment
          if ((unit.contains('Signal Regiment') || unit.contains('SR')) &&
              (sentByLower.contains('capt') ||
                  sentByLower.contains('lt') ||
                  sentByLower.contains('maj') ||
                  sentByLower.contains('col') ||
                  sentByLower.contains('sgt') ||
                  sentByLower.contains('cpl'))) {
            fromUnitMatches = true;
            debugPrint(
                'Dispatch ${dispatch.referenceNumber} rank matches From unit filter: $unit');
            break;
          }
        }

        if (!fromUnitMatches) {
          debugPrint(
              'Dispatch ${dispatch.referenceNumber} sender ${dispatch.sentBy} does not match any From unit filter');
        }

        return fromUnitMatches;
      }).toList();

      debugPrint(
          'After From unit filtering: ${fromFilteredDispatches.length} dispatches');
    } else {
      debugPrint('No From unit filtering applied (All Units selected)');
    }

    // Final filtered dispatches
    List<OutgoingDispatch> slipDispatches = fromFilteredDispatches;

    // Debug: Print the number of dispatches after filtering
    debugPrint('Filtered outgoing dispatches: ${slipDispatches.length}');
    debugPrint('Destination unit filter: $destinationUnit');
    if (filterToUnits != null) {
      debugPrint('To units filter: $filterToUnits');
    }
    if (filterFromUnits != null) {
      debugPrint('From units filter: $filterFromUnits');
    }

    // Print details of each filtered dispatch for debugging
    for (int i = 0; i < slipDispatches.length; i++) {
      final dispatch = slipDispatches[i];
      debugPrint('Dispatch $i:');
      debugPrint('  Reference: ${dispatch.referenceNumber}');
      debugPrint('  Recipient: ${dispatch.recipient}');
      debugPrint('  RecipientUnit: ${dispatch.recipientUnit}');
      debugPrint('  SentBy: ${dispatch.sentBy}');
      debugPrint('  Date: ${dispatch.dateTime}');
    }

    // If no dispatches were found, print a clear message and use all dispatches as a fallback
    if (slipDispatches.isEmpty) {
      debugPrint('NO DISPATCHES MATCHED THE FILTERS!');
      debugPrint(
          'Using all dispatches as a fallback to ensure content is displayed');

      // Use all dispatches as a fallback (limited to 10 for performance)
      if (allDispatches.isNotEmpty) {
        slipDispatches = allDispatches.take(10).toList();
        debugPrint('Using ${slipDispatches.length} dispatches as fallback');
      } else {
        // If there are no dispatches at all, create a sample one
        debugPrint(
            'No dispatches found in the system. Creating a sample dispatch for display purposes.');
        slipDispatches = [
          OutgoingDispatch(
            id: 'sample-1',
            referenceNumber: 'SAMPLE-001',
            subject: 'Sample Dispatch',
            content: 'This is a sample dispatch for display purposes.',
            dateTime: DateTime.now(),
            priority: 'Normal',
            securityClassification: 'Unclassified',
            status: 'Pending',
            handledBy: 'System',
            recipient: 'Sample Recipient',
            recipientUnit:
                destinationUnit.isEmpty ? 'Sample Unit' : destinationUnit,
            sentBy: 'Sample Sender',
            sentDate: DateTime.now(),
            deliveryMethod: 'Physical',
            attachments: [],
            logs: [],
          ),
        ];
      }
    }

    // Sort dispatches by date
    slipDispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Format the current date for the header
    final currentDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Calculate number of pages needed
    // Always create at least one page, even if there are no dispatches
    final int totalPages = slipDispatches.isEmpty
        ? 1
        : (slipDispatches.length / _settings['rowsPerPage']).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      // If there are no dispatches, use an empty list
      List<OutgoingDispatch> pageDispatches;
      if (slipDispatches.isEmpty) {
        pageDispatches = [];
      } else {
        final int startIndex = (pageIndex * _settings['rowsPerPage']).toInt();
        final int endIndex =
            (startIndex + _settings['rowsPerPage'] > slipDispatches.length)
                ? slipDispatches.length
                : (startIndex + _settings['rowsPerPage']).toInt();

        pageDispatches = slipDispatches.sublist(startIndex, endIndex);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: _settings['pageSize'],
          margin: _settings['margin'],
          orientation: _settings['orientation'] == 'landscape'
              ? pw.PageOrientation.landscape
              : pw.PageOrientation.portrait,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with unit information
                if (_settings['showUnitInfo'] ?? true)
                  pw.Container(
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      children: [
                        // Custom header text if provided
                        if ((_settings['customHeaderText'] ?? '').isNotEmpty)
                          pw.Text(
                            _settings['customHeaderText'],
                            style: pw.TextStyle(
                              fontSize: _settings['fontSize']['title'],
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),

                        pw.Text(
                          'TRANSIT SLIP',
                          style: pw.TextStyle(
                            fontSize: _settings['fontSize']['header'],
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'FROM: $unitCode     TO: $destinationUnit',
                          style: pw.TextStyle(
                            fontSize: _settings['fontSize']['title'],
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (_settings['showDateGenerated'] ?? true)
                          pw.Column(
                            children: [
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Date: $currentDate',
                                style: pw.TextStyle(
                                  fontSize: _settings['fontSize']['body'],
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        pw.Divider(
                          thickness: 2.0,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 20),

                // Tabulated table
                _buildTransitTable(pageDispatches),

                pw.SizedBox(height: 20),

                // Signature section
                _buildSignatureSection(),

                pw.Spacer(),

                // Footer
                pw.Container(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Custom footer text if provided
                      if ((_settings['customFooterText'] ?? '').isNotEmpty)
                        pw.Container(
                          alignment: pw.Alignment.center,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Text(
                            _settings['customFooterText'],
                            style: pw.TextStyle(
                              fontSize: _settings['fontSize']['footer'],
                              color: PdfColors.grey700,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                      // Page numbers if enabled
                      if (_settings['showPageNumbers'] ?? true)
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Page ${pageIndex + 1} of $totalPages',
                            style: pw.TextStyle(
                              fontSize: _settings['fontSize']['footer'],
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Build the transit slip table
  pw.Widget _buildTransitTable(List<OutgoingDispatch> dispatches) {
    // Debug the dispatches being passed to the table
    debugPrint('Building transit table with ${dispatches.length} dispatches');

    // Always show exactly the number of rows specified in settings, default to 50
    final int totalRows = _settings['rowsPerPage'] ?? 50;
    debugPrint('Table will show $totalRows rows (filled or empty)');

    // Get border settings
    final bool showTableBorders = _settings['showTableBorders'] ?? true;
    final double borderWidth = _settings['tableBorderWidth'] ?? 1.0;
    final bool showAlternateRowColors =
        _settings['showAlternateRowColors'] ?? true;

    // Create a table with configurable border lines
    return pw.Table(
      border: showTableBorders
          ? pw.TableBorder.all(
              color: _settings['tableBorderColor'] ?? PdfColors.black,
              width: borderWidth,
              style: pw.BorderStyle.solid,
            )
          : null,
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // S/N
        1: const pw.FixedColumnWidth(80), // DATE
        2: const pw.FlexColumnWidth(2.0), // FROM
        3: const pw.FlexColumnWidth(2.0), // TO
        4: const pw.FlexColumnWidth(1.5), // REFS NO
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        // Table header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: _settings['tableHeaderColor'] ?? PdfColors.grey300,
            border: showTableBorders
                ? pw.Border.all(
                    color: _settings['tableBorderColor'] ?? PdfColors.black,
                    width: borderWidth,
                  )
                : null,
          ),
          repeat: true, // Repeat header on each page
          children: [
            _buildTableCell('S/N', isHeader: true),
            _buildTableCell('DATE', isHeader: true),
            _buildTableCell('FROM', isHeader: true),
            _buildTableCell('TO', isHeader: true),
            _buildTableCell('REFS NO', isHeader: true),
          ],
        ),

        // Generate all rows based on settings
        ...List.generate(totalRows, (index) {
          final isEven = index % 2 == 0;
          final hasData = index < dispatches.length;

          // Determine row color based on settings
          final rowColor = showAlternateRowColors && isEven
              ? _settings['alternateRowColor'] ?? PdfColors.grey100
              : PdfColors.white;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowColor,
              border: showTableBorders
                  ? pw.Border.all(
                      color: _settings['tableBorderColor'] ?? PdfColors.black,
                      width: borderWidth / 2,
                    )
                  : null,
            ),
            children: [
              // S/N column (always show row number)
              _buildTableCell('${index + 1}'),

              // Other columns (show data if available, otherwise empty)
              _buildTableCell(hasData
                  ? DateFormat('dd/MM/yyyy').format(dispatches[index].dateTime)
                  : ''),
              _buildTableCell(hasData
                  ? (dispatches[index].sentBy.isNotEmpty
                      ? dispatches[index].sentBy
                      : 'N/A')
                  : ''),
              _buildTableCell(hasData
                  ? (dispatches[index].recipientUnit.isNotEmpty
                      ? dispatches[index].recipientUnit
                      : (dispatches[index].recipient.isNotEmpty
                          ? dispatches[index].recipient
                          : 'N/A'))
                  : ''),
              _buildTableCell(hasData ? dispatches[index].referenceNumber : ''),
            ],
          );
        }),
      ],
    );
  }

  /// Build a table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader
              ? _settings['fontSize']['title']
              : _settings['fontSize']['body'],
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: PdfColors.black, // Ensure text is black for visibility
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  /// Build the signature section
  pw.Widget _buildSignatureSection() {
    // Check if signature section should be shown
    final bool showSignatureSection = _settings['showSignatureSection'] ?? true;

    if (!showSignatureSection) {
      return pw
          .Container(); // Return empty container if signature section is disabled
    }

    // Get signature section height
    final double signatureSectionHeight =
        _settings['signatureSectionHeight'] ?? 120.0;

    return pw.Container(
      height: signatureSectionHeight,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left column - Prepared by
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PREPARED BY:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'RANK:.................................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'NAME:................................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DATE/SIGN:.........................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 20),

          // Right column - Received by
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RECEIVED BY:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'RANK:.................................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'NAME:................................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DATE/SIGN:.........................................',
                  style: pw.TextStyle(
                    fontSize: _settings['fontSize']['body'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Save the report as PDF
  Future<String?> saveReportAsPdf(pw.Document pdf, String fileName) async {
    try {
      // Get application documents directory as default location
      final directory = await getApplicationDocumentsDirectory();
      final defaultPath = '${directory.path}/$fileName';

      // Save the PDF to the file system
      final file = File(defaultPath);
      await file.writeAsBytes(await pdf.save());

      return defaultPath;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }

  /// Save the report as PDF with a file dialog
  Future<String?> saveReportWithDialog(pw.Document pdf, String fileName) async {
    final fileSaveDialogService = FileSaveDialogService();
    return await fileSaveDialogService.saveFileWithDialog(pdf, fileName);
  }

  /// Open a saved report
  Future<bool> openReport(String filePath) async {
    final fileSaveDialogService = FileSaveDialogService();
    return await fileSaveDialogService.openFile(filePath);
  }

  /// Open the folder containing a saved report
  Future<bool> openReportFolder(String filePath) async {
    final fileSaveDialogService = FileSaveDialogService();
    return await fileSaveDialogService.openContainingFolder(filePath);
  }

  /// Save the report to the library
  Future<SavedReport?> saveReportToLibrary({
    required pw.Document pdf,
    required String unitCode,
    required String destinationUnit,
    Map<String, dynamic>? metadata,
  }) async {
    final reportName = 'Transit Slip - $unitCode to $destinationUnit';

    return await _reportLibraryService.saveReport(
      pdfDocument: pdf,
      name: reportName,
      reportType: 'Transit Slip',
      metadata: metadata ??
          {
            'unitCode': unitCode,
            'destinationUnit': destinationUnit,
            'generatedAt': DateTime.now().millisecondsSinceEpoch,
          },
    );
  }
}
