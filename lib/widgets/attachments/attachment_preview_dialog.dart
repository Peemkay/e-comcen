import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_theme.dart';
import '../../models/file_attachment.dart';
import '../../services/attachment_service.dart';
import '../../services/file_utility_service.dart';

/// Dialog to preview file attachments
class AttachmentPreviewDialog extends StatefulWidget {
  final FileAttachment attachment;

  const AttachmentPreviewDialog({
    super.key,
    required this.attachment,
  });

  @override
  State<AttachmentPreviewDialog> createState() =>
      _AttachmentPreviewDialogState();
}

class _AttachmentPreviewDialogState extends State<AttachmentPreviewDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),

            // Content
            Flexible(
              child: _buildContent(),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Build the dialog header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.attachment.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Build the dialog content
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File information
          _buildInfoSection('File Information', [
            _buildInfoRow('Name', widget.attachment.name),
            _buildInfoRow('Size', widget.attachment.formattedSize),
            _buildInfoRow('Type', widget.attachment.mimeType),
            _buildInfoRow(
              'Uploaded',
              widget.attachment.uploadedAt,
            ),
          ]),

          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // Reference information
          _buildInfoSection('Reference', [
            _buildInfoRow('Type', widget.attachment.referenceType),
            _buildInfoRow('ID', widget.attachment.referenceId),
          ]),
        ],
      ),
    );
  }

  /// Build the dialog actions
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Open button
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
            onPressed: _isLoading ? null : _openFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          // Download button
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: _isLoading ? null : _downloadFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build an information section
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }

  /// Build an information row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Get the file icon based on the file type
  IconData _getFileIcon() {
    if (widget.attachment.isImage) {
      return FontAwesomeIcons.fileImage;
    } else if (widget.attachment.mimeType.contains('pdf')) {
      return FontAwesomeIcons.filePdf;
    } else if (widget.attachment.mimeType.contains('word')) {
      return FontAwesomeIcons.fileWord;
    } else if (widget.attachment.mimeType.contains('excel') ||
        widget.attachment.mimeType.contains('spreadsheet')) {
      return FontAwesomeIcons.fileExcel;
    } else if (widget.attachment.mimeType.contains('text')) {
      return FontAwesomeIcons.fileLines;
    } else {
      return FontAwesomeIcons.file;
    }
  }

  /// Open the file with the default application
  Future<void> _openFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attachmentService = AttachmentService();
      final result = await attachmentService.openAttachment(widget.attachment);

      if (!result.isSuccess) {
        setState(() {
          _errorMessage = result.userFriendlyMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error opening file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Download the file to the downloads folder and open it
  Future<void> _downloadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attachmentService = AttachmentService();
      final result =
          await attachmentService.saveAndOpenAttachment(widget.attachment);

      if (!result.isSuccess) {
        setState(() {
          _errorMessage = result.userFriendlyMessage;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File saved and opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error downloading file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
