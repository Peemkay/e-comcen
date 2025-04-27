import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../services/dispatch_service.dart';

class OutgoingDispatchForm extends StatefulWidget {
  final OutgoingDispatch? dispatch;

  const OutgoingDispatchForm({super.key, this.dispatch});

  @override
  State<OutgoingDispatchForm> createState() => _OutgoingDispatchFormState();
}

class _OutgoingDispatchFormState extends State<OutgoingDispatchForm> {
  final _formKey = GlobalKey<FormState>();
  final DispatchService _dispatchService = DispatchService();

  // Form controllers
  final _referenceController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _recipientController = TextEditingController();
  final _recipientUnitController = TextEditingController();
  final _sentByController = TextEditingController();
  final _handledByController = TextEditingController();

  // Form values
  DateTime _dispatchDate = DateTime.now();
  DateTime _sentDate = DateTime.now();
  String _priority = 'Normal';
  String _securityClassification = 'Unclassified';
  String _status = 'Pending';
  String _deliveryMethod = 'Physical';
  List<String> _attachments = [];

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
  final List<String> _deliveryMethods = ['Physical', 'Electronic', 'Both'];

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
      _recipientController.text = widget.dispatch!.recipient;
      _recipientUnitController.text = widget.dispatch!.recipientUnit;
      _sentByController.text = widget.dispatch!.sentBy;
      _handledByController.text = widget.dispatch!.handledBy;

      _dispatchDate = widget.dispatch!.dateTime;
      _sentDate = widget.dispatch!.sentDate;
      _priority = widget.dispatch!.priority;
      _securityClassification = widget.dispatch!.securityClassification;
      _status = widget.dispatch!.status;
      _deliveryMethod = widget.dispatch!.deliveryMethod;
      _attachments = List.from(widget.dispatch!.attachments);
    } else {
      // Set default values for new dispatch
      _referenceController.text =
          'OUT-${DateTime.now().year}-${_generateReferenceNumber()}';
      _handledByController.text = 'Admin'; // Default to current user
      _sentByController.text = 'Admin'; // Default to current user
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _recipientController.dispose();
    _recipientUnitController.dispose();
    _sentByController.dispose();
    _handledByController.dispose();
    super.dispose();
  }

  String _generateReferenceNumber() {
    // Generate a 3-digit reference number
    return (100 + _dispatchService.getOutgoingDispatches().length + 1)
        .toString()
        .padLeft(3, '0');
  }

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

  Future<void> _selectSentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _sentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _sentDate) {
      setState(() {
        _sentDate = picked;
      });
    }
  }

  void _saveDispatch() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create dispatch object
      final dispatch = OutgoingDispatch(
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
        recipient: _recipientController.text,
        recipientUnit: _recipientUnitController.text,
        sentBy: _sentByController.text,
        sentDate: _sentDate,
        deliveryMethod: _deliveryMethod,
        attachments: _attachments,
        logs: _isEditing
            ? [
                ...widget.dispatch!.logs,
                DispatchLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  action: _isEditing ? 'Updated' : 'Created',
                  performedBy: 'Admin',
                  notes: _isEditing
                      ? 'Updated outgoing dispatch'
                      : 'Created new outgoing dispatch',
                ),
              ]
            : [
                DispatchLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  action: 'Created',
                  performedBy: 'Admin',
                  notes: 'Created new outgoing dispatch',
                ),
              ],
        trackingStatus:
            _status != 'Pending' ? DispatchStatus.fromString(_status) : null,
      );

      // Save to service
      if (_isEditing) {
        _dispatchService.updateOutgoingDispatch(dispatch);
      } else {
        _dispatchService.addOutgoingDispatch(dispatch);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Edit Outgoing Dispatch' : 'New Outgoing Dispatch'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference Number
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.hashtag, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reference number';
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
                  prefixIcon: Icon(FontAwesomeIcons.fileLines, size: 16),
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
                    prefixIcon: Icon(FontAwesomeIcons.calendar, size: 16),
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
                items: _securityClassifications.map((String classification) {
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
                  prefixIcon: Icon(FontAwesomeIcons.circleInfo, size: 16),
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

              // Recipient
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recipient Unit
              TextFormField(
                controller: _recipientUnitController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.buildingUser, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recipient unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sent By
              TextFormField(
                controller: _sentByController,
                decoration: const InputDecoration(
                  labelText: 'Sent By',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.userCheck, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sender name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sent Date
              InkWell(
                onTap: () => _selectSentDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sent Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.calendarCheck, size: 16),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_sentDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Method
              DropdownButtonFormField<String>(
                value: _deliveryMethod,
                decoration: const InputDecoration(
                  labelText: 'Delivery Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.truck, size: 16),
                ),
                items: _deliveryMethods.map((String method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _deliveryMethod = newValue!;
                  });
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

              // Attachments (simplified for this example)
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // In a real app, this would open a file picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'File attachment functionality would be implemented here'),
                    ),
                  );
                },
                icon: const Icon(FontAwesomeIcons.paperclip),
                label: const Text('Add Attachment'),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Update Dispatch' : 'Save Dispatch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
