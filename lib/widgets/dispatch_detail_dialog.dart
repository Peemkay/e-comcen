import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/dispatch.dart';
import '../models/file_attachment.dart';
import 'attachment_list.dart';

/// Dialog for displaying dispatch details
class DispatchDetailDialog extends StatelessWidget {
  final Dispatch dispatch;
  final bool isTrash;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  
  const DispatchDetailDialog({
    super.key,
    required this.dispatch,
    this.isTrash = false,
    this.onRestore,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
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
                    _getDispatchTypeIcon(),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dispatch.subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference number and date
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Reference',
                            dispatch.referenceNumber,
                            FontAwesomeIcons.hashtag,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Date',
                            DateFormat('dd MMM yyyy HH:mm').format(dispatch.dateTime),
                            FontAwesomeIcons.calendar,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sender and recipient
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'From',
                            dispatch.sender,
                            FontAwesomeIcons.userPen,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'To',
                            dispatch.recipient,
                            FontAwesomeIcons.userCheck,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority and status
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Priority',
                            dispatch.priority,
                            dispatch.getPriorityIcon(),
                            valueColor: dispatch.getPriorityColor(),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Status',
                            isTrash ? 'Deleted' : dispatch.status,
                            isTrash ? FontAwesomeIcons.trash : dispatch.getStatusIcon(),
                            valueColor: isTrash ? Colors.red : dispatch.getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Security classification
                    _buildInfoItem(
                      'Security Classification',
                      dispatch.securityClassification,
                      FontAwesomeIcons.lock,
                    ),
                    const SizedBox(height: 16),
                    
                    // Content
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(dispatch.content),
                    ),
                    const SizedBox(height: 16),
                    
                    // Attachments
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (dispatch.fileAttachments != null && dispatch.fileAttachments!.isNotEmpty)
                      AttachmentList(
                        attachments: dispatch.fileAttachments!,
                        onTap: (attachment) => _viewAttachment(context, attachment),
                      )
                    else if (dispatch.attachments.isNotEmpty)
                      Text(
                        '${dispatch.attachments.length} attachment(s)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        'No attachments',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Logs
                    const Text(
                      'Activity Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (dispatch.logs.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dispatch.logs.length,
                        itemBuilder: (context, index) {
                          final log = dispatch.logs[index];
                          return ListTile(
                            leading: const Icon(FontAwesomeIcons.clockRotateLeft),
                            title: Text(log.action),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy HH:mm').format(log.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (log.notes.isNotEmpty)
                                  Text(
                                    log.notes,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              log.performedBy,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        'No activity logs',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Actions
            if (isTrash)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onRestore != null) {
                          onRestore!();
                        }
                      },
                      icon: const Icon(FontAwesomeIcons.arrowRotateLeft, color: Colors.green),
                      label: const Text('Restore', style: TextStyle(color: Colors.green)),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (onDelete != null) {
                          onDelete!();
                        }
                      },
                      icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                      label: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build info item
  Widget _buildInfoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Get icon for dispatch type
  IconData _getDispatchTypeIcon() {
    if (dispatch is IncomingDispatch) {
      return FontAwesomeIcons.envelopeOpenText;
    } else if (dispatch is OutgoingDispatch) {
      return FontAwesomeIcons.paperPlane;
    } else if (dispatch is LocalDispatch) {
      return FontAwesomeIcons.buildingUser;
    } else if (dispatch is ExternalDispatch) {
      return FontAwesomeIcons.globe;
    } else {
      return FontAwesomeIcons.envelope;
    }
  }
  
  // View attachment
  void _viewAttachment(BuildContext context, FileAttachment attachment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${attachment.name}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    // In a real app, this would open the attachment
  }
}
