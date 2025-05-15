import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_attachment.dart';
import '../services/attachment_service.dart';
import '../constants/app_theme.dart';

/// Widget for displaying a list of attachments
class AttachmentList extends StatelessWidget {
  final List<FileAttachment> attachments;
  final Function(FileAttachment)? onTap;
  final Function(FileAttachment)? onDelete;
  final bool isEditable;

  const AttachmentList({
    super.key,
    required this.attachments,
    this.onTap,
    this.onDelete,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No attachments'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return AttachmentListItem(
          attachment: attachment,
          onTap: onTap != null ? () => onTap!(attachment) : null,
          onDelete: isEditable && onDelete != null
              ? () => onDelete!(attachment)
              : null,
        );
      },
    );
  }
}

/// Widget for displaying a single attachment item
class AttachmentListItem extends StatelessWidget {
  final FileAttachment attachment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AttachmentListItem({
    super.key,
    required this.attachment,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: _buildFileIcon(),
        title: Text(
          attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${attachment.formattedSize} • ${attachment.uploadedAt}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (attachment.isImage) {
      iconData = FontAwesomeIcons.image;
      iconColor = Colors.blue;
    } else if (attachment.mimeType.contains('pdf')) {
      iconData = FontAwesomeIcons.filePdf;
      iconColor = Colors.red;
    } else if (attachment.mimeType.contains('word')) {
      iconData = FontAwesomeIcons.fileWord;
      iconColor = Colors.blue;
    } else if (attachment.mimeType.contains('excel') ||
        attachment.mimeType.contains('spreadsheet')) {
      iconData = FontAwesomeIcons.fileExcel;
      iconColor = Colors.green;
    } else if (attachment.mimeType.contains('text')) {
      iconData = FontAwesomeIcons.fileLines;
      iconColor = Colors.grey;
    } else {
      iconData = FontAwesomeIcons.file;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

/// Widget for picking and displaying attachments
class AttachmentPicker extends StatefulWidget {
  final List<FileAttachment> attachments;
  final Function(List<FileAttachment>) onAttachmentsChanged;
  final String referenceType;
  final String referenceId;

  const AttachmentPicker({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    required this.referenceType,
    required this.referenceId,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  final AttachmentService _attachmentService = AttachmentService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Attachment list
        if (widget.attachments.isNotEmpty)
          AttachmentList(
            attachments: widget.attachments,
            isEditable: true,
            onTap: _viewAttachment,
            onDelete: _deleteAttachment,
          ),

        const SizedBox(height: 8),

        // Add attachment button
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _pickFile,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(FontAwesomeIcons.paperclip),
          label: Text(_isLoading ? 'Adding...' : 'Add Attachment'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final file = await _attachmentService.pickFile();
      if (file != null) {
        final attachment = await _attachmentService.saveAttachment(
          file: file,
          referenceType: widget.referenceType,
          referenceId: widget.referenceId,
        );

        if (attachment != null) {
          final updatedAttachments = [...widget.attachments, attachment];
          widget.onAttachmentsChanged(updatedAttachments);
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewAttachment(FileAttachment attachment) async {
    try {
      // Get the attachment file
      final file = await _attachmentService.getAttachment(attachment.path);

      // Check if we got the file and if the widget is still mounted
      if (!mounted) return;

      if (file != null) {
        // Get application documents directory for saving the file
        final directory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${directory.path}/Downloads');

        // Create downloads directory if it doesn't exist
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        // Copy file to downloads directory with original name
        final downloadPath = '${downloadDir.path}/${attachment.name}';
        await file.copy(downloadPath);

        // Check if widget is still mounted before showing snackbar
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: $downloadPath'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () async {
                try {
                  if (Platform.isWindows) {
                    await Process.run('explorer.exe', [downloadPath]);
                  } else if (Platform.isAndroid) {
                    // For Android, you would use a plugin like open_file
                    debugPrint('Opening file on Android: $downloadPath');
                  } else if (Platform.isIOS) {
                    // For iOS, you would use a plugin like open_file
                    debugPrint('Opening file on iOS: $downloadPath');
                  }
                } catch (e) {
                  debugPrint('Error opening file: $e');
                }
              },
            ),
          ),
        );
      } else {
        // File is null, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not retrieve file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error handling attachment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAttachment(FileAttachment attachment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the attachment
      final success =
          await _attachmentService.deleteAttachment(attachment.path);

      // Check if widget is still mounted
      if (!mounted) return;

      if (success) {
        // Update the attachments list
        final updatedAttachments =
            widget.attachments.where((a) => a.id != attachment.id).toList();
        widget.onAttachmentsChanged(updatedAttachments);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment deleted'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete attachment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message if mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting attachment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Update loading state if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
