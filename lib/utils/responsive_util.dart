import 'package:flutter/material.dart';

/// Utility class for responsive design
class ResponsiveUtil {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Returns a value based on the screen size
  /// [mobile] value for mobile screens
  /// [tablet] value for tablet screens (optional, defaults to mobile)
  /// [desktop] value for desktop screens (optional, defaults to tablet or mobile)
  static T getValueForScreenType<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Returns the appropriate padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    return getValueForScreenType(
      context: context,
      mobile: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
    );
  }

  /// Returns the appropriate number of grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    return getValueForScreenType(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Returns the appropriate child aspect ratio for grid items based on screen size
  static double getGridChildAspectRatio(BuildContext context) {
    return getValueForScreenType(
      context: context,
      mobile: 0.8,
      tablet: 0.85,
      desktop: 0.9,
    );
  }

  /// Returns the appropriate font size based on screen size
  static double getFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = getValueForScreenType(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
    return baseFontSize * scaleFactor;
  }

  /// Returns the appropriate icon size based on screen size
  static double getIconSize(BuildContext context, double baseIconSize) {
    final scaleFactor = getValueForScreenType(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.4,
    );
    return baseIconSize * scaleFactor;
  }

  /// Returns the appropriate widget based on screen size
  static Widget getWidgetForScreenType({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// A responsive scaffold that adapts to different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtil.getFontSize(context, 18),
          ),
        ),
        actions: actions,
        backgroundColor: backgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveUtil.getScreenPadding(context),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
