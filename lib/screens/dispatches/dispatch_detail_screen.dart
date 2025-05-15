import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/file_attachment.dart';
import '../../services/dispatch_service.dart';
import '../../services/attachment_service.dart';
import '../../widgets/attachment_list.dart';
import 'incoming_dispatch_form.dart';
import 'outgoing_dispatch_form.dart';
import 'local_dispatch_form.dart';
import 'external_dispatch_form.dart';
import 'dispatch_tracking_screen.dart';

class DispatchDetailScreen extends StatefulWidget {
  final String dispatchId;
  final String dispatchType; // 'incoming', 'outgoing', 'local', 'external'

  const DispatchDetailScreen({
    super.key,
    required this.dispatchId,
    required this.dispatchType,
  });

  @override
  State<DispatchDetailScreen> createState() => _DispatchDetailScreenState();
}

class _DispatchDetailScreenState extends State<DispatchDetailScreen> {
  final DispatchService _dispatchService = DispatchService();
  final AttachmentService _attachmentService = AttachmentService();
  late Dispatch _dispatch;
  bool _isLoading = true;
  bool _isDeleting = false;
  List<FileAttachment> _fileAttachments = [];

  @override
  void initState() {
    super.initState();
    _loadDispatch();
  }

  void _loadDispatch() {
    setState(() {
      _isLoading = true;
    });

    // Load the dispatch based on type
    switch (widget.dispatchType) {
      case 'incoming':
        _dispatch = _dispatchService
            .getIncomingDispatches()
            .firstWhere((d) => d.id == widget.dispatchId);
        break;
      case 'outgoing':
        _dispatch = _dispatchService
            .getOutgoingDispatches()
            .firstWhere((d) => d.id == widget.dispatchId);
        break;
      case 'local':
        _dispatch = _dispatchService
            .getLocalDispatches()
            .firstWhere((d) => d.id == widget.dispatchId);
        break;
      case 'external':
        _dispatch = _dispatchService
            .getExternalDispatches()
            .firstWhere((d) => d.id == widget.dispatchId);
        break;
      default:
        throw Exception('Unknown dispatch type: ${widget.dispatchType}');
    }

    // Load file attachments
    _loadFileAttachments();
  }

