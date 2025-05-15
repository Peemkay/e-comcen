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
                      ? 'Updated transit form'
                      : 'Created new transit form',
                ),
              ]
            : [
                DispatchLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  timestamp: DateTime.now(),
                  action: 'Created',
                  performedBy: 'Admin',
                  notes: 'Created new transit form',
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
              ? 'Transit Form updated successfully'
              : 'Transit Form added successfully'),
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
        title: Text(_isEditing ? 'Edit Transit Form' : 'New Transit Form'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withAlpha(13),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Header
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _isEditing ? 'Edit Transit Details' : 'New Transit Form',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                // Main Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Divider(height: 24),

                        // 1. Reference Number
                        TextFormField(
                          controller: _referenceController,
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            hintText: 'Enter reference number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon:
                                const Icon(FontAwesomeIcons.hashtag, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a reference number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. Subject (Optional)
                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: 'Subject (Optional)',
                            hintText: 'Enter subject',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon:
                                const Icon(FontAwesomeIcons.envelope, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          // No validator since it's optional
                        ),
                        const SizedBox(height: 20),

                        // 3. Date and Time
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDispatchDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date and Time',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(
                                        FontAwesomeIcons.calendar,
                                        size: 16),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy HH:mm')
                                        .format(_dispatchDate),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4. Security Classification
                        DropdownButtonFormField<String>(
                          value: _securityClassification,
                          decoration: InputDecoration(
                            labelText: 'Security Classification',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon:
                                const Icon(FontAwesomeIcons.lock, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
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
                        const SizedBox(height: 20),

                        // 5. Status
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(FontAwesomeIcons.circleInfo,
                                size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sender and Recipient Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        const Text(
                          'Sender and Recipient',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Divider(height: 24),

                        // 6. From (Sender Unit)
                        TextFormField(
                          controller: _sentByController,
                          decoration: InputDecoration(
                            labelText: 'From',
                            hintText: 'Enter sender unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                                FontAwesomeIcons.buildingUser,
                                size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter sender unit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 7. To (Recipient Unit)
                        TextFormField(
                          controller: _recipientUnitController,
                          decoration: InputDecoration(
                            labelText: 'To',
                            hintText: 'Enter recipient unit',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(
                                FontAwesomeIcons.buildingFlag,
                                size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter recipient unit';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Delivery Details Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        const Text(
                          'Delivery Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Divider(height: 24),

                        // 8. Delivered By
                        TextFormField(
                          controller: _sentByController,
                          decoration: InputDecoration(
                            labelText: 'Delivered By',
                            hintText: 'Enter deliverer name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(FontAwesomeIcons.userCheck,
                                size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter deliverer name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 9. Received By
                        TextFormField(
                          controller: _recipientController,
                          decoration: InputDecoration(
                            labelText: 'Received By',
                            hintText: 'Enter receiver name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon:
                                const Icon(FontAwesomeIcons.user, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter receiver name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 10. Handled By (Optional)
                        TextFormField(
                          controller: _handledByController,
                          decoration: InputDecoration(
                            labelText: 'Handled By (Optional)',
                            hintText: 'Enter handler name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon:
                                const Icon(FontAwesomeIcons.userGear, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          // No validator since it's optional
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Attachments Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        const Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Divider(height: 24),

                        // Attachment Button
                        Center(
                          child: OutlinedButton.icon(
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
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDispatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing
                                ? 'Update Transit Form'
                                : 'Save Transit Form',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
