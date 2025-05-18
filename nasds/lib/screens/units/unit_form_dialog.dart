import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/unit.dart';
import '../../services/unit_service.dart';

typedef UnitCallback = Future<void> Function(Unit unit, bool isNew);

class UnitFormDialog extends StatefulWidget {
  final Unit? unit;
  final UnitCallback onUnitSaved;

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
  UnitType _selectedUnitType = UnitType.other;
  bool _isLoading = false;
  bool _isCheckingCode = false;
  bool _codeExists = false;
  bool _isPrimary = false;
  final UnitService _unitService = UnitService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.unit != null) {
      _nameController.text = widget.unit!.name;
      _codeController.text = widget.unit!.code;
      _locationController.text = widget.unit!.location ?? '';
      _descriptionController.text = widget.unit!.description ?? '';
      _selectedUnitType = widget.unit!.unitType;
      _isPrimary = widget.unit!.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkCodeExists(String code) async {
    if (code.isEmpty) return;

    // Skip check if editing and code hasn't changed
    if (widget.unit != null && widget.unit!.code == code) {
      setState(() {
        _isCheckingCode = false;
        _codeExists = false;
      });
      return;
    }

    setState(() {
      _isCheckingCode = true;
    });

    try {
      final existingUnit = await _unitService.findUnitByCode(code);

      if (mounted) {
        setState(() {
          _codeExists = existingUnit != null;
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

  Future<void> _saveUnit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final isNew = widget.unit == null;

      final unit = Unit(
        id: widget.unit?.id ?? '',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        location: _locationController.text.trim(),
        unitType: _selectedUnitType,
        description: _descriptionController.text.trim(),
        isPrimary: _isPrimary,
        createdAt: widget.unit?.createdAt,
        updatedAt: DateTime.now(),
      );

      await widget.onUnitSaved(unit, isNew);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving unit: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Unit' : 'Add New Unit',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Name',
                    hintText: 'Enter full unit name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a unit name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Unit code field
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Unit Code',
                    hintText: 'Enter unit code/formation code',
                    prefixIcon: const Icon(Icons.code),
                    suffixIcon: _isCheckingCode
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : _codeExists
                            ? const Icon(Icons.error, color: Colors.red)
                            : null,
                    helperText: _codeExists
                        ? 'This code is already in use'
                        : 'Short code for the unit (e.g., NASS, 521SR)',
                    helperStyle: TextStyle(
                      color: _codeExists ? Colors.red : null,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a unit code';
                    }
                    if (_codeExists) {
                      return 'This code is already in use by another unit';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _checkCodeExists(value);
                  },
                ),
                const SizedBox(height: 16),

                // Unit type dropdown
                DropdownButtonFormField<UnitType>(
                  value: _selectedUnitType,
                  decoration: const InputDecoration(
                    labelText: 'Unit Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: UnitType.values.map((type) {
                    String label;
                    IconData icon;

                    switch (type) {
                      case UnitType.forwardLink:
                        label = 'Forward Link';
                        icon = Icons.arrow_upward;
                        break;
                      case UnitType.rearLink:
                        label = 'Rear Link';
                        icon = Icons.arrow_downward;
                        break;
                      case UnitType.headquarters:
                        label = 'Headquarters';
                        icon = Icons.location_city;
                        break;
                      case UnitType.other:
                        label = 'Other';
                        icon = Icons.more_horiz;
                        break;
                    }

                    return DropdownMenuItem<UnitType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(icon, size: 18),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
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
                const SizedBox(height: 16),

                // Location field
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Enter unit location (optional)',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter unit description (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Primary unit toggle
                SwitchListTile(
                  title: const Text(
                    'Set as Primary Unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Primary unit will be used as the default unit on reports',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  value: _isPrimary,
                  onChanged: (value) {
                    setState(() {
                      _isPrimary = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUnit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
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
