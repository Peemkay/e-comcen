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

/// A simplified service focused solely on generating Transit Slip reports in A4 format
class TransitSlipGenerator {
  final DispatchService _dispatchService = DispatchService();
  final ReportLibraryService _reportLibraryService = ReportLibraryService();

  /// Generate a Transit Slip report
  Future<pw.Document> generateTransitSlip({
    required String unitCode,
    required String destinationUnit,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? filterToUnits,
    List<String>? filterFromUnits,
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

    // Debug: Print the number of dispatches
    debugPrint('Total outgoing dispatches: ${allDispatches.length}');

    // Filter dispatches based on date range
    List<OutgoingDispatch> dateFilteredDispatches =
        allDispatches.where((dispatch) {
      return dispatch.dateTime
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          dispatch.dateTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    debugPrint(
        'After date filtering: ${dateFilteredDispatches.length} dispatches');

    // Filter by destination unit if specified
    List<OutgoingDispatch> unitFilteredDispatches = dateFilteredDispatches;
    if (destinationUnit != 'Select Unit' && destinationUnit.isNotEmpty) {
      unitFilteredDispatches = dateFilteredDispatches.where((dispatch) {
        return dispatch.recipientUnit
                .toLowerCase()
                .contains(destinationUnit.toLowerCase()) ||
            dispatch.recipient
                .toLowerCase()
                .contains(destinationUnit.toLowerCase());
      }).toList();
    }

    debugPrint(
        'After unit filtering: ${unitFilteredDispatches.length} dispatches');

    // Filter by "To" units if specified
    List<OutgoingDispatch> toFilteredDispatches = unitFilteredDispatches;
    if (filterToUnits != null &&
        !filterToUnits.contains('All Units') &&
        filterToUnits.isNotEmpty) {
      toFilteredDispatches = unitFilteredDispatches.where((dispatch) {
        for (final unit in filterToUnits) {
          if (dispatch.recipientUnit
                  .toLowerCase()
                  .contains(unit.toLowerCase()) ||
              dispatch.recipient.toLowerCase().contains(unit.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    debugPrint(
        'After To unit filtering: ${toFilteredDispatches.length} dispatches');

    // Filter by "From" units if specified
    List<OutgoingDispatch> fromFilteredDispatches = toFilteredDispatches;
    if (filterFromUnits != null &&
        !filterFromUnits.contains('All Units') &&
        filterFromUnits.isNotEmpty) {
      fromFilteredDispatches = toFilteredDispatches.where((dispatch) {
        for (final unit in filterFromUnits) {
          if (dispatch.sentBy.toLowerCase().contains(unit.toLowerCase())) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    debugPrint(
        'After From unit filtering: ${fromFilteredDispatches.length} dispatches');

    // Final filtered dispatches
    List<OutgoingDispatch> slipDispatches = fromFilteredDispatches;

    // If no dispatches matched the filters, create a sample one
    if (slipDispatches.isEmpty) {
      debugPrint('No dispatches matched the filters. Creating sample data.');
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

    // Sort dispatches by date
    slipDispatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));

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

              // Table
              _buildTable(slipDispatches),

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

  /// Build the table with 50 rows
  pw.Widget _buildTable(List<OutgoingDispatch> dispatches) {
    // Always show exactly 50 rows
    final int totalRows = 50;

    // Create a table with black border lines
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 1.0,
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
              width: 1.0,
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
                width: 0.5,
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
          fontSize: isHeader ? 12.0 : 10.0,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          color: PdfColors.black,
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
    required pw.Document pdf,
    required String unitCode,
    required String destinationUnit,
  }) async {
    final reportName = 'Transit Slip - $unitCode to $destinationUnit';

    return await _reportLibraryService.saveReport(
      pdfDocument: pdf,
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
