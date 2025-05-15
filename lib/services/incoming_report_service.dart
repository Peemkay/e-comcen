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

/// Service for generating Incoming Dispatch reports in A4 format
class IncomingReportService {
  final DispatchService _dispatchService = DispatchService();

  /// Report settings
  final Map<String, dynamic> _settings = {
    'pageSize': PdfPageFormat.a4,
    'orientation': 'portrait',
    'margin': const pw.EdgeInsets.all(40.0),
    'headerHeight': 40.0,
    'footerHeight': 30.0,
    'rowsPerPage': 25,
    'fontSize': {
      'header': 14.0,
      'title': 12.0,
      'body': 10.0,
      'footer': 8.0,
    },
    'showPageNumbers': true,
    'showDateGenerated': true,
    'showUnitInfo': true,
    'tableHeaderColor': PdfColors.grey200,
    'tableBorderColor': PdfColors.grey300,
    'alternateRowColor': PdfColors.grey100,
  };

  /// Get current settings
  Map<String, dynamic> get settings => _settings;

  /// Update settings
  void updateSettings(Map<String, dynamic> newSettings) {
    _settings.addAll(newSettings);
  }

  /// Generate an Incoming Dispatch report
  Future<pw.Document> generateIncomingReport({
    required DateTime startDate,
    required DateTime endDate,
    String? senderUnit,
    String? addrTo,
    String? priority,
    String? status,
    String sortBy = 'date',
    bool sortAscending = false,
  }) async {
    // Initialize fonts
    await PdfFonts.init();

    // Create a new PDF document with custom theme
    final pdf = pw.Document(
      theme: PdfFonts.getTheme(),
    );

    // Get dispatches based on filters
    final dispatches = await _getFilteredDispatches(
      startDate: startDate,
      endDate: endDate,
      senderUnit: senderUnit,
      addrTo: addrTo,
      priority: priority,
      status: status,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );

    // Format the current date for the header
    final currentDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    // Add pages to the document
    // Always create at least one page, even if there are no dispatches
    final int totalPages = dispatches.isEmpty
        ? 1
        : (dispatches.length / _settings['rowsPerPage']).ceil();

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      // If there are no dispatches, use an empty list
      List<IncomingDispatch> pageDispatches;
      if (dispatches.isEmpty) {
        pageDispatches = [];
      } else {
        final int startIndex = (pageIndex * _settings['rowsPerPage']).toInt();
        final int endIndex =
            (startIndex + _settings['rowsPerPage'] > dispatches.length)
                ? dispatches.length
                : (startIndex + _settings['rowsPerPage']).toInt();

        pageDispatches = dispatches.sublist(startIndex, endIndex);
      }

      pdf.addPage(
        pw.Page(
          pageFormat: _settings['pageSize'],
          margin: _settings['margin'],
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with underlined date
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'INCOMING DISPATCH REPORT: $currentDate',
                        style: pw.TextStyle(
                          fontSize: _settings['fontSize']['header'],
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(
                        thickness: 2.0,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Filter information
                _buildFilterInfo(
                    startDate, endDate, senderUnit, addrTo, priority, status),

                pw.SizedBox(height: 20),

                // Tabulated table
                _buildDispatchTable(pageDispatches),

                pw.Spacer(),

                // Footer
                if (_settings['showPageNumbers'])
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
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Build filter information section
  pw.Widget _buildFilterInfo(DateTime startDate, DateTime endDate,
      String? senderUnit, String? addrTo, String? priority, String? status) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Filter Criteria:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: _settings['fontSize']['body'],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Date Range: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: pw.TextStyle(fontSize: _settings['fontSize']['body']),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Sender Unit: ${senderUnit ?? 'All'}',
                  style: pw.TextStyle(fontSize: _settings['fontSize']['body']),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Address To: ${addrTo ?? 'All'}',
                  style: pw.TextStyle(fontSize: _settings['fontSize']['body']),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Priority: ${priority ?? 'All'}',
                  style: pw.TextStyle(fontSize: _settings['fontSize']['body']),
                ),
              ),
            ],
          ),
          if (status != null)
            pw.Text(
              'Status: $status',
              style: pw.TextStyle(fontSize: _settings['fontSize']['body']),
            ),
        ],
      ),
    );
  }

  /// Build the dispatch table
  pw.Widget _buildDispatchTable(List<IncomingDispatch> dispatches) {
    // Always show exactly 50 rows, even if there are fewer dispatches
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
        1: const pw.FixedColumnWidth(60), // P/ACTION
        2: const pw.FixedColumnWidth(100), // ORIGINATOR'S NUMBER
        3: const pw.FlexColumnWidth(1.5), // ADDR FROM
        4: const pw.FlexColumnWidth(1.5), // ADDR TO
        5: const pw.FixedColumnWidth(60), // THI
        6: const pw.FixedColumnWidth(60), // TCL
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        // Table header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(color: PdfColors.black, width: 1.0),
          ),
          repeat: true, // Repeat header on each page
          children: [
            _buildTableCell('S/N', isHeader: true),
            _buildTableCell('P/ACTION', isHeader: true),
            _buildTableCell('ORIGINATOR\'S NUMBER', isHeader: true),
            _buildTableCell('ADDR FROM', isHeader: true),
            _buildTableCell('ADDR TO', isHeader: true),
            _buildTableCell('THI', isHeader: true),
            _buildTableCell('TCL', isHeader: true),
          ],
        ),

        // Generate all rows (1-50)
        ...List.generate(totalRows, (index) {
          final isEven = index % 2 == 0;
          final hasData = index < dispatches.length;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey100 : PdfColors.white,
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            children: [
              // S/N column (always show row number)
              _buildTableCell('${index + 1}'),

              // Other columns (show data if available, otherwise empty)
              _buildTableCell(hasData ? dispatches[index].priority : ''),
              _buildTableCell(
                  hasData ? dispatches[index].originatorsNumber : ''),
              _buildTableCell(hasData ? dispatches[index].senderUnit : ''),
              _buildTableCell(hasData ? dispatches[index].addrTo : ''),
              _buildTableCell(hasData && dispatches[index].timeHandedIn != null
                  ? DateFormat('HH:mm').format(dispatches[index].timeHandedIn!)
                  : ''),
              _buildTableCell(hasData && dispatches[index].timeCleared != null
                  ? DateFormat('HH:mm').format(dispatches[index].timeCleared!)
                  : ''),
            ],
          );
        }),
      ],
    );
  }

  /// Build a table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
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
      ),
    );
  }

  /// Get filtered dispatches based on criteria
  Future<List<IncomingDispatch>> _getFilteredDispatches({
    required DateTime startDate,
    required DateTime endDate,
    String? senderUnit,
    String? addrTo,
    String? priority,
    String? status,
    String sortBy = 'date',
    bool sortAscending = false,
  }) async {
    // Get all incoming dispatches
    List<IncomingDispatch> dispatches =
        _dispatchService.getIncomingDispatches();

    // Apply date range filter
    dispatches = dispatches.where((dispatch) {
      return dispatch.dateTime.isAfter(startDate) &&
          dispatch.dateTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Apply sender unit filter
    if (senderUnit != null && senderUnit != 'All') {
      dispatches = dispatches.where((dispatch) {
        return dispatch.senderUnit == senderUnit;
      }).toList();
    }

    // Apply addr to filter
    if (addrTo != null && addrTo != 'All') {
      dispatches = dispatches.where((dispatch) {
        return dispatch.addrTo == addrTo;
      }).toList();
    }

    // Apply priority filter
    if (priority != null && priority != 'All') {
      dispatches = dispatches.where((dispatch) {
        return dispatch.priority == priority;
      }).toList();
    }

    // Apply status filter
    if (status != null && status != 'All') {
      dispatches = dispatches.where((dispatch) {
        return dispatch.status == status;
      }).toList();
    }

    // Apply sorting
    dispatches.sort((a, b) {
      switch (sortBy) {
        case 'date':
          return sortAscending
              ? a.dateTime.compareTo(b.dateTime)
              : b.dateTime.compareTo(a.dateTime);
        case 'priority':
          return sortAscending
              ? a.priority.compareTo(b.priority)
              : b.priority.compareTo(a.priority);
        case 'reference':
          return sortAscending
              ? a.referenceNumber.compareTo(b.referenceNumber)
              : b.referenceNumber.compareTo(a.referenceNumber);
        default:
          return sortAscending
              ? a.dateTime.compareTo(b.dateTime)
              : b.dateTime.compareTo(a.dateTime);
      }
    });

    return dispatches;
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
