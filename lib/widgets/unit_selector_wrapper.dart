import 'package:flutter/material.dart';
import '../models/unit.dart';
import 'unit_selector_updated.dart';

/// This is a compatibility wrapper for the UnitSelectorUpdated widget
/// It exists to maintain backward compatibility with code that still uses UnitSelector
///
/// @deprecated Use UnitSelectorUpdated instead
class UnitSelector extends StatelessWidget {
  final String? selectedUnitId;
  final Function(Unit) onUnitSelected;
  final String label;
  final bool isRequired;
  final bool allowAddNew;
  final UnitType? filterByType;

  const UnitSelector({
    super.key,
    this.selectedUnitId,
    required this.onUnitSelected,
    required this.label,
    this.isRequired = false,
    this.allowAddNew = true,
    this.filterByType,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('UnitSelector: Using compatibility wrapper');
    // Simply delegate to the updated widget
    return UnitSelectorUpdated(
      selectedUnitId: selectedUnitId,
      onUnitSelected: onUnitSelected,
      label: label,
      isRequired: isRequired,
      allowAddNew: allowAddNew,
      filterByType: filterByType,
    );
  }
}
