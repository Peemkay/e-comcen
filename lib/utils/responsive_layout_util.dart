import 'package:flutter/material.dart';

/// A utility class for responsive layout calculations.
///
/// This class provides static methods to calculate responsive values
/// based on screen size, orientation, and device type.
class ResponsiveLayoutUtil {
  /// Private constructor to prevent instantiation
  ResponsiveLayoutUtil._();
  
  /// Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Check if the current device is a mobile device
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  /// Check if the current device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  /// Check if the current device is a desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  /// Check if the current orientation is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Check if the current orientation is portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Get the screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get the screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get the screen aspect ratio (width / height)
  static double screenAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }
  
  /// Calculate a responsive value based on screen width
  /// 
  /// [mobileValue] is used for mobile devices
  /// [tabletValue] is used for tablet devices
  /// [desktopValue] is used for desktop devices
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobileValue,
    T? tabletValue,
    required T desktopValue,
  }) {
    if (isDesktop(context)) {
      return desktopValue;
    } else if (isTablet(context)) {
      return tabletValue ?? mobileValue;
    } else {
      return mobileValue;
    }
  }
  
  /// Calculate a responsive font size based on screen width
  static double responsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? minFontSize,
    double? maxFontSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate font size based on screen width
    double fontSize;
    if (screenWidth > desktopBreakpoint) {
      fontSize = baseFontSize * 1.2;
    } else if (screenWidth > tabletBreakpoint) {
      fontSize = baseFontSize * 1.1;
    } else if (screenWidth > mobileBreakpoint) {
      fontSize = baseFontSize;
    } else {
      fontSize = baseFontSize * 0.9;
    }
    
    // Apply min/max constraints
    if (minFontSize != null && fontSize < minFontSize) {
      fontSize = minFontSize;
    }
    if (maxFontSize != null && fontSize > maxFontSize) {
      fontSize = maxFontSize;
    }
    
    return fontSize;
  }
  
  /// Calculate responsive padding based on screen size
  static EdgeInsets responsivePadding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
    double factor = 1.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate base padding value
    final basePadding = screenWidth * 0.02 * factor; // 2% of screen width
    
    // Calculate horizontal and vertical padding
    final horizontalPadding = horizontal ?? basePadding;
    final verticalPadding = vertical ?? basePadding;
    
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }
  
  /// Calculate responsive margin based on screen size
  static EdgeInsets responsiveMargin(
    BuildContext context, {
    double? horizontal,
    double? vertical,
    double factor = 1.0,
  }) {
    return responsivePadding(
      context,
      horizontal: horizontal,
      vertical: vertical,
      factor: factor,
    );
  }
  
  /// Calculate responsive spacing based on screen size
  static double responsiveSpacing(
    BuildContext context, {
    double factor = 1.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.02 * factor; // 2% of screen width
  }
  
  /// Calculate responsive icon size based on screen size
  static double responsiveIconSize(
    BuildContext context, {
    double baseSize = 24.0,
  }) {
    if (isDesktop(context)) {
      return baseSize * 1.2;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 0.9;
    }
  }
  
  /// Calculate responsive grid column count based on screen width
  static int responsiveGridCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > desktopBreakpoint) {
      return 4; // Desktop
    } else if (screenWidth > tabletBreakpoint) {
      return 3; // Large tablet
    } else if (screenWidth > mobileBreakpoint) {
      return 2; // Small tablet
    } else {
      return 1; // Mobile
    }
  }
  
  /// Calculate responsive width based on screen size
  static double responsiveWidth(
    BuildContext context, {
    double? minWidth,
    double? maxWidth,
    double percentage = 0.9, // 90% of screen width by default
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    double width = screenWidth * percentage;
    
    // Apply min/max constraints
    if (minWidth != null && width < minWidth) {
      width = minWidth;
    }
    if (maxWidth != null && width > maxWidth) {
      width = maxWidth;
    }
    
    return width;
  }
  
  /// Calculate responsive height based on screen size
  static double responsiveHeight(
    BuildContext context, {
    double? minHeight,
    double? maxHeight,
    double percentage = 0.9, // 90% of screen height by default
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    double height = screenHeight * percentage;
    
    // Apply min/max constraints
    if (minHeight != null && height < minHeight) {
      height = minHeight;
    }
    if (maxHeight != null && height > maxHeight) {
      height = maxHeight;
    }
    
    return height;
  }
}