  Future<void> _loadFileAttachments() async {
    // If dispatch already has file attachments, use them
    if (_dispatch.fileAttachments != null &&
        _dispatch.fileAttachments!.isNotEmpty) {
      setState(() {
        _fileAttachments = List.from(_dispatch.fileAttachments!);
        _isLoading = false;
      });
      return;
    }

    // Otherwise, load attachments from paths
    if (_dispatch.attachments.isNotEmpty) {
      final attachments = await _attachmentService
          .getAttachmentsFromPaths(_dispatch.attachments);
      setState(() {
        _fileAttachments = attachments;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editDispatch() {
    Widget form;

    switch (widget.dispatchType) {
      case 'incoming':
        form = IncomingDispatchForm(
          dispatch: _dispatch as IncomingDispatch,
        );
        break;
      case 'outgoing':
        form = OutgoingDispatchForm(
          dispatch: _dispatch as OutgoingDispatch,
        );
        break;
      case 'local':
        form = LocalDispatchForm(
          dispatch: _dispatch as LocalDispatch,
        );
        break;
      case 'external':
        form = ExternalDispatchForm(
          dispatch: _dispatch as ExternalDispatch,
        );
        break;
      default:
        throw Exception('Unknown dispatch type: ${widget.dispatchType}');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => form),
    ).then((_) => _loadDispatch());
  }

  void _deleteDispatch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this dispatch? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() async {
    setState(() {
      _isDeleting = true;
    });

    // Delete the dispatch based on type
    switch (widget.dispatchType) {
      case 'incoming':
        _dispatchService.deleteIncomingDispatch(widget.dispatchId);
        break;
      case 'outgoing':
        _dispatchService.deleteOutgoingDispatch(widget.dispatchId);
        break;
      case 'local':
        _dispatchService.deleteLocalDispatch(widget.dispatchId);
        break;
      case 'external':
        _dispatchService.deleteExternalDispatch(widget.dispatchId);
        break;
    }

    setState(() {
      _isDeleting = false;
    });

    // Show success message and navigate back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispatch deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _viewAttachment(FileAttachment attachment) async {
    try {
      final file = await _attachmentService.getAttachment(attachment.path);
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${attachment.name}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        // In a real app, you would open the file with a viewer
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dispatch Details'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_dispatch.referenceNumber),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.clockRotateLeft),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DispatchTrackingScreen(
                    dispatchId: widget.dispatchId,
                    dispatchType: widget.dispatchType,
                  ),
                ),
              );
            },
            tooltip: 'View Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDispatch,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDispatch,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _dispatch.subject,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _dispatch
                                      .getPriorityColor()
                                      .withAlpha(51), // 0.2 opacity
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _dispatch.priority,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _dispatch.getPriorityColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reference: ${_dispatch.referenceNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(_dispatch.dateTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  _dispatch.status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                avatar: Icon(
                                  _dispatch.getStatusIcon(),
                                  size: 14,
                                ),
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  _dispatch.securityClassification,
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                avatar: const Icon(
                                  FontAwesomeIcons.lock,
                                  size: 14,
                                ),
                                backgroundColor: Colors.grey[200],
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Content',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dispatch.content,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Handled By', _dispatch.handledBy),
                          const Divider(),

                          // Type-specific details
                          if (widget.dispatchType == 'incoming')
                            ..._buildIncomingDetails()
                          else if (widget.dispatchType == 'outgoing')
                            ..._buildOutgoingDetails()
                          else if (widget.dispatchType == 'local')
                            ..._buildLocalDetails()
                          else if (widget.dispatchType == 'external')
                            ..._buildExternalDetails(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attachments Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_fileAttachments.isEmpty)
                            const Text(
                              'No attachments',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            )
                          else
                            AttachmentList(
                              attachments: _fileAttachments,
                              onTap: _viewAttachment,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Activity Log Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activity Log',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_dispatch.logs.isEmpty)
                            const Text(
                              'No activity logs',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _dispatch.logs.length,
                              itemBuilder: (context, index) {
                                final log = _dispatch.logs[index];
                                return ListTile(
                                  leading: const Icon(
                                      FontAwesomeIcons.clockRotateLeft),
                                  title: Text(log.action),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy HH:mm')
                                            .format(log.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (log.notes.isNotEmpty)
                                        Text(
                                          log.notes,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    log.performedBy,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIncomingDetails() {
    final incomingDispatch = _dispatch as IncomingDispatch;
    return [
      _buildDetailRow('Sender', incomingDispatch.sender),
      _buildDetailRow('Sender Unit', incomingDispatch.senderUnit),
      _buildDetailRow('Received By', incomingDispatch.receivedBy),
      _buildDetailRow(
        'Received Date',
        DateFormat('dd MMM yyyy').format(incomingDispatch.receivedDate),
      ),
    ];
  }

  List<Widget> _buildOutgoingDetails() {
    final outgoingDispatch = _dispatch as OutgoingDispatch;
    return [
      _buildDetailRow('Recipient', outgoingDispatch.recipient),
      _buildDetailRow('Recipient Unit', outgoingDispatch.recipientUnit),
      _buildDetailRow('Sent By', outgoingDispatch.sentBy),
      _buildDetailRow(
        'Sent Date',
        DateFormat('dd MMM yyyy').format(outgoingDispatch.sentDate),
      ),
      _buildDetailRow('Delivery Method', outgoingDispatch.deliveryMethod),
    ];
  }

  List<Widget> _buildLocalDetails() {
    final localDispatch = _dispatch as LocalDispatch;
    return [
      _buildDetailRow('Sender', localDispatch.sender),
      _buildDetailRow('Sender Department', localDispatch.senderDepartment),
      _buildDetailRow('Recipient', localDispatch.recipient),
      _buildDetailRow(
          'Recipient Department', localDispatch.recipientDepartment),
      _buildDetailRow('Internal Reference', localDispatch.internalReference),
    ];
  }

  List<Widget> _buildExternalDetails() {
    final externalDispatch = _dispatch as ExternalDispatch;
    return [
      _buildDetailRow('Organization', externalDispatch.organization),
      _buildDetailRow('Contact Person', externalDispatch.contactPerson),
      _buildDetailRow('Contact Details', externalDispatch.contactDetails),
      _buildDetailRow(
        'Direction',
        externalDispatch.isIncoming ? 'Incoming' : 'Outgoing',
      ),
      _buildDetailRow('External Reference', externalDispatch.externalReference),
    ];
  }
}
