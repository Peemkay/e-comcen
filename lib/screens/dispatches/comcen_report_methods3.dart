// Build action buttons row
Widget _buildActionButtonsRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _printReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(FontAwesomeIcons.print),
          label: const Text('Print Report'),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _exportReport,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(FontAwesomeIcons.fileExport),
          label: const Text('Export Report'),
        ),
      ),
    ],
  );
}

// Print report
Future<void> _printReport() async {
  try {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Communication State Report - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Export report
void _exportReport() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Export functionality will be implemented in a future update'),
      backgroundColor: Colors.blue,
    ),
  );
}

// Generate PDF
Future<pw.Document> _generatePdf() async {
  final pdf = pw.Document();
  
  // Get report data
  final status = _reportData!['currentStatus'] as String;
  final lastChecked = _reportData!['lastChecked'] as DateTime;
  final lastCheckedBy = _reportData!['lastCheckedBy'] as String;
  final uptimePercentage = _reportData!['uptimePercentage'] as double;
  final totalChecks = _reportData!['totalChecks'] as int;
  final logs = _reportData!['logs'] as List<DispatchLog>;
  final servicesByType = _reportData!['servicesByType'] as Map<String, int>;
  
  // Format date range for display
  String dateRangeText = 'All Time';
  if (_startDate != null && _endDate != null) {
    final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
    final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
    dateRangeText = '$startFormatted to $endFormatted';
  } else if (_startDate != null) {
    final startFormatted = DateFormat('dd MMM yyyy').format(_startDate!);
    dateRangeText = 'From $startFormatted';
  } else if (_endDate != null) {
    final endFormatted = DateFormat('dd MMM yyyy').format(_endDate!);
    dateRangeText = 'Until $endFormatted';
  }
  
  // Add pages to PDF
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Header(
        level: 0,
        child: pw.Text(
          'Communication State Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey,
          ),
        ),
      ),
      build: (context) => [
        // Report metadata
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Report Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date Range: $_timeRange ($dateRangeText)'),
                  pw.Text('Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Service Type: $_serviceTypeFilter'),
                  pw.Text('Total Services: ${logs.length}'),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        
        // Current Status
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Current Status',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        status,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: _getPdfStatusColor(status),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Last checked: ${DateFormat('dd MMM yyyy HH:mm').format(lastChecked)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'By: $lastCheckedBy',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Uptime',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        '${uptimePercentage.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Total Checks: $totalChecks',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    ),
  );
  
  return pdf;
}

// Helper to get PDF status color
PdfColor _getPdfStatusColor(String status) {
  switch (status) {
    case 'Operational':
      return PdfColors.green;
    case 'Down':
      return PdfColors.red;
    case 'Intermittent':
      return PdfColors.orange;
    case 'Under Maintenance':
      return PdfColors.blue;
    default:
      return PdfColors.grey;
  }
}
