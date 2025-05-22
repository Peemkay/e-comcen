import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../services/dispatch_service.dart';

class ComcenLogForm extends StatefulWidget {
  final DispatchLog? log;

  const ComcenLogForm({super.key, this.log});

  @override
  State<ComcenLogForm> createState() => _ComcenLogFormState();
}

class _ComcenLogFormState extends State<ComcenLogForm> {
  final _formKey = GlobalKey<FormState>();
  final DispatchService _dispatchService = DispatchService();

  // Form controllers
  final _actionController = TextEditingController();
  final _performedByController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  DateTime _timestamp = DateTime.now();

  // Action types for dropdown
  final List<String> _actionTypes = [
    'Created',
    'Received',
    'Processed',
    'Forwarded',
    'Sent',
    'Delivered',
    'Acknowledged',
    'Completed',
    'Delayed',
    'Failed',
    'Returned',
    'System Maintenance',
    'Security Audit',
    'Communication Check',
    'Communication Link Status',
    'Network Status',
    'Other'
  ];

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isCustomAction = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.log != null;

    if (_isEditing) {
      // Populate form with existing log data
      _actionController.text = widget.log!.action;
      _performedByController.text = widget.log!.performedBy;
      _notesController.text = widget.log!.notes;
      _timestamp = widget.log!.timestamp;

      // Check if action is in the predefined list
      _isCustomAction = !_actionTypes.contains(widget.log!.action);
    } else {
      // Set default values for new log
      _performedByController.text = 'Admin'; // Default to current user
    }
  }

  @override
  void dispose() {
    _actionController.dispose();
    _performedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Simplified approach to avoid BuildContext issues
  void _selectTimestamp(BuildContext context) {
    // Show date picker
    _pickDate(context);
  }

  // Pick date and time in sequence
  Future<void> _pickDate(BuildContext context) async {
    // Use a separate method for showing time picker to avoid async gap issues
    Future<void> showTimePickerAndUpdate(DateTime pickedDate) async {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_timestamp),
      );

      if (pickedTime == null || !mounted) return;

      setState(() {
        _timestamp = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }

    try {
      // Show date picker
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _timestamp,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );

      // If date picker was cancelled or widget is unmounted, return
      if (pickedDate == null || !mounted) return;

      // Show time picker in a separate method
      await showTimePickerAndUpdate(pickedDate);
    } catch (e) {
      // Handle any errors
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error selecting date/time: $e')),
        );
      }
    }
  }

  void _saveLog() {
    if (_formKey.currentState!.validate()) {
      // Store context and scaffold messenger before async operations
      final currentContext = context;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      setState(() {
        _isLoading = true;
      });

      // Get action text (either from dropdown or custom input)
      final String action = _isCustomAction
          ? _actionController.text
          : _actionController.text.isEmpty
              ? 'Other'
              : _actionController.text;

      // Create log object
      final log = DispatchLog(
        id: _isEditing
            ? widget.log!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: _timestamp,
        action: action,
        performedBy: _performedByController.text,
        notes: _notesController.text,
      );

      // Save to service (we'll add this method to DispatchService)
      if (_isEditing) {
        // Update log logic will be added to service
        _dispatchService.updateComcenLog(log);
      } else {
        // Add log logic will be added to service
        _dispatchService.addComcenLog(log);
      }

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success message and navigate back
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Log updated successfully'
              : 'Log added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(currentContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit COMCEN Log' : 'New COMCEN Log'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp
              InkWell(
                onTap: () => _selectTimestamp(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Timestamp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.clock, size: 16),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy HH:mm').format(_timestamp),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Type
              if (!_isCustomAction) ...[
                DropdownButtonFormField<String>(
                  value: _actionTypes.contains(_actionController.text)
                      ? _actionController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Action Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.listCheck, size: 16),
                  ),
                  hint: const Text('Select an action type'),
                  items: [
                    ..._actionTypes.map((String action) {
                      return DropdownMenuItem<String>(
                        value: action,
                        child: Text(action),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue == 'Other') {
                        _isCustomAction = true;
                        _actionController.text = '';
                      } else {
                        _actionController.text = newValue!;
                      }
                    });
                  },
                  validator: (value) {
                    if (!_isCustomAction && (value == null || value.isEmpty)) {
                      return 'Please select an action type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCustomAction = true;
                        _actionController.text = '';
                      });
                    },
                    icon: const Icon(FontAwesomeIcons.pen, size: 14),
                    label: const Text('Custom Action'),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Action',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(FontAwesomeIcons.pen, size: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an action';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCustomAction = false;
                        _actionController.text = '';
                      });
                    },
                    icon: const Icon(FontAwesomeIcons.listCheck, size: 14),
                    label: const Text('Use Predefined Action'),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Performed By
              TextFormField(
                controller: _performedByController,
                decoration: const InputDecoration(
                  labelText: 'Performed By',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(FontAwesomeIcons.userGear, size: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter who performed this action';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(FontAwesomeIcons.noteSticky, size: 16),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Update Log' : 'Save Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
