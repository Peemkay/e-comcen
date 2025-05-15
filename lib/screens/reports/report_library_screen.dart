import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../constants/app_theme.dart';
import '../../services/report_library_service.dart';
import '../../widgets/responsive_scaffold.dart';
import 'pdf_preview_screen.dart';

/// Screen to display all generated reports with a side preview
class ReportLibraryScreen extends StatefulWidget {
  const ReportLibraryScreen({super.key});

  @override
  State<ReportLibraryScreen> createState() => _ReportLibraryScreenState();
}

class _ReportLibraryScreenState extends State<ReportLibraryScreen> {
  final ReportLibraryService _reportLibraryService = ReportLibraryService();
  
  List<SavedReport> _reports = [];
  SavedReport? _selectedReport;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'All';
  
  // Filter options
  final List<String> _reportTypes = [
    'All',
    'Dispatch Summary',
    'Transit Slip',
    'Incoming Report',
    'Communication State',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  /// Load all reports from the library
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _reportLibraryService.getAllReports();
      
      setState(() {
        _reports = reports;
        _isLoading = false;
        
        // Select the first report if available
        if (_reports.isNotEmpty && _selectedReport == null) {
          _selectedReport = _reports.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Filter reports based on search query and type filter
  List<SavedReport> _getFilteredReports() {
    return _reports.where((report) {
      // Apply type filter
      if (_filterType != 'All' && report.reportType != _filterType) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        return report.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               report.reportType.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }

  /// Delete a report
  Future<void> _deleteReport(SavedReport report) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text('Are you sure you want to delete "${report.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Delete the report
    final success = await _reportLibraryService.deleteReport(report.id);
    
    if (success) {
      // Reload reports
      await _loadReports();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open a report
  Future<void> _openReport(SavedReport report) async {
    final success = await _reportLibraryService.openReport(report.id);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening report'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Report Library'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search reports...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Type filter
                      DropdownButton<String>(
                        value: _filterType,
                        items: _reportTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterType = value;
                            });
                          }
                        },
                        hint: const Text('Filter by type'),
                      ),
                    ],
                  ),
                ),
                
                // Reports list and preview
                Expanded(
                  child: _reports.isEmpty
                      ? _buildEmptyState()
                      : isWideScreen
                          ? _buildWideLayout(filteredReports)
                          : _buildNarrowLayout(filteredReports),
                ),
              ],
            ),
    );
  }

  /// Build the empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.fileCircleXmark,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No reports found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate reports from the Reports screen',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_chart),
            label: const Text('Go to Reports'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the wide layout with side-by-side list and preview
  Widget _buildWideLayout(List<SavedReport> reports) {
    return Row(
      children: [
        // Reports list (left side)
        Expanded(
          flex: 3,
          child: _buildReportsList(reports),
        ),
        
        // Vertical divider
        const VerticalDivider(width: 1),
        
        // Report preview (right side)
        Expanded(
          flex: 4,
          child: _selectedReport != null
              ? _buildReportPreview(_selectedReport!)
              : const Center(
                  child: Text('Select a report to preview'),
                ),
        ),
      ],
    );
  }

  /// Build the narrow layout with stacked list and preview
  Widget _buildNarrowLayout(List<SavedReport> reports) {
    return _buildReportsList(reports);
  }

  /// Build the reports list
  Widget _buildReportsList(List<SavedReport> reports) {
    return reports.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No matching reports found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _filterType = 'All';
                    });
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final isSelected = _selectedReport?.id == report.id;
              
              return _buildReportCard(report, isSelected);
            },
          );
  }

  /// Build a report card
  Widget _buildReportCard(SavedReport report, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReport = report;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report thumbnail or icon
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: report.thumbnailPath != null
                      ? Image.file(
                          File(report.thumbnailPath!),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          _getReportIcon(report.reportType),
                          size: 64,
                          color: Colors.grey[600],
                        ),
                ),
              ),
            ),
            
            // Report details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.reportType,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.formattedCreatedAt,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.formattedFileSize,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: 'Open',
                    onPressed: () => _openReport(report),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Delete',
                    onPressed: () => _deleteReport(report),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the report preview
  Widget _buildReportPreview(SavedReport report) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          Text(
            report.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getReportIcon(report.reportType),
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                report.reportType,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${report.formattedCreatedAt}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Size: ${report.formattedFileSize}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
                onPressed: () => _openReport(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: () => _deleteReport(report),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // PDF preview
          Expanded(
            child: _buildPdfPreview(report),
          ),
        ],
      ),
    );
  }

  /// Build the PDF preview
  Widget _buildPdfPreview(SavedReport report) {
    final file = File(report.filePath);
    
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'File not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The file at ${report.filePath} does not exist.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.filePdf,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'PDF Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              path.basename(report.filePath),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
              onPressed: () => _openReport(report),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the icon for a report type
  IconData _getReportIcon(String reportType) {
    switch (reportType) {
      case 'Dispatch Summary':
        return FontAwesomeIcons.fileLines;
      case 'Transit Slip':
        return FontAwesomeIcons.fileExport;
      case 'Incoming Report':
        return FontAwesomeIcons.fileImport;
      case 'Communication State':
        return FontAwesomeIcons.fileWaveform;
      default:
        return FontAwesomeIcons.filePdf;
    }
  }
}
