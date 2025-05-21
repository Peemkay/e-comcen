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
import '../../widgets/attachment_picker.dart';
import '../../widgets/enhanced_card.dart';
import '../../screens/units/simple_unit_form_dialog.dart';

class OutFileForm extends StatefulWidget {
  final IncomingDispatch? dispatch;

  const OutFileForm({super.key, this.dispatch});

  @override
  State<OutFileForm> createState() => _OutFileFormState();
}

class _OutFileFormState extends State<OutFileForm> {
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
  final _remarksController = TextEditingController();

  // Time controllers
  DateTime? _timeHandedIn; // THI
  DateTime? _timeCleared; // TCL

  // Form values
  DateTime _dispatchDate = DateTime.now();
  DateTime _sentDate = DateTime.now(); // For OutgoingDispatch
  String _priority = 'ROUTINE';
  String _securityClassification = 'Unclassified';
  String _status = 'Pending';
  String _deliveryMethod = 'Standard';
  List<String> _attachments = [];
  List<FileAttachment> _fileAttachments = [];

  // Services
  final AttachmentService _attachmentService = AttachmentService();

  // Lists for dropdowns
  final List<String> _priorities = ['IMM', 'FLASH', 'PRIORITY', 'ROUTINE'];
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
        debugPrint('OutFileForm: Received unit change notification');
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
      _sentDate = DateTime.now(); // Default for outgoing dispatch
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
          'OUT-${DateTime.now().year}-${_generateReferenceNumber()}';

      // Clear the Received By and Handled By fields
      _handledByController.text = '';
      _receivedByController.text = '';

