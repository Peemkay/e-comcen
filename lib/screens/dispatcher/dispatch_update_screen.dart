import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/dispatch.dart';
import '../../models/dispatch_tracking.dart';
import '../../providers/dispatcher_provider.dart';

class DispatchUpdateScreen extends StatefulWidget {
  final Dispatch dispatch;

  const DispatchUpdateScreen({
    super.key,
    required this.dispatch,
  });

  @override
  State<DispatchUpdateScreen> createState() => _DispatchUpdateScreenState();
}

class _DispatchUpdateScreenState extends State<DispatchUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverRankController = TextEditingController();
  final _receiverIdController = TextEditingController();

  DispatchStatus _selectedStatus = DispatchStatus.inProgress;
  bool _isDelivered = false;

  @override
  void initState() {
    super.initState();

    // Set initial status based on current dispatch status
    try {
      _selectedStatus = DispatchStatus.fromString(widget.dispatch.status);
    } catch (e) {
      // Default to in progress if status can't be parsed
      _selectedStatus = DispatchStatus.inProgress;
    }

    // Set initial location
    if (widget.dispatch.currentLocation != null) {
      _locationController.text = widget.dispatch.currentLocation!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    _receiverNameController.dispose();
    _receiverRankController.dispose();
    _receiverIdController.dispose();
    super.dispose();
  }

  void _updateDispatch() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // If delivered, make sure receiver details are provided
    if (_isDelivered) {
      if (_receiverNameController.text.isEmpty ||
          _receiverRankController.text.isEmpty ||
          _receiverIdController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide receiver details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Update dispatch status
    Provider.of<DispatcherProvider>(context, listen: false)
        .completeDispatch(
      widget.dispatch.referenceNumber,
      _selectedStatus,
      _notesController.text,
      _locationController.text,
    )
        .then((success) {
      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update dispatch status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Dispatch Status'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dispatch details card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.dispatch
                                  .getPriorityColor()
                                  .withAlpha(25), // 0.1 * 255 = 25
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.dispatch.getPriorityIcon(),
                              color: widget.dispatch.getPriorityColor(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.dispatch.subject,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Ref: ${widget.dispatch.referenceNumber}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.dispatch.sender,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.dispatch.recipient,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Status',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.dispatch.status,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.dispatch.getStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Priority',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  widget.dispatch.priority,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.dispatch.getPriorityColor(),
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

              // Status update section
              const Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Status selection
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select New Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status options
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip(DispatchStatus.inProgress),
                          _buildStatusChip(DispatchStatus.dispatched),
                          _buildStatusChip(DispatchStatus.inTransit),
                          _buildStatusChip(DispatchStatus.delivered),
                          _buildStatusChip(DispatchStatus.received),
                          _buildStatusChip(DispatchStatus.completed),
                          _buildStatusChip(DispatchStatus.returned),
                          _buildStatusChip(DispatchStatus.failed),
                          _buildStatusChip(DispatchStatus.rejected),
                          _buildStatusChip(DispatchStatus.delayed),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Current location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Current Location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current location';
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
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Delivery confirmation section (only shown for delivered status)
              if (_selectedStatus == DispatchStatus.delivered ||
                  _selectedStatus == DispatchStatus.received ||
                  _selectedStatus == DispatchStatus.completed) ...[
                Row(
                  children: [
                    Checkbox(
                      value: _isDelivered,
                      onChanged: (value) {
                        setState(() {
                          _isDelivered = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text(
                      'Confirm Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isDelivered) ...[
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Receiver Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Receiver name
                          TextFormField(
                            controller: _receiverNameController,
                            decoration: const InputDecoration(
                              labelText: 'Receiver Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (_isDelivered &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter receiver name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Receiver rank
                          TextFormField(
                            controller: _receiverRankController,
                            decoration: const InputDecoration(
                              labelText: 'Receiver Rank',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.military_tech),
                            ),
                            validator: (value) {
                              if (_isDelivered &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter receiver rank';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Receiver ID
                          TextFormField(
                            controller: _receiverIdController,
                            decoration: const InputDecoration(
                              labelText: 'Receiver ID/Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                            validator: (value) {
                              if (_isDelivered &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter receiver ID';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _updateDispatch,
                  icon: const Icon(FontAwesomeIcons.floppyDisk),
                  label: const Text('Update Dispatch Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(DispatchStatus status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(status.label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      avatar: Icon(
        status.icon,
        size: 16,
        color: isSelected ? Colors.white : status.color,
      ),
      backgroundColor: Colors.grey[200],
      selectedColor: status.color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
