import 'package:flutter/material.dart';
import '../utils/responsive_layout_util.dart';
import '../constants/app_theme.dart';

/// A responsive scaffold optimized for desktop views.
///
/// This scaffold provides a layout that adapts to different screen sizes,
/// with special optimizations for desktop views including:
/// - Optional persistent navigation drawer
/// - Optional side panel
/// - Responsive content area
/// - Desktop-optimized app bar
class DesktopResponsiveScaffold extends StatelessWidget {
  /// The app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// The primary content of the scaffold.
  final Widget body;

  /// Optional drawer that can be opened from the left side.
  final Widget? drawer;

  /// Optional persistent navigation rail for desktop views.
  final Widget? navigationRail;

  /// Optional side panel for desktop views (typically used for details or filters).
  final Widget? sidePanel;

  /// Width of the side panel when visible.
  final double sidePanelWidth;

  /// Width of the navigation rail when visible.
  final double navigationRailWidth;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Background color of the scaffold.
  final Color? backgroundColor;

  /// Whether to show the drawer on desktop views.
  final bool showDrawerOnDesktop;

  /// Whether to show the side panel.
  final bool showSidePanel;

  /// Creates a responsive scaffold optimized for desktop views.
  const DesktopResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.navigationRail,
    this.sidePanel,
    this.sidePanelWidth = 300,
    this.navigationRailWidth = 72,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.showDrawerOnDesktop = false,
    this.showSidePanel = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on a desktop device
    final isDesktopView = ResponsiveLayoutUtil.isAnyDesktop(context);

    // For desktop views, we use a row layout with optional navigation rail and side panel
    if (isDesktopView) {
      return Scaffold(
        appBar: appBar,
        drawer: showDrawerOnDesktop ? null : drawer,
        backgroundColor: backgroundColor,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional navigation rail for desktop
            if (navigationRail != null && showDrawerOnDesktop)
              SizedBox(
                width: navigationRailWidth,
                child: navigationRail!,
              ),

            // Main content area (expanded to fill available space)
            Expanded(
              child: body,
            ),

            // Optional side panel for details or filters
            if (sidePanel != null && showSidePanel)
              Container(
                width: sidePanelWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  color: Theme.of(context).cardColor,
                ),
                child: sidePanel!,
              ),
          ],
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    // For mobile and tablet views, we use a standard scaffold
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
  }
}

/// A desktop-optimized app bar with responsive sizing and spacing.
class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar.
  final Widget title;

  /// Optional leading widget.
  final Widget? leading;

  /// Optional list of action widgets.
  final List<Widget>? actions;

  /// Background color of the app bar.
  final Color? backgroundColor;

  /// Elevation of the app bar.
  final double? elevation;

  /// Whether to center the title.
  final bool centerTitle;

  /// Creates a desktop-optimized app bar.
  const DesktopAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopView = ResponsiveLayoutUtil.isAnyDesktop(context);

    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: elevation ?? (isDesktopView ? 0 : 4),
      centerTitle: centerTitle,
      toolbarHeight: isDesktopView ? 64 : 56, // Taller app bar for desktop
      titleSpacing: isDesktopView ? 24 : 16, // More spacing for desktop
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
