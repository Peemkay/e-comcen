import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../models/unit.dart';
import '../../services/dispatch_service.dart';
import '../../services/unit_service.dart';
import '../../services/unit_manager.dart';
import '../../screens/units/unit_form_dialog.dart';

class OutgoingDispatchForm extends StatefulWidget {
  final OutgoingDispatch? dispatch;

  const OutgoingDispatchForm({super.key, this.dispatch});

  @override
  State<OutgoingDispatchForm> createState() => _OutgoingDispatchFormState();
}

class _OutgoingDispatchFormState extends State<OutgoingDispatchForm> {
  final _formKey = GlobalKey<FormState>();
  final DispatchService _dispatchService = DispatchService();
  final UnitService _unitService = UnitService();
  final UnitManager _unitManager = UnitManager();

  // Lists to store units for dropdowns
  List<Unit> _allUnits = [];
  bool _isLoadingUnits = false;

  // Subscription to unit changes
  StreamSubscription? _unitChangesSubscription;

  // Form controllers
  final _referenceController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  final _recipientController = TextEditingController(); // Person receiving
  final _recipientUnitController = TextEditingController(); // Recipient unit
  final _sentByController = TextEditingController(); // Sender unit
  final _deliveredByController = TextEditingController(); // Person delivering
  final _handledByController = TextEditingController(); // Person handling

  // Unit objects for the sender and recipient units
  Unit? _senderUnit;
  Unit? _recipientUnit;

  // Form values
  DateTime _dispatchDate = DateTime.now();
  DateTime _sentDate = DateTime.now();
  String _priority = 'Normal';
  String _securityClassification = 'Unclassified';
  String _status = 'Pending';
  String _deliveryMethod = 'Physical';

  // Attachments
  List<String> _attachments = [];
  List<Map<String, dynamic>> _attachmentDetails = [];

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

  /// Initialize the UnitManager
  Future<void> _initializeUnitManager() async {
    try {
      debugPrint('OutgoingDispatchForm: Initializing UnitManager');
      await _unitManager.initialize();
      debugPrint('OutgoingDispatchForm: UnitManager initialized successfully');
    } catch (e) {
      debugPrint('OutgoingDispatchForm: Error initializing UnitManager: $e');
    }
  }

  /// Load all units from the UnitManager
  Future<void> _loadAllUnitsFromManager() async {
    if (_isLoadingUnits) return;

    setState(() {
      _isLoadingUnits = true;
    });

    try {
      debugPrint('OutgoingDispatchForm: Loading units from UnitManager');

      // Load all units directly from the database
      final units = await _unitManager.getAllUnits();

      debugPrint(
          'OutgoingDispatchForm: Loaded ${units.length} units from UnitManager');

      // Print all units for debugging
      if (units.isNotEmpty) {
        debugPrint('OutgoingDispatchForm: Units loaded:');
        for (var i = 0; i < units.length; i++) {
          final unit = units[i];
          debugPrint(
              '  Unit ${i + 1}: ID=${unit.id}, Name=${unit.name}, Code=${unit.code}');
        }
      } else {
        debugPrint('OutgoingDispatchForm: NO UNITS LOADED FROM DATABASE!');
      }

      // Reset sender and recipient units to ensure we're using the latest data
      _senderUnit = null;
      _recipientUnit = null;

      // If we have units, select appropriate ones
      if (units.isNotEmpty) {
        // Select primary unit as sender
        _senderUnit = units.firstWhere(
          (unit) => unit.isPrimary,
          orElse: () => units.first,
        );
        _sentByController.text = _senderUnit!.name;

        // If we have more than one unit, select a different one as recipient
        if (units.length > 1) {
          _recipientUnit = units.firstWhere(
            (unit) => unit.id != _senderUnit!.id,
            orElse: () => units.first,
          );
          _recipientUnitController.text = _recipientUnit!.name;
        }
      }

      // Update state with new units
      setState(() {
        _allUnits = units;
        _isLoadingUnits = false;
      });

      debugPrint('OutgoingDispatchForm: Units loaded and state updated');
    } catch (e) {
      debugPrint('OutgoingDispatchForm: Error loading units: $e');
      setState(() {
        _isLoadingUnits = false;
      });
    }
  }

  // This is a helper method that will be called when the widget is disposed

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dispatch != null;

    // Initialize UnitManager
    _initializeUnitManager();

    // Subscribe to unit changes
    _unitChangesSubscription = _unitManager.unitChanges.listen((_) {
      debugPrint('OutgoingDispatchForm: Received unit change notification');
      _loadAllUnitsFromManager();
    });

    // Load all units
    _loadAllUnitsFromManager();

