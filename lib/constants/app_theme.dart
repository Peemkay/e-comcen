import 'package:flutter/material.dart';

/// AppTheme provides consistent styling and responsive design utilities
/// for the E-COMCEN application.
class AppTheme {
  /// Responsive spacing values that adapt to different screen sizes
  static double getResponsiveSpacing(BuildContext context,
      {double factor = 1.0}) {
    final size = MediaQuery.of(context).size;
    // Base spacing value that scales with screen size
    final baseSpacing = size.width * 0.02; // 2% of screen width
    return baseSpacing * factor;
  }

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(BuildContext context,
      {double baseFontSize = 14.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale font size based on screen width with min/max constraints
    if (screenWidth > 1200) {
      return baseFontSize * 1.2; // Larger screens
    } else if (screenWidth > 600) {
      return baseFontSize * 1.0; // Medium screens
    } else {
      return baseFontSize * 0.9; // Small screens
    }
  }

  /// Get responsive icon size based on screen width
  static double getResponsiveIconSize(BuildContext context,
      {double baseSize = 24.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return baseSize * 1.2;
    } else if (screenWidth > 600) {
      return baseSize * 1.0;
    } else {
      return baseSize * 0.9;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context,
      {double factor = 1.0}) {
    final spacing = getResponsiveSpacing(context, factor: factor);
    return EdgeInsets.all(spacing);
  }

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context,
      {double factor = 1.0}) {
    final spacing = getResponsiveSpacing(context, factor: factor);
    return EdgeInsets.symmetric(horizontal: spacing);
  }

  /// Get responsive vertical padding based on screen size
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context,
      {double factor = 1.0}) {
    final spacing = getResponsiveSpacing(context, factor: factor);
    return EdgeInsets.symmetric(vertical: spacing);
  }

  /// Get number of grid columns based on screen width
  static int getResponsiveGridCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4; // Large screens
    } else if (screenWidth > 900) {
      return 3; // Medium-large screens
    } else if (screenWidth > 600) {
      return 2; // Medium screens
    } else {
      return 1; // Small screens
    }
  }

  /// Get card width based on screen size
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return screenWidth * 0.2; // 20% of screen width
    } else if (screenWidth > 900) {
      return screenWidth * 0.25; // 25% of screen width
    } else if (screenWidth > 600) {
      return screenWidth * 0.4; // 40% of screen width
    } else {
      return screenWidth * 0.8; // 80% of screen width
    }
  }

  /// Check if the device is a mobile device
  static bool isMobileDevice(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if the device is a tablet
  static bool isTabletDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if the device is a desktop
  static bool isDesktopDevice(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  // Nigerian Army Signal Corps colors
  static const Color primaryColor =
      Color(0xFF00205B); // Dark Blue (Signal Corps color)
  static const Color secondaryColor =
      Color(0xFF008000); // Green (Nigerian Army color)
  static const Color accentColor =
      Color(0xFFFFD700); // Gold/Yellow (for accents)
  static const Color textColor = Color(0xFF333333);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFB00020);

  // Aliases for consistency
  static const Color primaryNavyBlue = primaryColor;
  static const Color armyGreen = secondaryColor;
  static const Color goldAccent = accentColor;
  static const Color white = Colors.white;
  static const Color errorRed = errorColor;

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textColor,
      ),
      bodyMedium: TextStyle(
        color: textColor,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  // Custom Input Decoration
  static InputDecoration inputDecoration(String label,
      {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: primaryColor),
    );
  }

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: white,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: primaryColor),
    ),
    elevation: 0,
  );

  // Dropdown Decoration
  static DropdownButtonFormField<String> dropdownDecoration(String label,
      String? value, List<String> items, Function(String?) onChanged,
      {String? hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: inputDecoration(label, hint: hint),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
      dropdownColor: white,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
    );
  }
}
