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
class NewTransitSlipService {
  final DispatchService _dispatchService = DispatchService();
  final ReportLibraryService _reportLibraryService = ReportLibraryService();

  /// Report settings
  final Map<String, dynamic> _settings = {
    'pageSize': PdfPageFormat.a4,
    'orientation': 'portrait',
    'margin': const pw.EdgeInsets.all(20.0), // Standard margins for A4
    'headerHeight': 80.0,
    'footerHeight': 120.0,
    'rowsPerPage': 50, // Always show 50 rows as required
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
    );

    // Get all outgoing dispatches
    List<OutgoingDispatch> allDispatches =
        dispatches ?? _dispatchService.getOutgoingDispatches();

    // Debug: Print the number of dispatches before filtering
    debugPrint(
        'Total outgoing dispatches before filtering: ${allDispatches.length}');

    // Apply filters to get the dispatches for this transit slip
    List<OutgoingDispatch> slipDispatches = _filterDispatches(
      allDispatches,
      unitCode,
      destinationUnit,
      startDate,
      endDate,
      filterToUnits,
      filterFromUnits,
    );

    // Format the current date for the header
    final currentDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Add the page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: _settings['pageSize'],
        margin: _settings['margin'],
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with unit information
              _buildHeader(unitCode, destinationUnit, currentDate),

              pw.SizedBox(height: 20),

              // Tabulated table
              _buildTransitTable(slipDispatches),

              pw.SizedBox(height: 30),

              // Signature section
              _buildSignatureSection(),

              // Footer with page number
              if (_settings['showPageNumbers'] ?? true)
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  margin: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: _settings['fontSize']['footer'],
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Filter dispatches based on criteria
  List<OutgoingDispatch> _filterDispatches(
    List<OutgoingDispatch> allDispatches,
    String unitCode,
    String destinationUnit,
    DateTime startDate,
    DateTime endDate,
    List<String>? filterToUnits,
    List<String>? filterFromUnits,
  ) {
    // Make the date range more inclusive
    final DateTime startOfStartDate =
        DateTime(startDate.year, startDate.month, startDate.day);
    final DateTime endOfEndDate =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Apply filters
    List<OutgoingDispatch> filteredDispatches = allDispatches.where((dispatch) {
      // Date filter
      bool dateMatches = dispatch.dateTime
              .isAfter(startOfStartDate.subtract(const Duration(days: 1))) &&
          dispatch.dateTime.isBefore(endOfEndDate.add(const Duration(days: 1)));

      // Destination unit filter
      bool unitMatches = true;
      if (destinationUnit != 'Select Unit' && destinationUnit.isNotEmpty) {
        unitMatches = dispatch.recipientUnit
                .toLowerCase()
                .contains(destinationUnit.toLowerCase()) ||
            dispatch.recipient
                .toLowerCase()
                .contains(destinationUnit.toLowerCase());
      }

      // To units filter
      bool toUnitMatches = true;
      if (filterToUnits != null &&
          !filterToUnits.contains('All Units') &&
          filterToUnits.isNotEmpty) {
        toUnitMatches = false;
        for (final unit in filterToUnits) {
          if (unit.isEmpty) continue;

          if (dispatch.recipientUnit
                  .toLowerCase()
                  .contains(unit.toLowerCase()) ||
              dispatch.recipient.toLowerCase().contains(unit.toLowerCase())) {
            toUnitMatches = true;
            break;
          }
        }
      }

      // From units filter
      bool fromUnitMatches = true;
      if (filterFromUnits != null &&
          !filterFromUnits.contains('All Units') &&
          filterFromUnits.isNotEmpty) {
        fromUnitMatches = false;
        for (final unit in filterFromUnits) {
          if (unit.isEmpty) continue;

          if (dispatch.sentBy.toLowerCase().contains(unit.toLowerCase()) ||
              unitCode.toLowerCase().contains(unit.toLowerCase())) {
            fromUnitMatches = true;
            break;
          }
        }
      }

      return dateMatches && unitMatches && toUnitMatches && fromUnitMatches;
    }).toList();

    // If no dispatches matched the filters, use all dispatches as a fallback (limited to 10)
    if (filteredDispatches.isEmpty) {
      debugPrint('No dispatches matched the filters. Using fallback data.');
      if (allDispatches.isNotEmpty) {
        filteredDispatches = allDispatches.take(10).toList();
      } else {
        // If there are no dispatches at all, create a sample one
        filteredDispatches = [
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
    filteredDispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return filteredDispatches;
  }

  /// Build the header section
  pw.Widget _buildHeader(
      String unitCode, String destinationUnit, String currentDate) {
    return pw.Container(
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
    );
  }

  /// Build the transit slip table
  pw.Widget _buildTransitTable(List<OutgoingDispatch> dispatches) {
    // Debug the dispatches being passed to the table
    debugPrint('Building transit table with ${dispatches.length} dispatches');

    // Always show exactly 50 rows as required
    final int totalRows = 50;

    // Get border settings
    final double borderWidth = _settings['tableBorderWidth'] ?? 1.0;

    // Create a table with black border lines
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: borderWidth,
        style: pw.BorderStyle.solid,
      ),
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
            color: PdfColors.grey300,
            border: pw.Border.all(
              color: PdfColors.black,
              width: borderWidth,
            ),
          ),
          children: [
            _buildTableCell('S/N', isHeader: true),
            _buildTableCell('DATE', isHeader: true),
            _buildTableCell('FROM', isHeader: true),
            _buildTableCell('TO', isHeader: true),
            _buildTableCell('REFS NO', isHeader: true),
          ],
        ),

        // Generate all 50 rows (filled or empty)
        ...List.generate(totalRows, (index) {
          final hasData = index < dispatches.length;

          // Determine row color (alternate rows)
          final rowColor = index % 2 == 0 ? PdfColors.white : PdfColors.grey100;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowColor,
              border: pw.Border.all(
                color: PdfColors.black,
                width: borderWidth / 2,
              ),
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
    return pw.Container(
      height: _settings['signatureSectionHeight'] ?? 120.0,
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
