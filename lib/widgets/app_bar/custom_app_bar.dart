import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../lock_icon_button.dart';

/// Custom app bar with consistent styling for the application
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.leading,
    this.bottom,
    this.elevation = 4.0,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : leading,
      actions: _buildActions(context),
      bottom: bottom,
    );
  }

  // Build actions list with lock icon
  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actionWidgets = [];

    // Add lock screen button
    actionWidgets.add(const LockIconButton());

    // Add other actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
