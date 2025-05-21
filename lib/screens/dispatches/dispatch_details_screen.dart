// Add these imports at the top of the file
import 'package:nasds/widgets/print_options_dialog.dart';
import 'package:nasds/utils/printing_service.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:nasds/mocks/printing.dart';

// Add this method to the _DispatchDetailsScreenState class
Future<void> _printDispatch() async {
  try {
    // Show print options dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PrintOptionsDialog(
        documentName: 'Dispatch - ${widget.dispatch.referenceNumber}',
      ),
    );

    // If dialog was cancelled
    if (result == null) {
      return;
    }

    final printAction = result['action'] as PrintAction;
    final pageFormat = result['pageFormat'] as pdf.PdfPageFormat;

    // Generate PDF
    pdfGenerator(pdf.PdfPageFormat format) async {
      final document = pw.Document();

      document.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    widget.dispatch.isIncoming
                        ? 'Incoming Dispatch'
                        : 'Outgoing Dispatch',
                  ),
                ),
                pw.SizedBox(height: 20),

                // Reference Number
                pw.Row(
                  children: [
                    pw.Text(
                      'Reference Number:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.referenceNumber),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Dispatch Date
                pw.Row(
                  children: [
                    pw.Text(
                      'Dispatch Date:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      widget.dispatch.dispatchDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.dispatch.dispatchDate!)
                          : 'Not specified',
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Received/Sent Date
                pw.Row(
                  children: [
                    pw.Text(
                      widget.dispatch.isIncoming
                          ? 'Received Date:'
                          : 'Sent Date:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      widget.dispatch.receivedDate != null
                          ? DateFormat('dd/MM/yyyy')
                              .format(widget.dispatch.receivedDate!)
                          : 'Not specified',
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Origin
                pw.Row(
                  children: [
                    pw.Text(
                      'Origin:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.origin),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Destination
                pw.Row(
                  children: [
                    pw.Text(
                      'Destination:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.destination),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Service Type
                pw.Row(
                  children: [
                    pw.Text(
                      'Service Type:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.serviceType),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Security Classification
                pw.Row(
                  children: [
                    pw.Text(
                      'Security Classification:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.securityClassification),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Precedence
                pw.Row(
                  children: [
                    pw.Text(
                      'Precedence:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.precedence),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Subject
                pw.Text(
                  'Subject:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(widget.dispatch.subject),
                ),
                pw.SizedBox(height: 20),

                // Content
                pw.Text(
                  'Content:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(widget.dispatch.content),
                ),
                pw.SizedBox(height: 20),

                // Remarks
                if (widget.dispatch.remarks != null &&
                    widget.dispatch.remarks!.isNotEmpty) ...[
                  pw.Text(
                    'Remarks:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(widget.dispatch.remarks!),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Status
                pw.Row(
                  children: [
                    pw.Text(
                      'Status:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(widget.dispatch.status),
                  ],
                ),

                // Footer with page number
                pw.Footer(
                  trailing: pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: pdf.PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return document.save();
    }

    switch (printAction) {
      case PrintAction.print:
        final printer = result['printer'] as Printer?;
        final copies = result['copies'] as int;
        final grayscale = result['grayscale'] as bool;

        await PrintingService.printPdf(
          onLayout: pdfGenerator,
          documentName: 'Dispatch - ${widget.dispatch.referenceNumber}',
          printer: printer,
          copies: copies,
          grayscale: grayscale,
          pageFormat: pageFormat,
        );
        break;

      case PrintAction.preview:
        await PrintingService.showPrintPreview(
          onLayout: pdfGenerator,
          documentName: 'Dispatch - ${widget.dispatch.referenceNumber}',
          pageFormat: pageFormat,
        );
        break;

      case PrintAction.share:
        await PrintingService.sharePdf(
          onLayout: pdfGenerator,
          documentName:
              'Dispatch_${widget.dispatch.referenceNumber.replaceAll('/', '_')}.pdf',
          pageFormat: pageFormat,
        );
        break;
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Update the build method to include a print button in the app bar
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Dispatch Details'),
      actions: [
        // Print button
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.print),
          tooltip: 'Print Dispatch',
          onPressed: _printDispatch,
        ),
        // Edit button (if user has permission)
        if (_canEdit)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.penToSquare),
            tooltip: 'Edit Dispatch',
            onPressed: _editDispatch,
          ),
      ],
    ),
    body: _buildBody(),
  );
}
