import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'notifications/notification_badge.dart';
import 'dispatch_tracking_dialog.dart';
import 'lock_icon_button.dart';

/// An enhanced app bar with modern design and comprehensive features
/// including logo, responsive title, notification badge, user profile,
/// search functionality, and help menu.
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotificationBadge;
  final bool showLogo;
  final bool showUserProfile;
  final bool showSearchButton;
  final bool showHelpButton;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onProfileTap;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;

  const EnhancedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotificationBadge = true,
    this.showLogo = true,
    this.showUserProfile = true,
    this.showSearchButton = true,
    this.showHelpButton = true,
    this.onNotificationTap,
    this.onSearchTap,
    this.onHelpTap,
    this.onProfileTap,
    this.leading,
    this.bottom,
    this.elevation = 2.0,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final authService = AuthService();
    final currentUser = authService.currentUser;

    // Create actions list
    final List<Widget> actionWidgets = [];

    // Add search button if enabled
    if (showSearchButton) {
      actionWidgets.add(
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
          tooltip: 'Search',
          onPressed: onSearchTap ??
              () {
                showDialog(
                  context: context,
                  builder: (context) => const DispatchTrackingDialog(),
                );
              },
        ),
      );
    }

    // Add notification badge if enabled
    if (showNotificationBadge) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: NotificationBadge(
            onTap: onNotificationTap ??
                () {
                  Navigator.pushNamed(context, '/notifications');
                },
            size: 20.0,
            badgeColor: AppTheme.accentColor,
            child: const FaIcon(FontAwesomeIcons.bell, size: 18),
          ),
        ),
      );
    }

    // Add help button if enabled
    if (showHelpButton) {
      actionWidgets.add(
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.circleQuestion, size: 18),
          tooltip: 'Help',
          onPressed: onHelpTap ??
              () {
                _showHelpMenu(context);
              },
        ),
      );
    }

    // Add lock screen button
    actionWidgets.add(
      const LockIconButton(),
    );

    // Add user profile if enabled
    if (showUserProfile && currentUser != null) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 4.0),
          child: _buildUserProfileButton(context, currentUser),
        ),
      );
    }

    // Add other actions
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return AppBar(
      title: showLogo
          ? _buildTitleWithLogo(context, title, isSmallScreen)
          : Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: Colors.white,
      leading: leading,
      actions: actionWidgets,
      bottom: bottom,
      toolbarHeight: isSmallScreen ? kToolbarHeight : kToolbarHeight * 1.2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  // Build title with logo
  Widget _buildTitleWithLogo(
      BuildContext context, String title, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        Container(
          height: isSmallScreen ? 32 : 36,
          width: isSmallScreen ? 32 : 36,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppConstants.logoPath,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Title
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 18 : 20,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build user profile button
  Widget _buildUserProfileButton(BuildContext context, User user) {
    final String initials = _getInitials(user.name);

    return InkWell(
      onTap: onProfileTap ??
          () {
            _showUserProfileMenu(context);
          },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User avatar
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  // Show user profile menu
  void _showUserProfileMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem<String>(
          value: 'profile',
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.userShield, size: 18),
            title: Text('My Profile'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/profile');
            });
          },
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.gear, size: 18),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/settings');
            });
          },
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.rightFromBracket,
                size: 18, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              AuthService().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            });
          },
        ),
      ],
    );
  }

  // Show help menu
  void _showHelpMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.circleInfo, size: 18),
            title: Text('User Guide'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/help/guide');
            });
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.video, size: 18),
            title: Text('Video Tutorials'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/help/tutorials');
            });
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.headset, size: 18),
            title: Text('Contact Support'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/help/support');
            });
          },
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const ListTile(
            leading: FaIcon(FontAwesomeIcons.circleInfo, size: 18),
            title: Text('About'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pushNamed(context, '/about');
            });
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