    if (_isEditing) {
      // Populate form with existing dispatch data
      _referenceController.text = widget.dispatch!.referenceNumber;
      _subjectController.text = widget.dispatch!.subject;
      _contentController.text = widget.dispatch!.content;
      _recipientController.text =
          widget.dispatch!.recipient; // Person receiving
      _recipientUnitController.text =
          widget.dispatch!.recipientUnit; // Recipient unit
      _sentByController.text = widget
          .dispatch!.recipientUnit; // Sender unit (using recipientUnit for now)
      _deliveredByController.text =
          widget.dispatch!.sentBy; // Person delivering
      _handledByController.text = widget.dispatch!.handledBy; // Person handling

      _dispatchDate = widget.dispatch!.dateTime;
      _sentDate = widget.dispatch!.sentDate;
      _priority = widget.dispatch!.priority;
      _securityClassification = widget.dispatch!.securityClassification;
      _status = widget.dispatch!.status;
      _deliveryMethod = widget.dispatch!.deliveryMethod;
      _attachments = List.from(widget.dispatch!.attachments);

      // Create basic Unit objects for validation
      if (_sentByController.text.isNotEmpty) {
        _senderUnit = Unit(
          id: 'temp_sender_${DateTime.now().millisecondsSinceEpoch}',
          name: _sentByController.text,
          code: _sentByController.text
              .substring(
                  0,
                  _sentByController.text.length > 3
                      ? 3
                      : _sentByController.text.length)
              .toUpperCase(),
        );
      }

      if (_recipientUnitController.text.isNotEmpty) {
        _recipientUnit = Unit(
          id: 'temp_recipient_${DateTime.now().millisecondsSinceEpoch}',
          name: _recipientUnitController.text,
          code: _recipientUnitController.text
              .substring(
                  0,
                  _recipientUnitController.text.length > 3
                      ? 3
                      : _recipientUnitController.text.length)
              .toUpperCase(),
        );
      }
    } else {
      // Set default values for new dispatch
      _referenceController.text =
          'OUT-${DateTime.now().year}-${_generateReferenceNumber()}';

      // Keep delivery details fields empty
      _handledByController.text = '';
      _deliveredByController.text = '';
      _recipientController.text = '';

      // Default sender unit to "Nigerian Army School of Signals"
      _sentByController.text = 'Nigerian Army School of Signals';
      _senderUnit = Unit(
        id: 'temp_sender_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Nigerian Army School of Signals',
        code: 'NAS',
      );
    }
  }

  @override
  void dispose() {
    // Cancel subscription
    _unitChangesSubscription?.cancel();

    // Dispose controllers
    _referenceController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _recipientController.dispose();
    _recipientUnitController.dispose();
    _sentByController.dispose();
    _deliveredByController.dispose();
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

  // Show the add unit dialog - same as in Units Management screen
  void _showAddUnitDialog() {
    showDialog(
      context: context,
      builder: (context) => UnitFormDialog(
        onUnitSaved: _handleUnitSaved,
      ),
    );
  }

  // Handle unit saved callback - same as in Units Management screen
  Future<void> _handleUnitSaved(Unit unit, bool isNew) async {
    if (!mounted) return;

    setState(() {
      _isLoadingUnits = true;
    });

    try {
      debugPrint(
          'OutgoingDispatchForm: Handling unit save: ${unit.name} (${unit.code}), isNew: $isNew');

      bool success = false;
      if (isNew) {
        // Add the unit using UnitManager
        final savedUnit = await _unitManager.addUnit(unit);
        success = savedUnit != null;

        if (success) {
          // Also add to UnitService for compatibility
          await _unitService.addUnit(savedUnit!);

          // Update the unit in our state
          setState(() {
            // Add to all units if not already there
            if (!_allUnits.any((u) => u.id == savedUnit.id)) {
              _allUnits.add(savedUnit);
            }

            // Set as sender or recipient if needed
            if (_senderUnit == null) {
              _senderUnit = savedUnit;
              _sentByController.text = savedUnit.name;
            } else if (_recipientUnit == null) {
              _recipientUnit = savedUnit;
              _recipientUnitController.text = savedUnit.name;
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
              _sentByController.text = unit.name;
            }
            if (_recipientUnit?.id == unit.id) {
              _recipientUnit = unit;
              _recipientUnitController.text = unit.name;
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
      debugPrint('OutgoingDispatchForm: Error in _handleUnitSaved: $e');
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

  // File attachment methods
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        final fileName = file.name;
        final fileSize = (file.size / 1024).toStringAsFixed(2); // Convert to KB
        final fileExtension = fileName.split('.').last.toLowerCase();

        setState(() {
          // Add to attachments list (for compatibility with existing code)
          _attachments.add(fileName);

          // Add detailed information
          _attachmentDetails.add({
            'name': fileName,
            'path': file.path,
            'size': fileSize,
            'extension': fileExtension,
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File attached: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove attachment at specified index
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      _attachmentDetails.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachment removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Get appropriate icon based on file extension
  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return FontAwesomeIcons.filePdf;
      case 'doc':
      case 'docx':
        return FontAwesomeIcons.fileWord;
      case 'xls':
      case 'xlsx':
        return FontAwesomeIcons.fileExcel;
      case 'ppt':
      case 'pptx':
        return FontAwesomeIcons.filePowerpoint;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return FontAwesomeIcons.fileImage;
      case 'txt':
        return FontAwesomeIcons.fileLines;
      case 'zip':
      case 'rar':
        return FontAwesomeIcons.fileZipper;
      default:
        return FontAwesomeIcons.file;
    }
  }

  void _saveDispatch() {
    if (_formKey.currentState!.validate()) {
      // Create sender and recipient units if needed
      if (_sentByController.text.isNotEmpty && _senderUnit == null) {
        _senderUnit = Unit(
          id: 'temp_sender_${DateTime.now().millisecondsSinceEpoch}',
          name: _sentByController.text,
          code: _sentByController.text
              .substring(
                  0,
                  _sentByController.text.length > 3
                      ? 3
                      : _sentByController.text.length)
              .toUpperCase(),
        );
      }

      if (_recipientUnitController.text.isNotEmpty && _recipientUnit == null) {
        _recipientUnit = Unit(
          id: 'temp_recipient_${DateTime.now().millisecondsSinceEpoch}',
          name: _recipientUnitController.text,
          code: _recipientUnitController.text
              .substring(
                  0,
                  _recipientUnitController.text.length > 3
                      ? 3
                      : _recipientUnitController.text.length)
              .toUpperCase(),
        );
      }

      // Validate that units are set
      if (_senderUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a sender unit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_recipientUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a recipient unit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
        recipient: _recipientController.text, // Person receiving
        recipientUnit: _recipientUnit!.name, // Recipient unit name
        sentBy: _deliveredByController.text, // Person delivering
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

                // New Sender and Recipient Card
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

                        // From (Sender Unit) - Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'From (Sender Unit)',
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

                            // Sender Unit Dropdown
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
                                    contentPadding: const EdgeInsets.symmetric(
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
                                        _sentByController.text = newValue.name;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // To (Recipient Unit) - Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'To (Recipient Unit)',
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

                            // Recipient Unit Dropdown
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
                                        _recipientUnitController.text =
                                            newValue.name;
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                        FontAwesomeIcons.circlePlus,
                                        size: 16),
                                    label: const Text('Add New Unit'),
                                    onPressed: _showAddUnitDialog,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                  ),

                                  // Refresh Button - DIRECT DROPDOWN UPDATE
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh Units'),
                                    onPressed: () {
                                      // Show loading indicator
                                      setState(() {
                                        _isLoadingUnits = true;
                                      });

                                      // Get units from both services to ensure we have the latest data
                                      _unitService.getAllUnits().then((units) {
                                        if (mounted) {
                                          // Update the units list
                                          setState(() {
                                            _allUnits = units;

                                            // Reset sender and recipient units to ensure we're using the latest data
                                            _senderUnit = null;
                                            _recipientUnit = null;

                                            // If we have units, select appropriate ones
                                            if (units.isNotEmpty) {
                                              // Select primary unit as sender
                                              _senderUnit = units.firstWhere(
                                                (unit) => unit.isPrimary,
                                                orElse: () => units.first,
                                              );
                                              _sentByController.text =
                                                  _senderUnit!.name;

                                              // If we have more than one unit, select a different one as recipient
                                              if (units.length > 1) {
                                                _recipientUnit =
                                                    units.firstWhere(
                                                  (unit) =>
                                                      unit.id !=
                                                      _senderUnit!.id,
                                                  orElse: () => units.first,
                                                );
                                                _recipientUnitController.text =
                                                    _recipientUnit!.name;
                                              }
                                            }

                                            _isLoadingUnits = false;
                                          });

                                          // Show success message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Units refreshed (${units.length} units)'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }).catchError((e) {
                                        if (mounted) {
                                          setState(() {
                                            _isLoadingUnits = false;
                                          });

                                          // Show error message
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Error refreshing units: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green,
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

                        // 8. Delivered By Person
                        TextFormField(
                          controller: _deliveredByController,
                          decoration: InputDecoration(
                            labelText: 'Delivered By (Person)',
                            hintText: 'Enter name of person delivering',
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

                        // 9. Received By Person
                        TextFormField(
                          controller: _recipientController,
                          decoration: InputDecoration(
                            labelText: 'Received By (Person)',
                            hintText: 'Enter name of person receiving',
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
                            onPressed: _pickFile,
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

                        // Display attachments
                        if (_attachmentDetails.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Attached Files:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _attachmentDetails.length,
                            itemBuilder: (context, index) {
                              final attachment = _attachmentDetails[index];
                              return ListTile(
                                leading: Icon(
                                  _getFileIcon(attachment['extension']),
                                  color: AppTheme.primaryColor,
                                ),
                                title: Text(attachment['name']),
                                subtitle: Text('${attachment['size']} KB'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeAttachment(index),
                                ),
                                dense: true,
                              );
                            },
                          ),
                        ],
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
