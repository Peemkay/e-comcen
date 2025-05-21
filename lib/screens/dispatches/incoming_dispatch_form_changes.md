# Changes to be made to incoming_dispatch_form.dart

## 1. Move "Delivered By" field from Delivery Information section to Receiving Information section

In the Receiving Information section, add the "Delivered By" field before the "Handled By" field:

```dart
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

const SizedBox(height: 16),
```

## 2. Remove "Delivered By" field from the mobile layout in Delivery Information section

Replace:
```dart
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
```

With:
```dart
// Delivered By field moved to Receiving Information section
```

## 3. Keep only one "Add New Unit" button in the sender section

The "Add New Unit" button should only appear once in the Delivery Information section, specifically in the ADDR TO section.

## 4. Fix the _showAddUnitDialog method to properly update the UI when a new unit is added

```dart
// Show dialog to add a new unit
void _showAddUnitDialog() {
  showDialog(
    context: context,
    builder: (context) => UnitFormDialog(
      onUnitSaved: (unit, isNew) async {
        // Show loading indicator
        setState(() {
          _isLoadingUnits = true;
        });
        
        try {
          // Add or update the unit in both services for compatibility
          if (isNew) {
            // Add to UnitManager
            final savedUnit = await _unitManager.addUnit(unit);
            if (savedUnit != null) {
              // Also add to UnitService
              await _unitService.addUnit(savedUnit);
              
              // Update local state
              setState(() {
                if (!_allUnits.any((u) => u.id == savedUnit.id)) {
                  _allUnits.add(savedUnit);
                }
              });
            }
          } else {
            // Update in UnitManager
            await _unitManager.updateUnit(unit);
            // Also update in UnitService
            await _unitService.updateUnit(unit);
            
            // Update local state
            setState(() {
              final index = _allUnits.indexWhere((u) => u.id == unit.id);
              if (index >= 0) {
                _allUnits[index] = unit;
              } else {
                _allUnits.add(unit);
              }
            });
          }
          
          // Reload all units to ensure we have the latest data
          _loadUnits();
          
          // Show success message
          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Unit saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error saving unit: $e');
          // Show error message
          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Error saving unit: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          // Hide loading indicator
          if (mounted) {
            setState(() {
              _isLoadingUnits = false;
            });
          }
        }
      },
    ),
  );
}
```
