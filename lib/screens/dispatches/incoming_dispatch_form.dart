import 'dart:async';
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
import '../../services/unit_manager.dart';
import '../../utils/responsive_layout_util.dart';
import '../../widgets/attachment_list.dart';
import '../../widgets/enhanced_card.dart';
import '../../screens/units/unit_form_dialog.dart';

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
  final UnitManager _unitManager = UnitManager();

  // For unit changes subscription
  StreamSubscription? _unitChangesSubscription;

  // For loading state
  bool _isLoadingUnits = false;
  List<Unit> _allUnits = [];

  // Unit variables
  Unit? _senderUnit;
  Unit? _recipientUnit;

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

  // Unit selection (moved to above)

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
  final List<String> _priorities = ['IMM', 'Normal', 'Urgent', 'Flash'];
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

    // Initialize UnitManager
    _unitManager.initialize().then((_) {
      // Subscribe to unit changes
      _unitChangesSubscription = _unitManager.unitChanges.listen((_) {
        debugPrint('IncomingDispatchForm: Received unit change notification');
        _loadUnits();
      });

      // Load units
      _loadUnits();
    });

    // Initialize unit service for backward compatibility
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
    } else {
      // Set default values for new dispatch
      _referenceController.text =
          'IN-${DateTime.now().year}-${_generateReferenceNumber()}';

      // Clear the Received By and Handled By fields
      _handledByController.text = '';
      _receivedByController.text = '';

      _timeHandedIn = DateTime.now(); // Default to current time
      _timeCleared =
          null; // Default to null (will be set when dispatch is cleared)

      // Don't set a default recipient unit - leave ADDR TO unselected
      // _setPrimaryUnitAsDefault(); - Removed to leave ADDR TO unselected
    }
  }

  // Load units from the UnitManager
  Future<void> _loadUnits() async {
    if (_isLoadingUnits) return;

    setState(() {
      _isLoadingUnits = true;
    });

    try {
      debugPrint('IncomingDispatchForm: Loading units from UnitManager');

      // Initialize UnitManager if not already initialized
      if (!_unitManager.isInitialized) {
        await _unitManager.initialize();
      }

      // Load all units directly from the database
      final units = await _unitManager.getAllUnits();

      debugPrint(
          'IncomingDispatchForm: Loaded ${units.length} units from UnitManager');

      // Print all units for debugging
      if (units.isNotEmpty) {
        debugPrint('IncomingDispatchForm: Units loaded:');
        for (var i = 0; i < units.length; i++) {
          final unit = units[i];
          debugPrint(
              '  Unit ${i + 1}: ID=${unit.id}, Name=${unit.name}, Code=${unit.code}');
        }
      } else {
        debugPrint('IncomingDispatchForm: NO UNITS LOADED FROM DATABASE!');
      }

      // Update state with new units
      if (mounted) {
        setState(() {
          _allUnits = units;

          // Find sender unit if editing
          if (_isEditing && _senderUnitController.text.isNotEmpty) {
            for (final unit in units) {
              if (unit.name.toLowerCase() ==
                      _senderUnitController.text.toLowerCase() ||
                  unit.code.toLowerCase() ==
                      _senderUnitController.text.toLowerCase()) {
                _senderUnit = unit;
                break;
              }
            }
          }

          // Find recipient unit if editing
          if (_isEditing && _addrToController.text.isNotEmpty) {
            for (final unit in units) {
              if (unit.name.toLowerCase() ==
                      _addrToController.text.toLowerCase() ||
                  unit.code.toLowerCase() ==
                      _addrToController.text.toLowerCase()) {
                _recipientUnit = unit;
                break;
              }
            }
          }

          // If not editing, don't set a default recipient unit
          if (!_isEditing) {
            // Leave _recipientUnit as null to make the dropdown unselected
            _recipientUnit = null;
            _addrToController.text = '';
          }

          _isLoadingUnits = false;
        });
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Units refreshed (${units.length} units)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('IncomingDispatchForm: Units loaded and state updated');
    } catch (e) {
      debugPrint('IncomingDispatchForm: Error loading units: $e');
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading units: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    // Cancel subscription
    _unitChangesSubscription?.cancel();

    // Dispose controllers
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
          handledBy: 'System', // Default value since we removed the field
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
                                  labelText: 'P/ACTION *',
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
                              labelText: 'P/ACTION *',
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
                title: 'Delivery Information',
                icon: FontAwesomeIcons.userLarge,
                child: Column(
                  children: [
                    if (!isMobile) // Two-column layout for tablet and desktop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender Unit (ADDR FROM)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ADDR FROM (Sender Unit) *',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (_isLoadingUnits)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<Unit>(
                                        value: _senderUnit,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(
                                              FontAwesomeIcons.buildingUser,
                                              size: 16),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                        ),
                                        hint: const Text('Select sender unit'),
                                        items: _allUnits.map((Unit unit) {
                                          return DropdownMenuItem<Unit>(
                                            value: unit,
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    unit.code,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    unit.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (unit.isPrimary) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        validator: (value) {
                                          if (value == null) {
                                            return 'Please select a sender unit';
                                          }
                                          return null;
                                        },
                                        onChanged: (Unit? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _senderUnit = newValue;
                                              _senderUnitController.text =
                                                  newValue.name;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),

                                  // Add New Unit Button moved to ADDR TO section
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else // Single column for mobile
                      Column(
                        children: [
                          // Delivered By field moved to Receiving Information section

                          // ADDR FROM (Sender Unit)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ADDR FROM (Sender Unit) *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_isLoadingUnits)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<Unit>(
                                    value: _senderUnit,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(
                                          FontAwesomeIcons.buildingUser,
                                          size: 16),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    hint: const Text('Select sender unit'),
                                    items: _allUnits.map((Unit unit) {
                                      return DropdownMenuItem<Unit>(
                                        value: unit,
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                unit.code,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                unit.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (unit.isPrimary) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a sender unit';
                                      }
                                      return null;
                                    },
                                    onChanged: (Unit? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _senderUnit = newValue;
                                          _senderUnitController.text =
                                              newValue.name;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),

                              // Add New Unit Button moved to ADDR TO section
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // ADDR TO (Recipient Unit)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ADDR TO (Recipient Unit) *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_isLoadingUnits)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<Unit>(
                              value: _recipientUnit,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                    FontAwesomeIcons.buildingUser,
                                    size: 16),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              hint: const Text('Select recipient unit'),
                              items: _allUnits.map((Unit unit) {
                                return DropdownMenuItem<Unit>(
                                  value: unit,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          unit.code,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          unit.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unit.isPrimary) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a recipient unit';
                                }
                                return null;
                              },
                              onChanged: (Unit? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _recipientUnit = newValue;
                                    _addrToController.text = newValue.name;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        // Add New Unit Button
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(FontAwesomeIcons.circlePlus,
                                    size: 16),
                                label: const Text('Add New Unit'),
                                onPressed: () => _showAddUnitDialog(),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),

                              // Refresh Button
                              TextButton.icon(
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh Units'),
                                onPressed: () {
                                  // Show loading indicator
                                  setState(() {
                                    _isLoadingUnits = true;
                                  });

                                  // Reload units
                                  _loadUnits();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                    // Delivered By (moved from Delivery Information section)
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

  // Show dialog to add a new unit - USING THE SAME APPROACH AS TRANSIT FORM
  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

  // Handle unit saved callback - same as in Transit Form
  Future<void> _handleUnitSaved(Unit unit, bool isNew) async {
    if (!mounted) return;

    setState(() {
      _isLoadingUnits = true;
    });

    try {
      debugPrint(
          'IncomingDispatchForm: Handling unit save: ${unit.name} (${unit.code}), isNew: $isNew');

      bool success = false;
      if (isNew) {
        // Add the unit using UnitManager
        final savedUnit = await _unitManager.addUnit(unit);
        success = savedUnit != null;

        if (success) {
          // Also add to UnitService for compatibility
          await _unitService.addUnit(savedUnit);

          // Update the unit in our state
          setState(() {
            // Add to all units if not already there
            if (!_allUnits.any((u) => u.id == savedUnit.id)) {
              _allUnits.add(savedUnit);
            }

            // Set as sender or recipient if needed
            if (_senderUnit == null) {
              _senderUnit = savedUnit;
              _senderUnitController.text = savedUnit.name;
            } else if (_recipientUnit == null) {
              _recipientUnit = savedUnit;
              _addrToController.text = savedUnit.name;
            }
          });
        }
      } else {
        // Update the unit using UnitManager
        success = await _unitManager.updateUnit(unit);

        if (success) {
          // Also update in UnitService for compatibility
          await _unitService.updateUnit(unit);

          // Update the unit in our state
          setState(() {
            // Update in all units
            final index = _allUnits.indexWhere((u) => u.id == unit.id);
            if (index >= 0) {
              _allUnits[index] = unit;
            } else {
              _allUnits.add(unit);
            }

            // Update sender/recipient if needed
            if (_senderUnit?.id == unit.id) {
              _senderUnit = unit;
              _senderUnitController.text = unit.name;
            }
            if (_recipientUnit?.id == unit.id) {
              _recipientUnit = unit;
              _addrToController.text = unit.name;
            }
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoadingUnits = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew
                ? 'Unit added successfully'
                : 'Unit updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Force a reload of all units to ensure we have the latest data
        _loadUnits();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isNew ? 'Failed to add unit' : 'Failed to update unit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('IncomingDispatchForm: Error in _handleUnitSaved: $e');
      if (mounted) {
        setState(() {
          _isLoadingUnits = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