      _timeHandedIn = DateTime.now(); // Default to current time
      _timeCleared =
          null; // Default to null (will be set when dispatch is cleared)
    }
  }

  // Load units from the UnitManager
  Future<void> _loadUnits() async {
    if (_isLoadingUnits) return;

    setState(() {
      _isLoadingUnits = true;
    });

    try {
      debugPrint('OutFileForm: Loading units from UnitManager');

      // Initialize UnitManager if not already initialized
      if (!_unitManager.isInitialized) {
        await _unitManager.initialize();
      }

      // Load all units directly from the database
      final units = await _unitManager.getAllUnits();

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
    } catch (e) {
      debugPrint('OutFileForm: Error loading units: $e');
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
    _remarksController.dispose();
    super.dispose();
  }

  String _generateReferenceNumber() {
    // Get current date components
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    // Get count of existing dispatches and add 1
    final count = (_dispatchService.getOutgoingDispatches().length + 1)
        .toString()
        .padLeft(3, '0');

    // Format: OUT-YYYYMMDD-XXX (where XXX is a sequential number)
    return 'OUT-$year$month$day-$count';
  }

  // Method to select dispatch date
  Future<void> _selectDispatchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dispatchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dispatchDate) {
      setState(() {
        _dispatchDate = picked;
      });
    }
  }

  // Method to select time handed in
  Future<void> _selectTimeHandedIn(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeHandedIn != null
          ? TimeOfDay.fromDateTime(_timeHandedIn!)
          : TimeOfDay.now(),
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

  // Method to select time cleared
  Future<void> _selectTimeCleared(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeCleared != null
          ? TimeOfDay.fromDateTime(_timeCleared!)
          : TimeOfDay.now(),
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

  // Show dialog to add a new unit
  Future<void> _showAddUnitDialog() async {
    setState(() {
      _isLoadingUnits = true;
    });

    try {
      // Show the simplified dialog and wait for the result
      final Unit? newUnit = await showDialog<Unit>(
        context: context,
        builder: (context) => const SimpleUnitFormDialog(),
      );

      // If the user cancelled the dialog, newUnit will be null
      if (newUnit == null) {
        setState(() {
          _isLoadingUnits = false;
        });
        return;
      }

      debugPrint(
          'OutFileForm: Adding new unit: ${newUnit.name} (${newUnit.code}) with ID ${newUnit.id}');

      // Save the unit to both services
      bool success = false;
      Unit? savedUnit;

      try {
        // Try to save to UnitManager first - this is the primary storage
        final unitManagerResult = await _unitManager.addUnit(newUnit);
        debugPrint(
            'OutFileForm: UnitManager result: ${unitManagerResult != null ? 'Success' : 'Failed'}');

        // Then save to UnitService - this is for compatibility
        final unitServiceResult = await _unitService.addUnit(newUnit);
        debugPrint(
            'OutFileForm: UnitService result: ${unitServiceResult != null ? 'Success' : 'Failed'}');

        // Use the result from UnitManager if available, otherwise use the one from UnitService
        savedUnit = unitManagerResult ?? unitServiceResult ?? newUnit;

        // Consider it a success if either service worked
        success = unitManagerResult != null || unitServiceResult != null;
      } catch (e) {
        debugPrint('OutFileForm: Error saving unit to services: $e');
        success = false;
        savedUnit = newUnit; // Use the original unit as fallback
      }

      // Check if still mounted before updating UI
      if (!mounted) return;

      if (success) {
        debugPrint('OutFileForm: Unit saved successfully, refreshing units');

        // Force a refresh of all units in the application
        final updatedUnits = await _unitManager.getAllUnits();

        // Manually trigger a notification to ensure all components are updated
        _unitManager.notifyUnitChanges();

        // Check if still mounted before updating UI
        if (!mounted) return;

        // Now update the UI with the saved unit
        setState(() {
          // Update the units list
          _allUnits = updatedUnits;

          // Auto-select the unit if appropriate
          if (savedUnit != null) {
            if (_senderUnit == null) {
              _senderUnit = savedUnit;
              _senderUnitController.text = savedUnit.code;
            } else if (_recipientUnit == null) {
              _recipientUnit = savedUnit;
              _addrToController.text = savedUnit.code;
            }
          }

          _isLoadingUnits = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unit "${savedUnit.name}" added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Check if still mounted before updating UI
        if (!mounted) return;

        debugPrint('OutFileForm: Unit save failed, using fallback approach');

        // Still add to local list as fallback
        setState(() {
          if (savedUnit != null) {
            // Check if the unit already exists in the list
            final existingIndex =
                _allUnits.indexWhere((u) => u.id == savedUnit!.id);

            if (existingIndex >= 0) {
              // Update existing unit
              _allUnits[existingIndex] = savedUnit;
            } else {
              // Add new unit
              _allUnits.add(savedUnit);
            }
          }

          // Auto-select the unit if appropriate
          if (savedUnit != null) {
            if (_senderUnit == null) {
              _senderUnit = savedUnit;
              _senderUnitController.text = savedUnit.code;
            } else if (_recipientUnit == null) {
              _recipientUnit = savedUnit;
              _addrToController.text = savedUnit.code;
            }
          }

          _isLoadingUnits = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unit partially saved - may not appear in all dropdowns'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('OutFileForm: Error in _showAddUnitDialog: $e');

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

  // Handle unit selection for sender
  void _handleSenderUnitSelected(Unit unit) {
    setState(() {
      _senderUnit = unit;
      _senderUnitController.text = unit.code;
    });
  }

  // Handle unit selection for recipient
  void _handleRecipientUnitSelected(Unit unit) {
    setState(() {
      _recipientUnit = unit;
      _addrToController.text = unit.code;
    });
  }

  Future<void> _saveDispatch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
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
          recipient: _addrToController
              .text, // Person receiving (using unit name as fallback)
          recipientUnit: _addrToController.text, // ADDR TO (recipient unit)
          sentBy: _senderUnitController.text, // ADDR FROM (sender unit)
          sentDate: _sentDate, // Using current date for sent date
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
                        ? 'Updated OUT FILE dispatch'
                        : 'Created new OUT FILE dispatch',
                  ),
                ]
              : [
                  DispatchLog(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    timestamp: DateTime.now(),
                    action: 'Created',
                    performedBy: 'Admin',
                    notes: 'Created new OUT FILE dispatch',
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

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'OUT FILE dispatch updated successfully'
                : 'OUT FILE dispatch added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving OUT FILE dispatch: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit OUT FILE' : 'New OUT FILE'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDispatch,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    // Get screen size to determine layout
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Form(
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
                                  return 'Please enter reference number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        // Originator's Number
                        Expanded(
                          child: TextFormField(
                            controller: _originatorsNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Originator\'s Number',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.hashtag, size: 16),
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
                              return 'Please enter reference number';
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
                            prefixIcon:
                                Icon(FontAwesomeIcons.hashtag, size: 16),
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
                      prefixIcon: Icon(FontAwesomeIcons.noteSticky, size: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter subject';
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
                                  prefixIcon:
                                      Icon(FontAwesomeIcons.calendar, size: 16),
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
                          child: DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(FontAwesomeIcons.flag, size: 16),
                            ),
                            items: _priorities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _priority = newValue!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select priority';
                              }
                              return null;
                            },
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
                            prefixIcon: Icon(FontAwesomeIcons.flag, size: 16),
                          ),
                          items: _priorities.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _priority = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select priority';
                            }
                            return null;
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
                                prefixIcon:
                                    Icon(FontAwesomeIcons.lock, size: 16),
                              ),
                              items:
                                  _securityClassifications.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _securityClassification = newValue!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select security classification';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        // Status
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status *',
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(FontAwesomeIcons.circleCheck, size: 16),
                            ),
                            items: _statuses.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _status = newValue!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select status';
                              }
                              return null;
                            },
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
                            prefixIcon: Icon(FontAwesomeIcons.lock, size: 16),
                          ),
                          items: _securityClassifications.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _securityClassification = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select security classification';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status *',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(FontAwesomeIcons.circleCheck, size: 16),
                          ),
                          items: _statuses.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _status = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select status';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Unit Information Card (ADDR FROM/TO)
            EnhancedCard(
              title: 'Unit Information',
              icon: FontAwesomeIcons.buildingUser,
              child: Column(
                children: [
                  // Sender Unit Dropdown (ADDR FROM)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender Unit Dropdown
                      Expanded(
                        child: DropdownButtonFormField<Unit>(
                          decoration: const InputDecoration(
                            labelText: 'ADDR FROM *',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(FontAwesomeIcons.buildingUser, size: 16),
                          ),
                          hint: const Text('Select sender unit'),
                          value: _senderUnit,
                          items: _allUnits.map((Unit unit) {
                            return DropdownMenuItem<Unit>(
                              value: unit,
                              child: Text('${unit.code} - ${unit.name}'),
                            );
                          }).toList(),
                          onChanged: (Unit? newValue) {
                            if (newValue != null) {
                              _handleSenderUnitSelected(newValue);
                            }
                          },
                          validator: (value) {
                            if (_senderUnitController.text.isEmpty) {
                              return 'Please select sender unit';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recipient Unit Dropdown (ADDR TO)
                  DropdownButtonFormField<Unit>(
                    decoration: const InputDecoration(
                      labelText: 'ADDR TO *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(FontAwesomeIcons.buildingUser, size: 16),
                    ),
                    hint: const Text('Select recipient unit'),
                    value: _recipientUnit,
                    items: _allUnits.map((Unit unit) {
                      return DropdownMenuItem<Unit>(
                        value: unit,
                        child: Text('${unit.code} - ${unit.name}'),
                      );
                    }).toList(),
                    onChanged: (Unit? newValue) {
                      if (newValue != null) {
                        _handleRecipientUnitSelected(newValue);
                      }
                    },
                    validator: (value) {
                      if (_addrToController.text.isEmpty) {
                        return 'Please select recipient unit';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Unit management buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Add New Unit'),
                        onPressed: _showAddUnitDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Units',
                        onPressed: _loadUnits,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional Fields Card
            EnhancedCard(
              title: 'Additional Information',
              icon: FontAwesomeIcons.circleInfo,
              child: Column(
                children: [
                  // P/ACTION Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'P/ACTION *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(FontAwesomeIcons.bolt, size: 16),
                    ),
                    value: _priority,
                    items: ['IMM', 'FLASH', 'PRIORITY', 'ROUTINE']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _priority = newValue;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Delivered By field
                  TextFormField(
                    controller: _senderController,
                    decoration: const InputDecoration(
                      labelText: 'Delivered By *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter delivered by';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // THI (Time Handed In)
                  InkWell(
                    onTap: () => _selectTimeHandedIn(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'THI (Time Handed In) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.clock, size: 16),
                      ),
                      child: Text(
                        _timeHandedIn != null
                            ? DateFormat('HH:mm').format(_timeHandedIn!)
                            : 'Select time',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TCL (Time Cleared)
                  InkWell(
                    onTap: () => _selectTimeCleared(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'TCL (Time Cleared)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(FontAwesomeIcons.clock, size: 16),
                      ),
                      child: Text(
                        _timeCleared != null
                            ? DateFormat('HH:mm').format(_timeCleared!)
                            : 'Select time',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Handled By field
                  TextFormField(
                    controller: _handledByController,
                    decoration: const InputDecoration(
                      labelText: 'Handled By *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(FontAwesomeIcons.userGear, size: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter handled by';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Remarks Card
            EnhancedCard(
              title: 'Remarks',
              icon: FontAwesomeIcons.noteSticky,
              child: Column(
                children: [
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(FontAwesomeIcons.comment, size: 16),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Attachments Card
            EnhancedCard(
              title: 'Attachments',
              icon: FontAwesomeIcons.paperclip,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use AttachmentPicker widget
                  AttachmentPicker(
                    attachments: _fileAttachments,
                    onAttachmentsChanged: (attachments) {
                      setState(() {
                        _fileAttachments = attachments;
                        // Update attachment paths for backward compatibility
                        _attachments = attachments.map((a) => a.path).toList();
                      });
                    },
                    referenceType: 'out_file',
                    referenceId: _isEditing
                        ? widget.dispatch!.id
                        : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 8),

            // Save Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Update OUT FILE' : 'Save OUT FILE'),
                onPressed: _isLoading ? null : _saveDispatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
