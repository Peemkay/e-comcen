import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../models/file_attachment.dart';
import '../../models/unit.dart';
import '../../services/dispatch_service.dart';
import '../../services/attachment_service.dart';
import '../../services/unit_service.dart';
import '../../utils/responsive_layout_util.dart';
import '../../widgets/attachment_list.dart';
import '../../widgets/enhanced_card.dart';
import '../../widgets/unit_selector.dart';

class IncomingDispatchForm extends StatefulWidget {
  final IncomingDispatch? dispatch;

  const IncomingDispatchForm({super.key, this.dispatch});

  @override
  State<IncomingDispatchForm> createState() => _IncomingDispatchFormState();
}

class _IncomingDispatchFormState extends State<IncomingDispatchForm> {
  final _formKey = GlobalKey<FormState>();
  final DispatchService _dispatchService = DispatchService();
  final UnitService _unitService = UnitService();

  // Form controllers
  final _referenceController = TextEditingController();
  final _originatorsNumberController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _senderController = TextEditingController(); // Delivered by
  final _senderUnitController = TextEditingController(); // ADDR FROM
  final _addrToController = TextEditingController(); // ADDR TO
  final _receivedByController = TextEditingController();
  final _handledByController = TextEditingController();

  // Unit selection
  Unit? _senderUnit;
  Unit? _recipientUnit;

  // Time controllers
  DateTime? _timeHandedIn; // THI
  DateTime? _timeCleared; // TCL

  // Form values
  DateTime _dispatchDate = DateTime.now();
  DateTime _receivedDate = DateTime.now();
  String _priority = 'Normal';
  String _securityClassification = 'Unclassified';
  String _status = 'Pending';
  List<String> _attachments = [];
  List<FileAttachment> _fileAttachments = [];

  // Services
  final AttachmentService _attachmentService = AttachmentService();

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

    // Initialize unit service
    _unitService.initialize();

