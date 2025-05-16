import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_theme.dart';
import '../providers/security_provider.dart';
import 'notifications/notification_badge.dart';

/// Custom app bar with notification badge and lock screen icon
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotificationBadge;
  final bool showLockIcon;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLockTap;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotificationBadge = true,
    this.showLockIcon = true,
    this.onNotificationTap,
    this.onLockTap,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // Create actions list with notification badge and lock icon
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

    // Add lock screen icon if enabled
    if (showLockIcon) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.lock, size: 18),
            tooltip: 'Lock Screen',
            onPressed: onLockTap ??
                () {
                  // Get the security provider and lock the screen
                  final securityProvider =
                      Provider.of<SecurityProvider>(context, listen: false);
                  securityProvider.lockApplication(context);
                },
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
