import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Utility class for responsive design
class ResponsiveUtil {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Platform detection
  static bool get isAnyDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  // Get appropriate value based on screen type
  static T getValueForScreenType<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    // For desktop screens
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile;
    }

    // For tablet screens
    if (width >= mobileBreakpoint) {
      return tablet ?? mobile;
    }

    // For mobile screens
    return mobile;
  }

  // Get appropriate padding based on screen type
  static EdgeInsets getScreenPadding(BuildContext context) {
    return getValueForScreenType<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );
  }

  // Get appropriate font size based on screen type
  static double getFontSize(BuildContext context, double baseSize) {
    return getValueForScreenType<double>(
      context: context,
      mobile: baseSize * 0.9,
      tablet: baseSize,
      desktop: baseSize * 1.1,
    );
  }

  // Get appropriate grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= desktopBreakpoint) {
      return 4; // 4 columns for desktop
    } else if (width >= tabletBreakpoint) {
      return 3; // 3 columns for larger tablets
    } else if (width >= mobileBreakpoint) {
      return 2; // 2 columns for small tablets
    } else {
      return 1; // 1 column for mobile in portrait
    }
  }

  // Get appropriate card aspect ratio based on screen type
  static double getCardAspectRatio(BuildContext context) {
    return getValueForScreenType<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.3,
    );
  }

  // Get appropriate icon size based on screen type
  static double getIconSize(BuildContext context, {double factor = 1.0}) {
    return getValueForScreenType<double>(
      context: context,
      mobile: 24.0 * factor,
      tablet: 28.0 * factor,
      desktop: 32.0 * factor,
    );
  }

  // Get appropriate spacing based on screen type
  static double getSpacing(BuildContext context, {double factor = 1.0}) {
    return getValueForScreenType<double>(
      context: context,
      mobile: 8.0 * factor,
      tablet: 12.0 * factor,
      desktop: 16.0 * factor,
    );
  }
}
