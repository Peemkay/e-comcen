import 'package:flutter/material.dart';
import 'package:nasds/widgets/lock_icon_button.dart';

/// Utility functions for app bars
class AppBarUtils {
  /// Adds standard actions to an app bar, including the lock icon
  /// 
  /// [existingActions] - Any existing actions to include
  /// [includeBackButton] - Whether to include a back button (defaults to false)
  /// [onBackPressed] - Custom back button handler (optional)
  static List<Widget> getStandardActions({
    List<Widget>? existingActions,
    bool includeBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    final List<Widget> actions = [];
    
    // Add back button if requested
    if (includeBackButton) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => Navigator.of(navigatorKey.currentContext!).pop(),
        ),
      );
    }
    
    // Add existing actions if provided
    if (existingActions != null && existingActions.isNotEmpty) {
      actions.addAll(existingActions);
    }
    
    // Always add the lock icon button
    actions.add(const LockIconButton());
    
    return actions;
  }
  
  // Global navigator key for accessing context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
