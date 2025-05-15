import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'notifications/notification_badge.dart';
import 'dispatch_tracking_dialog.dart';

/// Enhanced custom app bar with modern design and comprehensive features
/// including logo, responsive title, notification badge, user profile,
/// search functionality, and help menu.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotificationBadge;
  final VoidCallback? onNotificationTap;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotificationBadge = true,
    this.onNotificationTap,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Create actions list with notification badge
    final List<Widget> actionWidgets = [];

    // Add notification badge if enabled
    if (showNotificationBadge) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: NotificationBadge(
            onTap: onNotificationTap ??
                () {
                  Navigator.pushNamed(context, '/notifications');
                },
            child: const Icon(Icons.notifications),
          ),
        ),
      );
    }

    // Add other actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return AppBar(
      title: Text(title),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actionWidgets,
      bottom: bottom,
      elevation: 4.0,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
