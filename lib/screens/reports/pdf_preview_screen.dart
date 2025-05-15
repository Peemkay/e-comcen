import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../constants/app_theme.dart';
import '../../services/file_save_dialog_service.dart';
import '../../services/report_library_service.dart';

/// A screen to preview PDF documents
class PdfPreviewScreen extends StatefulWidget {
  /// The PDF document to preview
  final pw.Document pdfDocument;

  /// The default file name to use when saving
  final String defaultFileName;

  /// The title to display in the app bar
  final String title;

  /// The saved report (if already saved to the library)
  final SavedReport? savedReport;

  /// Create a PDF preview screen
  const PdfPreviewScreen({
    super.key,
    required this.pdfDocument,
    required this.defaultFileName,
    this.title = 'PDF Preview',
    this.savedReport,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = false;
  String? _tempFilePath;
  String? _savedFilePath;
  String? _errorMessage;
  final FileSaveDialogService _fileSaveDialogService = FileSaveDialogService();

  @override
  void initState() {
    super.initState();
    _createTempFile();
  }

  @override
  void dispose() {
    _deleteTempFile();
    super.dispose();
  }

  /// Create a temporary file to display the PDF
  Future<void> _createTempFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create a temporary directory if it doesn't exist
      final tempDir = Directory.systemTemp.createTempSync('nasds_pdf_preview');

      // Create a temporary file
      final tempFile = File('${tempDir.path}/${widget.defaultFileName}');

      // Save the PDF to the temporary file
      await tempFile.writeAsBytes(await widget.pdfDocument.save());

      setState(() {
        _tempFilePath = tempFile.path;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating temporary file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete the temporary file
  Future<void> _deleteTempFile() async {
    if (_tempFilePath != null) {
      try {
        final tempFile = File(_tempFilePath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        // Try to delete the parent directory if it's empty
        final tempDir = Directory(path.dirname(_tempFilePath!));
        if (await tempDir.exists()) {
          final files = await tempDir.list().toList();
          if (files.isEmpty) {
            await tempDir.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting temporary file: $e');
      }
    }
  }

  /// Save the PDF to a user-selected location
  Future<void> _savePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Show the save file dialog
      final filePath = await _fileSaveDialogService.saveFileWithDialog(
        widget.pdfDocument,
        widget.defaultFileName,
      );

      setState(() {
        _savedFilePath = filePath;
      });

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openFile(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Open the saved file
  Future<void> _openFile(String filePath) async {
    try {
      final success = await _fileSaveDialogService.openFile(filePath);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the file. Try opening it manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Open the folder containing the saved file
  Future<void> _openFolder() async {
    if (_savedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the file first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success =
          await _fileSaveDialogService.openContainingFolder(_savedFilePath!);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not open the folder. Try opening it manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // View in library button (if saved to library)
          if (widget.savedReport != null)
            IconButton(
              icon: const Icon(FontAwesomeIcons.folderOpen),
              tooltip: 'View in Library',
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/report_library');
                    },
            ),
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save PDF',
            onPressed: _isLoading ? null : _savePdf,
          ),
          // Open folder button
          if (_savedFilePath != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open containing folder',
              onPressed: _isLoading ? null : _openFolder,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Build the body of the screen
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createTempFile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tempFilePath == null) {
      return const Center(
        child: Text('No PDF to display'),
      );
    }

    // Use a placeholder for the PDF preview
    // In a real implementation, you would use a PDF viewer plugin
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.filePdf,
            color: AppTheme.primaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'PDF Preview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            widget.defaultFileName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Show message if already saved to library
          if (widget.savedReport != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26), // 0.1 opacity
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Saved to Report Library',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(FontAwesomeIcons.folderOpen),
                    label: const Text('View in Library'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/report_library');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          if (widget.savedReport == null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save PDF'),
              onPressed: _savePdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_savedFilePath != null)
              TextButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Open containing folder'),
                onPressed: _openFolder,
              ),
          ],
        ],
      ),
    );
  }
}
