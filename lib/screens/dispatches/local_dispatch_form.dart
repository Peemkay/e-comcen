import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../models/file_attachment.dart';
import '../../services/dispatch_service.dart';
import '../../services/attachment_service.dart';
import '../../utils/responsive_util.dart';
import '../../widgets/attachment_list.dart';

class LocalDispatchForm extends StatefulWidget {
  final LocalDispatch? dispatch;

  const LocalDispatchForm({super.key, this.dispatch});

  @override
  State<LocalDispatchForm> createState() => _LocalDispatchFormState();
}

class _LocalDispatchFormState extends State<LocalDispatchForm> {
  final _formKey = GlobalKey<FormState>();
  final DispatchService _dispatchService = DispatchService();
  final AttachmentService _attachmentService = AttachmentService();

  // Form controllers
  final _referenceController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _senderController = TextEditingController();
  final _senderDepartmentController = TextEditingController();
  final _recipientController = TextEditingController();
  final _recipientDepartmentController = TextEditingController();
  final _handledByController = TextEditingController();

  // Form values
  DateTime _dispatchDate = DateTime.now();
  String _priority = 'Normal';
  String _securityClassification = 'Unclassified';
  String _status = 'Pending';
  List<String> _attachments = [];
  List<FileAttachment> _fileAttachments = [];

  // Lists for dropdowns
  final List<String> _priorities = ['Normal', 'Urgent', 'Flash'];
  final List<String> _securityClassifications = [
    'Unclassified',
    'Restricted',
    'Confidential',
    'Secret',
    'Top Secret'
  ];
  // Get all status labels from the DispatchStatus enum
  final List<String> _statuses =
      DispatchStatus.values.map((status) => status.label).toList();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dispatch != null;

