import "package:flutter/material.dart";
import "dart:io" show Platform;

class ResponsiveLayoutUtil {
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

  // Get appropriate padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  // Get appropriate column count for grid layouts
  static int getResponsiveGridCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }
  
  // Get appropriate column count for grid layouts - alias for getResponsiveGridCount
  static int responsiveGridCount(BuildContext context) {
    return getResponsiveGridCount(context);
  }

  // Get responsive spacing
  static double responsiveSpacing(BuildContext context,
      {double mobile = 8.0, double tablet = 12.0, double desktop = 16.0}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive font size
  static double responsiveFontSize(BuildContext context,
      {double mobile = 14.0, double tablet = 16.0, double desktop = 18.0}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive elevation
  static double responsiveElevation(BuildContext context,
      {double mobile = 2.0, double tablet = 4.0, double desktop = 6.0}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive border radius
  static double responsiveBorderRadius(BuildContext context,
      {double mobile = 8.0, double tablet = 12.0, double desktop = 16.0}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive card aspect ratio
  static double responsiveCardAspectRatio(BuildContext context,
      {double mobile = 1.2, double tablet = 1.5, double desktop = 1.8}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive icon size
  static double responsiveIconSize(BuildContext context,
      {double mobile = 24.0, double tablet = 28.0, double desktop = 32.0}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Get responsive value based on screen size
  static T responsiveValue<T>(BuildContext context,
      {required T mobile, required T tablet, required T desktop}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
}
