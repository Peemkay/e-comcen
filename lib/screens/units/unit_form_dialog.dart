import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';
import '../../widgets/form_field_container.dart';

class UnitFormDialog extends StatefulWidget {
  final Unit? unit;
  final Function(Unit unit, bool isNew) onUnitSaved;

  const UnitFormDialog({
    super.key,
    this.unit,
    required this.onUnitSaved,
  });

  @override
  State<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final UnitService _unitService = UnitService();

  UnitType _selectedUnitType = UnitType.other;
  bool _isPrimary = false;
  bool _isCheckingCode = false;
  Unit? _existingUnit;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _unitService.initialize();

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
      final units = await _unitService.getAllUnits();

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

  void _handleSave() {
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
                widget.onUnitSaved(_existingUnit!, false);
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
      final unit = Unit(
        id: widget.unit?.id ?? '',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        unitType: _selectedUnitType,
        isPrimary: _isPrimary,
        // Preserve existing values
        commanderId: widget.unit?.commanderId,
        parentUnitId: widget.unit?.parentUnitId,
        createdAt: widget.unit?.createdAt,
        updatedAt: DateTime.now(),
      );

      widget.onUnitSaved(unit, widget.unit == null);
      Navigator.pop(context);
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
                      onChanged: (value) {
                        // Auto-convert to uppercase
                        if (value != value.toUpperCase()) {
                          _codeController.value = TextEditingValue(
                            text: value.toUpperCase(),
                            selection: _codeController.selection,
                          );
                        }
                      },
                    ),
                    if (_existingUnit != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Unit with code "${_existingUnit!.code}" already exists:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _existingUnit!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_existingUnit!.location != null &&
                                _existingUnit!.location!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Location: ${_existingUnit!.location}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
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
                label: 'Location',
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
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
