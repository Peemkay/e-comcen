import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:nasds/constants/app_theme.dart';
import 'package:nasds/models/file_attachment.dart';
import 'package:nasds/utils/file_utils.dart';

class AttachmentPicker extends StatefulWidget {
  final List<FileAttachment> attachments;
  final Function(List<FileAttachment>) onAttachmentsChanged;
  final String referenceType;
  final String referenceId;
  final bool readOnly;

  const AttachmentPicker({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    required this.referenceType,
    required this.referenceId,
    this.readOnly = false,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attachment list
        if (widget.attachments.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final attachment = widget.attachments[index];
              final fileName = path.basename(attachment.path);
              final fileExtension =
                  path.extension(attachment.path).toLowerCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getFileIcon(fileExtension),
                  title: Text(
                    fileName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    FileUtils.getFormattedFileSize(attachment.size),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: widget.readOnly
                      ? IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.download,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () => _viewAttachment(attachment),
                        )
                      : IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.trash,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeAttachment(index),
                        ),
                  onTap: () => _viewAttachment(attachment),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Add attachment button
        if (!widget.readOnly)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickFiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const FaIcon(FontAwesomeIcons.paperclip, size: 16),
            label: const Text('Add Attachment'),
          ),
      ],
    );
  }

  Widget _getFileIcon(String fileExtension) {
    IconData iconData;
    Color iconColor;

    switch (fileExtension) {
      case '.pdf':
        iconData = FontAwesomeIcons.filePdf;
        iconColor = Colors.red;
        break;
      case '.doc':
      case '.docx':
        iconData = FontAwesomeIcons.fileWord;
        iconColor = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
        iconData = FontAwesomeIcons.fileExcel;
        iconColor = Colors.green;
        break;
      case '.ppt':
      case '.pptx':
        iconData = FontAwesomeIcons.filePowerpoint;
        iconColor = Colors.orange;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        iconData = FontAwesomeIcons.fileImage;
        iconColor = Colors.purple;
        break;
      case '.txt':
        iconData = FontAwesomeIcons.fileLines;
        iconColor = Colors.grey;
        break;
      case '.zip':
      case '.rar':
        iconData = FontAwesomeIcons.fileZipper;
        iconColor = Colors.brown;
        break;
      default:
        iconData = FontAwesomeIcons.file;
        iconColor = Colors.grey;
    }

    return FaIcon(
      iconData,
      color: iconColor,
      size: 24,
    );
  }

  Future<void> _pickFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final newAttachments = <FileAttachment>[];

        for (final file in result.files) {
          if (file.path != null) {
            final fileObj = File(file.path!);
            final fileSize = await fileObj.length();

            newAttachments.add(
              FileAttachment(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${file.name}',
                path: file.path!,
                name: file.name,
                size: fileSize,
                mimeType: FileUtils.getMimeType(file.path!),
                referenceType: widget.referenceType,
                referenceId: widget.referenceId,
                uploadDate: DateTime.now(),
              ),
            );
          }
        }

        final updatedAttachments = [...widget.attachments, ...newAttachments];
        widget.onAttachmentsChanged(updatedAttachments);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeAttachment(int index) {
    final attachment = widget.attachments[index];

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text(
            'Are you sure you want to delete "${path.basename(attachment.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove the attachment
              final updatedAttachments =
                  List<FileAttachment>.from(widget.attachments);
              updatedAttachments.removeAt(index);
              widget.onAttachmentsChanged(updatedAttachments);

              // Show success message
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachment deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewAttachment(FileAttachment attachment) async {
    try {
      await FileUtils.openFile(attachment.path);
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
}