    if (_isEditing) {
      // Populate form with existing dispatch data
      _referenceController.text = widget.dispatch!.referenceNumber;
      _subjectController.text = widget.dispatch!.subject;
      _contentController.text = widget.dispatch!.content;
      _senderController.text = widget.dispatch!.sender;
      _senderDepartmentController.text = widget.dispatch!.senderDepartment;
      _recipientController.text = widget.dispatch!.recipient;
      _recipientDepartmentController.text =
          widget.dispatch!.recipientDepartment;
      _handledByController.text = widget.dispatch!.handledBy;

      _dispatchDate = widget.dispatch!.dateTime;
      _priority = widget.dispatch!.priority;
      _securityClassification = widget.dispatch!.securityClassification;
      _status = widget.dispatch!.status;
      _attachments = List.from(widget.dispatch!.attachments);

      // Load file attachments if available
      if (widget.dispatch!.fileAttachments != null) {
        _fileAttachments = List.from(widget.dispatch!.fileAttachments!);
      } else if (widget.dispatch!.attachments.isNotEmpty) {
        // Load attachments from paths
        _loadAttachmentsFromPaths();
      }
    } else {
      // Set default values for new dispatch - no auto-generation
      _referenceController.text = ''; // User must enter manually
      _handledByController.text = ''; // User must enter manually
      _senderController.text = ''; // User must enter manually
    }
  }

  Future<void> _loadAttachmentsFromPaths() async {
    if (_attachments.isNotEmpty) {
      _fileAttachments =
          await _attachmentService.getAttachmentsFromPaths(_attachments);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _senderController.dispose();
    _senderDepartmentController.dispose();
    _recipientController.dispose();
    _recipientDepartmentController.dispose();
    _handledByController.dispose();
    super.dispose();
  }

  // Removed auto-generation method - users now enter reference numbers manually

  Future<void> _selectDispatchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dispatchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dispatchDate) {
      setState(() {
        _dispatchDate = picked;
      });
    }
  }

  void _saveDispatch() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create dispatch object
      final dispatch = LocalDispatch(
        id: _isEditing
            ? widget.dispatch!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        referenceNumber: _referenceController.text,
        subject: _subjectController.text,
        content: _contentController.text,
        dateTime: _dispatchDate,
        priority: _priority,
        securityClassification: _securityClassification,
        status: _status,
        handledBy: _handledByController.text,
        sender: _senderController.text,
        senderDepartment: _senderDepartmentController.text,
        recipient: _recipientController.text,
        recipientDepartment: _recipientDepartmentController.text,
        attachments: _attachments,
        fileAttachments: _fileAttachments,
        logs: _isEditing
            ? [
                ...widget.dispatch!.logs,
                DispatchLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  action: _isEditing ? 'Updated' : 'Created',
                  performedBy: 'Admin',
                  notes: _isEditing
                      ? 'Updated local dispatch'
                      : 'Created new local dispatch',
                ),
              ]
            : [
                DispatchLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  action: 'Created',
                  performedBy: 'Admin',
                  notes: 'Created new local dispatch',
                ),
              ],
        trackingStatus:
            _status != 'Pending' ? DispatchStatus.fromString(_status) : null,
      );

      // Save to service
      if (_isEditing) {
        _dispatchService.updateLocalDispatch(dispatch);
      } else {
        _dispatchService.addLocalDispatch(dispatch);
      }

      setState(() {
        _isLoading = false;
      });

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Dispatch updated successfully'
              : 'Dispatch added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device
    final isMobile = ResponsiveUtil.isMobile(context);
    final isDesktop = ResponsiveUtil.isDesktop(context);

    // Get responsive padding
    final padding = ResponsiveUtil.getValueForScreenType<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
    );

    // Get responsive spacing
    final spacing = ResponsiveUtil.getValueForScreenType<double>(
      context: context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return Scaffold(
        appBar: AppBar(
          title:
              Text(_isEditing ? 'Edit Local Dispatch' : 'New Local Dispatch'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: padding,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        isDesktop ? 1000 : (isMobile ? double.infinity : 800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use responsive layout for form fields
                      // Single reference field for all screen sizes
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference or Originator\'s Number *',
                          hintText: 'Enter Reference or Originator\'s Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.hashtag, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a reference or originator\'s number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.envelope, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content
                      TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon:
                              Icon(FontAwesomeIcons.fileLines, size: 16),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter content';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dispatch Date
                      InkWell(
                        onTap: () => _selectDispatchDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dispatch Date',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(FontAwesomeIcons.calendar, size: 16),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_dispatchDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.flag, size: 16),
                        ),
                        items: _priorities.map((String priority) {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _priority = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Security Classification
                      DropdownButtonFormField<String>(
                        value: _securityClassification,
                        decoration: const InputDecoration(
                          labelText: 'Security Classification',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.lock, size: 16),
                        ),
                        items: _securityClassifications
                            .map((String classification) {
                          return DropdownMenuItem<String>(
                            value: classification,
                            child: Text(classification),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _securityClassification = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(FontAwesomeIcons.circleInfo, size: 16),
                        ),
                        items: _statuses.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _status = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sender
                      TextFormField(
                        controller: _senderController,
                        decoration: const InputDecoration(
                          labelText: 'Sender',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter sender name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sender Department
                      TextFormField(
                        controller: _senderDepartmentController,
                        decoration: const InputDecoration(
                          labelText: 'Sender Department',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(FontAwesomeIcons.buildingUser, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter sender department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Recipient
                      TextFormField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient',
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(FontAwesomeIcons.userCheck, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter recipient name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Recipient Department
                      TextFormField(
                        controller: _recipientDepartmentController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.building, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter recipient department';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Handled By
                      TextFormField(
                        controller: _handledByController,
                        decoration: const InputDecoration(
                          labelText: 'Handled By',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.userGear, size: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter handler name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Attachments
                      AttachmentPicker(
                        attachments: _fileAttachments,
                        onAttachmentsChanged: (attachments) {
                          setState(() {
                            _fileAttachments = attachments;
                            // Update attachment paths for backward compatibility
                            _attachments =
                                attachments.map((a) => a.path).toList();
                          });
                        },
                        referenceType: 'local_dispatch',
                        referenceId: _isEditing
                            ? widget.dispatch!.id
                            : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveDispatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(_isEditing
                                  ? 'Update Dispatch'
                                  : 'Save Dispatch'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}
