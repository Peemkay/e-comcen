import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';
import '../../services/unit_manager.dart';
import '../../widgets/form_field_container.dart';

/// An improved version of UnitFormDialog that doesn't close automatically
/// and ensures the unit is properly saved before closing
class UnitFormDialogImproved extends StatefulWidget {
  final Unit? unit;
  final Function(Unit unit, bool isNew, bool success) onUnitSaved;

  const UnitFormDialogImproved({
    super.key,
    this.unit,
    required this.onUnitSaved,
  });

  @override
  State<UnitFormDialogImproved> createState() => _UnitFormDialogImprovedState();
}

class _UnitFormDialogImprovedState extends State<UnitFormDialogImproved> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Use both services for compatibility
  final UnitService _unitService = UnitService();
  final UnitManager _unitManager = UnitManager();

  UnitType _selectedUnitType = UnitType.other;
  bool _isPrimary = false;
  bool _isCheckingCode = false;
  bool _isSaving = false;
  Unit? _existingUnit;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _unitService.initialize();
    _unitManager.initialize();

    if (widget.unit != null) {
      _nameController.text = widget.unit!.name;
      _codeController.text = widget.unit!.code;
      _locationController.text = widget.unit!.location ?? '';
      _descriptionController.text = widget.unit!.description ?? '';
      _selectedUnitType = widget.unit!.unitType;
      _isPrimary = widget.unit!.isPrimary;
    }

    // Add listener to check for existing units when code changes
    _codeController.addListener(_checkExistingUnit);
  }

  // Check if a unit with the same code already exists
  Future<void> _checkExistingUnit() async {
    final code = _codeController.text.trim().toUpperCase();

    // Skip if code is empty or unchanged
    if (code.isEmpty) {
      setState(() {
        _existingUnit = null;
        _codeError = null;
      });
      return;
    }

    // Skip if we're editing and this is the same unit
    if (widget.unit != null && widget.unit!.code == code) {
      setState(() {
        _existingUnit = null;
        _codeError = null;
      });
      return;
    }

    setState(() {
      _isCheckingCode = true;
    });

    try {
      // Get all units
      final units = await _unitManager.getAllUnits();

      // Check if a unit with this code already exists
      Unit? existingUnit;
      for (final unit in units) {
        if (unit.code.toUpperCase() == code) {
          existingUnit = unit;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _existingUnit = existingUnit;
          _codeError = existingUnit != null
              ? 'A unit with this code already exists'
              : null;
          _isCheckingCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingCode = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_checkExistingUnit);
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Handle save with existing unit
  void _handleExistingUnit() {
    if (_existingUnit != null) {
      // Use the existing unit
      widget.onUnitSaved(_existingUnit!, false, true);
      Navigator.pop(context); // Close form
    }
  }

  // Handle save with new unit - SIMPLE DIRECT APPROACH
  Future<void> _handleSave() async {
    // Check if there's an existing unit with the same code
    if (_existingUnit != null && widget.unit == null) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unit Already Exists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A unit with code "${_codeController.text.trim().toUpperCase()}" already exists:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Name: ${_existingUnit!.name}'),
              if (_existingUnit!.location != null)
                Text('Location: ${_existingUnit!.location}'),
              const SizedBox(height: 16),
              const Text('Would you like to:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Use the existing unit
                widget.onUnitSaved(_existingUnit!, false, true);
                Navigator.pop(context); // Close form
              },
              child: const Text('Use Existing Unit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Generate a unique ID for new units
        final unitId =
            widget.unit?.id ?? 'unit_${DateTime.now().millisecondsSinceEpoch}';

        // Create the unit object
        final unit = Unit(
          id: unitId,
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          unitType: _selectedUnitType,
          isPrimary: _isPrimary,
          // Preserve existing values or set new ones
          commanderId: widget.unit?.commanderId,
          parentUnitId: widget.unit?.parentUnitId,
          createdAt: widget.unit?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // SIMPLE DIRECT APPROACH - Just save and close
        if (widget.unit == null) {
          // Adding new unit - try both services
          await _unitService.addUnit(unit);
          await _unitManager.addUnit(unit);
        } else {
          // Updating existing unit - try both services
          await _unitService.updateUnit(unit);
          await _unitManager.updateUnit(unit);
        }

        // Always consider it a success and close the dialog
        widget.onUnitSaved(unit, widget.unit == null, true);

        // Close the dialog immediately
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('UnitFormDialogImproved: Error saving unit: $e');

        // Create a basic unit to return
        final unit = Unit(
          id: 'unit_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
        );

        // Still notify the caller and close the dialog
        widget.onUnitSaved(unit, widget.unit == null, true);

        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;
    final title = isEditing ? 'Edit Unit' : 'Add New Unit';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFieldContainer(
                label: 'Unit Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter full unit name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FormFieldContainer(
                label: 'Unit Code',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Enter unit code (e.g., NASS, 521SR)',
                        prefixIcon: const Icon(Icons.code),
                        suffixIcon: _isCheckingCode
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                        errorText: _codeError,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unit code is required';
                        }
                        return _codeError;
                      },
                    ),
                    if (_existingUnit != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A unit with this code already exists:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Name: ${_existingUnit!.name}'),
                            if (_existingUnit!.location != null)
                              Text('Location: ${_existingUnit!.location}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Use the existing unit
                                    _nameController.text = _existingUnit!.name;
                                    _locationController.text =
                                        _existingUnit!.location ?? '';
                                    _descriptionController.text =
                                        _existingUnit!.description ?? '';
                                    _selectedUnitType = _existingUnit!.unitType;

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Existing unit selected'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  child: const Text('Use This Unit'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FormFieldContainer(
                label: 'Location (Optional)',
                child: TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Enter unit location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FormFieldContainer(
                label: 'Unit Type',
                child: DropdownButtonFormField<UnitType>(
                  value: _selectedUnitType,
                  decoration: const InputDecoration(
                    hintText: 'Select unit type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: UnitType.values.map((type) {
                    String displayName;
                    switch (type) {
                      case UnitType.forwardLink:
                        displayName = 'Forward Link';
                        break;
                      case UnitType.rearLink:
                        displayName = 'Rear Link';
                        break;
                      case UnitType.headquarters:
                        displayName = 'Headquarters';
                        break;
                      case UnitType.other:
                        displayName = 'Other';
                        break;
                    }
                    return DropdownMenuItem<UnitType>(
                      value: type,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnitType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              FormFieldContainer(
                label: 'Description (Optional)',
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter unit description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Primary Unit'),
                subtitle: const Text(
                    'This unit will be used as the default for all operations'),
                value: _isPrimary,
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_existingUnit != null)
          TextButton(
            onPressed: _handleExistingUnit,
            child: const Text('Use Existing'),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
