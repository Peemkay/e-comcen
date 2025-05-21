import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/unit.dart';
import '../../widgets/form_field_container.dart';

/// A simplified version of the unit form dialog that doesn't perform any database operations
/// It just collects the unit information and returns it to the caller
class SimpleUnitFormDialog extends StatefulWidget {
  final Unit? unit;

  const SimpleUnitFormDialog({
    super.key,
    this.unit,
  });

  @override
  State<SimpleUnitFormDialog> createState() => _SimpleUnitFormDialogState();
}

class _SimpleUnitFormDialogState extends State<SimpleUnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  UnitType _selectedUnitType = UnitType.other;
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

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

  void _handleSave() {
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

        // Return the unit to the caller
        Navigator.pop(context, unit);
      } catch (e) {
        debugPrint('SimpleUnitFormDialog: Error creating unit: $e');
        
        // Reset the saving state
        setState(() {
          _isSaving = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                child: TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'Enter unit code (e.g., NASS, 521SR)',
                    prefixIcon: Icon(Icons.code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unit code is required';
                    }
                    return null;
                  },
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
