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

/// A very basic service focused solely on generating Transit Slip reports with visible black borders
class BasicTransitSlipGenerator {
  final DispatchService _dispatchService = DispatchService();
  final ReportLibraryService _reportLibraryService = ReportLibraryService();

  /// Generate a Transit Slip report
  Future<pw.Document> generateTransitSlip({
    required String unitCode,
    required String destinationUnit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Initialize fonts
    await PdfFonts.init();

    // Create a new PDF document
    final pdf = pw.Document(
      title: 'Transit Slip - $unitCode to $destinationUnit',
      author: 'NASDS',
      creator: 'NASDS Application',
      subject: 'Transit Slip Report',
      keywords: 'transit, slip, dispatch, $unitCode, $destinationUnit',
    );

    // Get all outgoing dispatches
    List<OutgoingDispatch> allDispatches =
        _dispatchService.getOutgoingDispatches();

    // Filter dispatches based on date range
    List<OutgoingDispatch> filteredDispatches = allDispatches.where((dispatch) {
      return dispatch.dateTime
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          dispatch.dateTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter by destination unit if specified
    if (destinationUnit != 'Select Unit' && destinationUnit.isNotEmpty) {
      filteredDispatches = filteredDispatches.where((dispatch) {
        return dispatch.recipientUnit
                .toLowerCase()
                .contains(destinationUnit.toLowerCase()) ||
            dispatch.recipient
                .toLowerCase()
                .contains(destinationUnit.toLowerCase());
      }).toList();
    }

    // Sort dispatches by date
    filteredDispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // If no dispatches matched the filters, create a sample one
    if (filteredDispatches.isEmpty) {
      debugPrint('No dispatches matched the filters. Creating sample data.');
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

    // Format the current date for the header
    final currentDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Add the page to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20.0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(unitCode, destinationUnit, currentDate),

              pw.SizedBox(height: 20),

              // Table with black borders
              _buildTableWithBorders(filteredDispatches),

              pw.SizedBox(height: 30),

              // Signature section
              _buildSignatureSection(),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Build the header section
  pw.Widget _buildHeader(
      String unitCode, String destinationUnit, String currentDate) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'TRANSIT SLIP',
            style: pw.TextStyle(
              fontSize: 16.0,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'FROM: $unitCode     TO: $destinationUnit',
            style: pw.TextStyle(
              fontSize: 14.0,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date: $currentDate',
            style: pw.TextStyle(
              fontSize: 10.0,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Divider(
            thickness: 2.0,
            color: PdfColors.black,
          ),
        ],
      ),
    );
  }

  /// Build a table with visible black borders
  pw.Widget _buildTableWithBorders(List<OutgoingDispatch> dispatches) {
    // Always show exactly 50 rows
    final int totalRows = 50;

    // Create a table with thick black border lines
    return pw.Table(
      // Main table border - thick black line
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 2.0, // Thicker border for the outer edge
        style: pw.BorderStyle.solid,
      ),
      // Define column widths
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // S/N
        1: const pw.FixedColumnWidth(80), // DATE
        2: const pw.FlexColumnWidth(2.0), // FROM
        3: const pw.FlexColumnWidth(2.0), // TO
        4: const pw.FlexColumnWidth(1.5), // REFS NO
      },
      // Cell alignment
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      // Table content
      children: [
        // Table header row with dark background
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildHeaderCell('S/N'),
            _buildHeaderCell('DATE'),
            _buildHeaderCell('FROM'),
            _buildHeaderCell('TO'),
            _buildHeaderCell('REFS NO'),
          ],
        ),

        // Generate all 50 rows (filled or empty)
        ...List.generate(totalRows, (index) {
          final hasData = index < dispatches.length;

          // Determine row color (alternate rows for better readability)
          final rowColor = index % 2 == 0 ? PdfColors.white : PdfColors.grey100;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowColor,
            ),
            children: [
              // S/N column (always show row number)
              _buildCell('${index + 1}'),

              // Other columns (show data if available, otherwise empty)
              _buildCell(hasData
                  ? DateFormat('dd/MM/yyyy').format(dispatches[index].dateTime)
                  : ''),
              _buildCell(hasData
                  ? (dispatches[index].sentBy.isNotEmpty
                      ? dispatches[index].sentBy
                      : 'N/A')
                  : ''),
              _buildCell(hasData
                  ? (dispatches[index].recipientUnit.isNotEmpty
                      ? dispatches[index].recipientUnit
                      : (dispatches[index].recipient.isNotEmpty
                          ? dispatches[index].recipient
                          : 'N/A'))
                  : ''),
              _buildCell(hasData ? dispatches[index].referenceNumber : ''),
            ],
          );
        }),
      ],
    );
  }

  /// Build a header cell with border
  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.0),
          right: pw.BorderSide(color: PdfColors.black, width: 1.0),
        ),
      ),
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12.0,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build a regular cell with border
  pw.Widget _buildCell(String text) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.0),
          right: pw.BorderSide(color: PdfColors.black, width: 1.0),
        ),
      ),
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 10.0,
          color: PdfColors.black,
        ),
      ),
    );
  }

  /// Build the signature section
  pw.Widget _buildSignatureSection() {
    return pw.Container(
      height: 120.0,
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
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'RANK:.................................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'NAME:................................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DATE/SIGN:.........................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
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
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'RANK:.................................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'NAME:................................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'DATE/SIGN:.........................................',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Save the report as PDF with a file dialog
  Future<String?> saveReportWithDialog(pw.Document pdf, String fileName) async {
    final fileSaveDialogService = FileSaveDialogService();
    return await fileSaveDialogService.saveFileWithDialog(pdf, fileName);
  }

  /// Save the report to the library
  Future<SavedReport?> saveReportToLibrary({
    required pw.Document pdfDocument,
    required String unitCode,
    required String destinationUnit,
  }) async {
    final reportName = 'Transit Slip - $unitCode to $destinationUnit';

    return await _reportLibraryService.saveReport(
      pdfDocument: pdfDocument,
      name: reportName,
      reportType: 'Transit Slip',
      metadata: {
        'unitCode': unitCode,
        'destinationUnit': destinationUnit,
        'generatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }
}
