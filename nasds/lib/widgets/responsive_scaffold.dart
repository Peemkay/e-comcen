import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// A responsive scaffold that adapts its layout based on screen size.
///
/// This widget provides a consistent layout for all screens in the app,
/// with responsive padding and constraints to prevent overflow issues.
class ResponsiveScaffold extends StatelessWidget {
  /// The app bar to display at the top of the scaffold
  final PreferredSizeWidget? appBar;
  
  /// The primary content of the scaffold
  final Widget body;
  
  /// Optional drawer widget
  final Widget? drawer;
  
  /// Optional bottom navigation bar
  final Widget? bottomNavigationBar;
  
  /// Optional floating action button
  final Widget? floatingActionButton;
  
  /// Optional floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  /// Whether to resize the body to avoid the bottom inset
  final bool resizeToAvoidBottomInset;
  
  /// Whether to use a scrollable body
  final bool scrollable;
  
  /// Optional padding around the body
  final EdgeInsetsGeometry? padding;
  
  /// Optional background color
  final Color? backgroundColor;

  /// Creates a responsive scaffold.
  const ResponsiveScaffold({
    Key? key,
    this.appBar,
    required this.body,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.scrollable = true,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get responsive padding based on screen size
    final responsivePadding = padding ?? 
        AppTheme.getResponsivePadding(context, factor: 1.0);
    
    // Create the body with responsive padding
    Widget responsiveBody = Padding(
      padding: responsivePadding,
      child: body,
    );
    
    // Wrap in SingleChildScrollView if scrollable is true
    if (scrollable) {
      responsiveBody = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: responsiveBody,
      );
    }
    
    // Use SafeArea to avoid system UI overlays
    responsiveBody = SafeArea(
      child: responsiveBody,
    );
    
    // Create the scaffold with the responsive body
    return Scaffold(
      appBar: appBar,
      body: responsiveBody,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }
}

/// A responsive app bar that adapts its height and content based on screen size.
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar
  final Widget title;
  
  /// Optional list of actions to display on the right side of the app bar
  final List<Widget>? actions;
  
  /// Optional leading widget to display on the left side of the app bar
  final Widget? leading;
  
  /// Whether to center the title
  final bool centerTitle;
  
  /// Optional background color
  final Color? backgroundColor;
  
  /// Optional elevation
  final double? elevation;
  
  /// Optional bottom widget
  final PreferredSizeWidget? bottom;

  /// Creates a responsive app bar.
  const ResponsiveAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a small screen
    final isSmallScreen = AppTheme.isMobileDevice(context);
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: elevation ?? 0,
      bottom: bottom,
      // Use responsive padding based on screen size
      titleSpacing: isSmallScreen ? 0 : 16,
      toolbarHeight: isSmallScreen ? kToolbarHeight : kToolbarHeight * 1.2,
    );
  }

  @override
  Size get preferredSize {
    // Calculate the preferred size based on whether we have a bottom widget
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

/// A responsive drawer that adapts its width based on screen size.
class ResponsiveDrawer extends StatelessWidget {
  /// The header widget to display at the top of the drawer
  final Widget? header;
  
  /// The list of drawer items
  final List<Widget> children;
  
  /// Optional background color
  final Color? backgroundColor;

  /// Creates a responsive drawer.
  const ResponsiveDrawer({
    Key? key,
    this.header,
    required this.children,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the drawer width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * (screenWidth > 600 ? 0.3 : 0.7);
    
    return Drawer(
      width: drawerWidth,
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            if (header != null) header!,
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
