import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/dispatch.dart';
import '../services/dispatch_service.dart';
import '../services/file_save_dialog_service.dart';
import '../utils/pdf_fonts.dart';

/// Service for generating Transit Slip reports in A4 format
class TransitSlipService {
  final DispatchService _dispatchService = DispatchService();

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

    // Apply filters one by one for better debugging
    List<OutgoingDispatch> slipDispatches = allDispatches.where((dispatch) {
      // Check if dispatch date is within the selected date range
      final bool dateMatches = dispatch.dateTime.isAfter(startDate) &&
          dispatch.dateTime.isBefore(endDate.add(const Duration(days: 1)));

      if (!dateMatches) {
        return false;
      }

      // Check if dispatch is for the selected destination unit
      // Make this a case-insensitive comparison and handle partial matches
      final bool unitMatches = destinationUnit == 'Select Unit' ||
          destinationUnit.isEmpty ||
          dispatch.recipientUnit
              .toLowerCase()
              .contains(destinationUnit.toLowerCase()) ||
          (destinationUnit.contains('Signal Regiment') &&
              dispatch.recipientUnit.contains('SR'));

      if (!unitMatches) {
        return false;
      }

      // Check if dispatch matches the selected "To" units filter
      bool toUnitMatches = true;
      if (filterToUnits != null && !filterToUnits.contains('All Units')) {
        toUnitMatches = false;
        for (final unit in filterToUnits) {
          if (dispatch.recipient.toLowerCase().contains(unit.toLowerCase()) ||
              dispatch.recipientUnit
                  .toLowerCase()
                  .contains(unit.toLowerCase())) {
            toUnitMatches = true;
            break;
          }
        }
      }

      if (!toUnitMatches) {
        return false;
      }

      // Check if dispatch matches the selected "From" units filter
      bool fromUnitMatches = true;
      if (filterFromUnits != null && !filterFromUnits.contains('All Units')) {
        fromUnitMatches = false;
        for (final unit in filterFromUnits) {
          if (dispatch.sender.toLowerCase().contains(unit.toLowerCase())) {
            fromUnitMatches = true;
            break;
          }
        }
      }

      return fromUnitMatches;
    }).toList();

    // Debug: Print the number of dispatches after filtering
    debugPrint('Filtered outgoing dispatches: ${slipDispatches.length}');
    debugPrint('Destination unit filter: $destinationUnit');
    if (filterToUnits != null) {
      debugPrint('To units filter: $filterToUnits');
    }
    if (filterFromUnits != null) {
      debugPrint('From units filter: $filterFromUnits');
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
    // Always show exactly the number of rows specified in settings, default to 50
    final int totalRows = _settings['rowsPerPage'] ?? 50;

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
              _buildTableCell(hasData ? dispatches[index].sender : ''),
              _buildTableCell(hasData ? dispatches[index].recipient : ''),
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
}