    if (_isEditing) {
      // Populate form with existing dispatch data
      _referenceController.text = widget.dispatch!.referenceNumber;
      _originatorsNumberController.text = widget.dispatch!.originatorsNumber;
      _subjectController.text = widget.dispatch!.subject;
      _contentController.text = widget.dispatch!.content;
      _senderController.text = widget.dispatch!.sender; // Delivered by
      _senderUnitController.text = widget.dispatch!.senderUnit; // ADDR FROM
      _addrToController.text = widget.dispatch!.addrTo; // ADDR TO
      _receivedByController.text = widget.dispatch!.receivedBy;
      _handledByController.text = widget.dispatch!.handledBy;

      _dispatchDate = widget.dispatch!.dateTime;
      _receivedDate = widget.dispatch!.receivedDate;
      _timeHandedIn = widget.dispatch!.timeHandedIn;
      _timeCleared = widget.dispatch!.timeCleared;
      _priority = widget.dispatch!.priority;
      _securityClassification = widget.dispatch!.securityClassification;
      _status = widget.dispatch!.status;
      _attachments = List.from(widget.dispatch!.attachments);

      // Load file attachments if available
      if (widget.dispatch!.fileAttachments != null) {
        _fileAttachments = List.from(widget.dispatch!.fileAttachments!);
      } else if (_attachments.isNotEmpty) {
        // Convert legacy attachment paths to FileAttachment objects
        _loadAttachmentsFromPaths();
      }

      // Load units asynchronously
      _loadUnits();
    } else {
      // Set default values for new dispatch
      _referenceController.text =
          'IN-${DateTime.now().year}-${_generateReferenceNumber()}';
      _handledByController.text = 'Admin'; // Default to current user
      _receivedByController.text = 'Admin'; // Default to current user
      _timeHandedIn = DateTime.now(); // Default to current time
      _timeCleared =
          null; // Default to null (will be set when dispatch is cleared)

      // Set primary unit as default recipient unit
      _setPrimaryUnitAsDefault();
    }
  }

  // Load units for editing
  Future<void> _loadUnits() async {
    try {
      // Try to find sender unit by name
      final units = await _unitService.getAllUnits();

      // Find sender unit
      if (_senderUnitController.text.isNotEmpty) {
        for (final unit in units) {
          if (unit.name == _senderUnitController.text ||
              unit.code == _senderUnitController.text) {
            setState(() {
              _senderUnit = unit;
            });
            break;
          }
        }
      }

      // Find recipient unit
      if (_addrToController.text.isNotEmpty) {
        for (final unit in units) {
          if (unit.name == _addrToController.text ||
              unit.code == _addrToController.text) {
            setState(() {
              _recipientUnit = unit;
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading units: $e');
    }
  }

  // Set primary unit as default recipient
  Future<void> _setPrimaryUnitAsDefault() async {
    try {
      await _unitService.initialize();
      final primaryUnit = _unitService.primaryUnit;

      if (primaryUnit != null) {
        setState(() {
          _recipientUnit = primaryUnit;
          _addrToController.text = primaryUnit.name;
        });
      }
    } catch (e) {
      debugPrint('Error setting primary unit: $e');
    }
  }

  // Load attachments from paths
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
    _originatorsNumberController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _senderController.dispose();
    _senderUnitController.dispose();
    _addrToController.dispose();
    _receivedByController.dispose();
    _handledByController.dispose();
    super.dispose();
  }

  String _generateReferenceNumber() {
    // Generate a 3-digit reference number
    return (100 + _dispatchService.getIncomingDispatches().length + 1)
        .toString()
        .padLeft(3, '0');
  }

  Future<void> _selectDispatchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dispatchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dispatchDate) {
      setState(() {
        _dispatchDate = picked;
      });
    }
  }

  Future<void> _selectReceivedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _receivedDate) {
      setState(() {
        _receivedDate = picked;
      });
    }
  }

  Future<void> _selectTimeHandedIn(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeHandedIn != null
          ? TimeOfDay.fromDateTime(_timeHandedIn!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _timeHandedIn = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectTimeCleared(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeCleared != null
          ? TimeOfDay.fromDateTime(_timeCleared!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _timeCleared = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveDispatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create dispatch object
        final dispatch = IncomingDispatch(
          id: _isEditing
              ? widget.dispatch!.id
              : DateTime.now().millisecondsSinceEpoch.toString(),
          referenceNumber: _referenceController.text,
          originatorsNumber: _originatorsNumberController.text,
          subject: _subjectController.text,
          content: _contentController.text,
          dateTime: _dispatchDate,
          priority: _priority,
          securityClassification: _securityClassification,
          status: _status,
          handledBy: _handledByController.text,
          sender: _senderController.text, // Delivered by
          senderUnit: _senderUnitController.text, // ADDR FROM
          addrTo: _addrToController.text, // ADDR TO
          receivedBy: _receivedByController.text,
          receivedDate: _receivedDate,
          timeHandedIn: _timeHandedIn, // THI
          timeCleared: _timeCleared, // TCL
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
                        ? 'Updated incoming dispatch'
                        : 'Created new incoming dispatch',
                  ),
                ]
              : [
                  DispatchLog(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    timestamp: DateTime.now(),
                    action: 'Created',
                    performedBy: 'Admin',
                    notes: 'Created new incoming dispatch',
                  ),
                ],
          trackingStatus:
              _status != 'Pending' ? DispatchStatus.fromString(_status) : null,
        );

        // Save to service
        if (_isEditing) {
          _dispatchService.updateIncomingDispatch(dispatch);
        } else {
          _dispatchService.addIncomingDispatch(dispatch);
        }

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
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dispatch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printDispatch() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Printing functionality will be implemented in a future update.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayoutUtil.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Edit Incoming Dispatch' : 'New Incoming Dispatch'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.print),
              tooltip: 'Print Dispatch',
              onPressed: _printDispatch,
            ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.floppyDisk),
            tooltip: 'Save Dispatch',
            onPressed: _isLoading ? null : _saveDispatch,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              EnhancedCard(
                title: 'Basic Information',
                icon: FontAwesomeIcons.fileLines,
                child: Column(
                  children: [
                    // Use responsive layout for form fields
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reference Number
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextFormField(
                                controller: _referenceController,
                                decoration: const InputDecoration(
                                  labelText: 'Reference Number *',
                                  border: OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(FontAwesomeIcons.hashtag, size: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a reference number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          // Originator's Number
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextFormField(
                                controller: _originatorsNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Originator\'s Number',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                      FontAwesomeIcons.fileSignature,
                                      size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          TextFormField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Number *',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.hashtag, size: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a reference number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _originatorsNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Originator\'s Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(FontAwesomeIcons.fileSignature,
                                  size: 16),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.heading, size: 16),
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
                        labelText: 'Content *',
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dispatch Details Card
              EnhancedCard(
                title: 'Dispatch Details',
                icon: FontAwesomeIcons.circleInfo,
                child: Column(
                  children: [
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dispatch Date
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => _selectDispatchDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Dispatch Date *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(FontAwesomeIcons.calendar,
                                        size: 16),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(_dispatchDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Priority
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: DropdownButtonFormField<String>(
                                value: _priority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                      FontAwesomeIcons.flagCheckered,
                                      size: 16),
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
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _selectDispatchDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Dispatch Date *',
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
                          DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(FontAwesomeIcons.flagCheckered,
                                  size: 16),
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
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Security Classification
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: DropdownButtonFormField<String>(
                                value: _securityClassification,
                                decoration: const InputDecoration(
                                  labelText: 'Security Classification *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                      FontAwesomeIcons.shieldHalved,
                                      size: 16),
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
                            ),
                          ),
                          // Status
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(
                                  labelText: 'Status *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(FontAwesomeIcons.listCheck,
                                      size: 16),
                                ),
                                items: DispatchStatus.values
                                    .map((DispatchStatus status) {
                                  return DropdownMenuItem<String>(
                                    value: status.label,
                                    child: Text(status.label),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _status = newValue!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _securityClassification,
                            decoration: const InputDecoration(
                              labelText: 'Security Classification *',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.shieldHalved, size: 16),
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
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status *',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.listCheck, size: 16),
                            ),
                            items: DispatchStatus.values
                                .map((DispatchStatus status) {
                              return DropdownMenuItem<String>(
                                value: status.label,
                                child: Text(status.label),
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sender Information Card
              EnhancedCard(
                title: 'Sender Information',
                icon: FontAwesomeIcons.userLarge,
                child: Column(
                  children: [
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Delivered By (Sender)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextFormField(
                                controller: _senderController,
                                decoration: const InputDecoration(
                                  labelText: 'Delivered By *',
                                  border: OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(FontAwesomeIcons.user, size: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter deliverer name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          // Sender Unit (ADDR FROM)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: UnitSelector(
                                selectedUnitId: _senderUnit?.id,
                                label: 'ADDR FROM *',
                                isRequired: true,
                                onUnitSelected: (unit) {
                                  setState(() {
                                    _senderUnit = unit;
                                    _senderUnitController.text = unit.name;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          TextFormField(
                            controller: _senderController,
                            decoration: const InputDecoration(
                              labelText: 'Delivered By *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter deliverer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          UnitSelector(
                            selectedUnitId: _senderUnit?.id,
                            label: 'ADDR FROM *',
                            isRequired: true,
                            onUnitSelected: (unit) {
                              setState(() {
                                _senderUnit = unit;
                                _senderUnitController.text = unit.name;
                              });
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ADDR TO
                    UnitSelector(
                      selectedUnitId: _recipientUnit?.id,
                      label: 'ADDR TO *',
                      isRequired: true,
                      filterByType: UnitType
                          .headquarters, // Filter to show only headquarters units
                      onUnitSelected: (unit) {
                        setState(() {
                          _recipientUnit = unit;
                          _addrToController.text = unit.name;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Receiving Information Card
              EnhancedCard(
                title: 'Receiving Information',
                icon: FontAwesomeIcons.clipboardCheck,
                child: Column(
                  children: [
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Received By
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextFormField(
                                controller: _receivedByController,
                                decoration: const InputDecoration(
                                  labelText: 'Received By *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(FontAwesomeIcons.userCheck,
                                      size: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter receiver name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          // Received Date
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: InkWell(
                                onTap: () => _selectReceivedDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Received Date *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                        FontAwesomeIcons.calendarCheck,
                                        size: 16),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(_receivedDate),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          TextFormField(
                            controller: _receivedByController,
                            decoration: const InputDecoration(
                              labelText: 'Received By *',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.userCheck, size: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter receiver name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectReceivedDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Received Date *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(FontAwesomeIcons.calendarCheck,
                                    size: 16),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_receivedDate),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // THI (Time Handed In)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => _selectTimeHandedIn(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'THI (Time Handed In) *',
                                    border: OutlineInputBorder(),
                                    prefixIcon:
                                        Icon(FontAwesomeIcons.clock, size: 16),
                                  ),
                                  child: Text(
                                    _timeHandedIn != null
                                        ? DateFormat('HH:mm')
                                            .format(_timeHandedIn!)
                                        : 'Select time',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // TCL (Time Cleared)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: InkWell(
                                onTap: () => _selectTimeCleared(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'TCL (Time Cleared)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                        FontAwesomeIcons.clockRotateLeft,
                                        size: 16),
                                  ),
                                  child: Text(
                                    _timeCleared != null
                                        ? DateFormat('HH:mm')
                                            .format(_timeCleared!)
                                        : 'Not cleared yet',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _selectTimeHandedIn(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'THI (Time Handed In) *',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(FontAwesomeIcons.clock, size: 16),
                              ),
                              child: Text(
                                _timeHandedIn != null
                                    ? DateFormat('HH:mm').format(_timeHandedIn!)
                                    : 'Select time',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectTimeCleared(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'TCL (Time Cleared)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                    FontAwesomeIcons.clockRotateLeft,
                                    size: 16),
                              ),
                              child: Text(
                                _timeCleared != null
                                    ? DateFormat('HH:mm').format(_timeCleared!)
                                    : 'Not cleared yet',
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Handled By
                    TextFormField(
                      controller: _handledByController,
                      decoration: const InputDecoration(
                        labelText: 'Handled By *',
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Attachments Card
              EnhancedCard(
                title: 'Attachments',
                icon: FontAwesomeIcons.paperclip,
                child: AttachmentPicker(
                  attachments: _fileAttachments,
                  onAttachmentsChanged: (attachments) {
                    setState(() {
                      _fileAttachments = attachments;
                      // Update attachment paths for backward compatibility
                      _attachments = attachments.map((a) => a.path).toList();
                    });
                  },
                  referenceType: 'incoming_dispatch',
                  referenceId: _isEditing
                      ? widget.dispatch!.id
                      : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveDispatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(FontAwesomeIcons.floppyDisk),
                  label: Text(
                    _isEditing ? 'Update Dispatch' : 'Save Dispatch',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // Note about required fields
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  '* Required fields',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
