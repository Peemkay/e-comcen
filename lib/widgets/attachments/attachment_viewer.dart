import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/file_attachment.dart';
import '../../services/attachment_service.dart';

/// Widget to display and open file attachments
class AttachmentViewer extends StatelessWidget {
  final FileAttachment attachment;
  final bool showActions;
  final VoidCallback? onDelete;
  final bool isLoading;

  const AttachmentViewer({
    super.key,
    required this.attachment,
    this.showActions = true,
    this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: _buildFileIcon(),
        title: Text(
          attachment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Size: ${attachment.formattedSize}',
              style: const TextStyle(fontSize: 12),
            ),
            if (attachment.description != null &&
                attachment.description!.isNotEmpty)
              Text(
                attachment.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: showActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Open button
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: 'Open file',
                    onPressed: isLoading ? null : () => _openFile(context),
                  ),
                  // Download button
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    tooltip: 'Download file',
                    onPressed: isLoading ? null : () => _downloadFile(context),
                  ),
                  // Delete button (if onDelete is provided)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Delete file',
                      onPressed: isLoading ? null : onDelete,
                    ),
                ],
              )
            : null,
        onTap: isLoading ? null : () => _openFile(context),
      ),
    );
  }

  /// Build file icon based on file type
  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (attachment.isImage) {
      iconData = FontAwesomeIcons.fileImage;
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

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  /// Open the file with the default application
  Future<void> _openFile(BuildContext context) async {
    final attachmentService = AttachmentService();

    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Opening file...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Try to open the file
    final result = await attachmentService.openAttachment(attachment);

    // Handle the result
    if (!result.isSuccess) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result.userFriendlyMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download the file to the downloads folder and open it
  Future<void> _downloadFile(BuildContext context) async {
    final attachmentService = AttachmentService();

    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Downloading file...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Try to save and open the file
    final result = await attachmentService.saveAndOpenAttachment(attachment);

    // Handle the result
    if (context.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? 'File saved and opened successfully'
                : result.userFriendlyMessage,
          ),
          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

/// Widget to display a list of attachments
class AttachmentList extends StatelessWidget {
  final List<FileAttachment> attachments;
  final bool showActions;
  final Function(FileAttachment)? onDelete;
  final bool isLoading;

  const AttachmentList({
    super.key,
    required this.attachments,
    this.showActions = true,
    this.onDelete,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No attachments',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return AttachmentViewer(
          attachment: attachment,
          showActions: showActions,
          onDelete: onDelete != null ? () => onDelete!(attachment) : null,
          isLoading: isLoading,
        );
      },
    );
  }
}
