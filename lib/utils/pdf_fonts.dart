import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

/// A utility class for loading and managing fonts for PDF generation
class PdfFonts {
  static pw.Font? _robotoRegular;
  static pw.Font? _robotoBold;
  static pw.Font? _robotoItalic;
  static pw.Font? _robotoLight;
  static pw.Font? _robotoMedium;

  /// Initialize fonts for PDF generation
  static Future<void> init() async {
    if (_robotoRegular != null) return; // Already initialized

    try {
      // Use built-in fonts instead of loading from assets
      // This avoids issues with missing font files
      _robotoRegular = pw.Font.courier();
      _robotoBold = pw.Font.courierBold();
      _robotoItalic = pw.Font.courierOblique();
      _robotoLight = pw.Font.courier();
      _robotoMedium = pw.Font.courierBold();
    } catch (e) {
      debugPrint('Error initializing PDF fonts: $e');
      // Fallback to built-in fonts if loading fails
      _robotoRegular = pw.Font.helvetica();
      _robotoBold = pw.Font.helveticaBold();
      _robotoItalic = pw.Font.helveticaOblique();
      _robotoLight = pw.Font.helvetica();
      _robotoMedium = pw.Font.helvetica();
    }
  }

  /// Get a theme for PDF documents with custom fonts
  static pw.ThemeData getTheme() {
    return pw.ThemeData.withFont(
      base: _robotoRegular ?? pw.Font.courier(),
      bold: _robotoBold ?? pw.Font.courierBold(),
      italic: _robotoItalic ?? pw.Font.courierOblique(),
      boldItalic: _robotoBold ?? pw.Font.courierBoldOblique(),
    );
  }

  /// Get the regular font
  static pw.Font get regular => _robotoRegular ?? pw.Font.courier();

  /// Get the bold font
  static pw.Font get bold => _robotoBold ?? pw.Font.courierBold();

  /// Get the italic font
  static pw.Font get italic => _robotoItalic ?? pw.Font.courierOblique();

  /// Get the light font
  static pw.Font get light => _robotoLight ?? pw.Font.courier();

  /// Get the medium font
  static pw.Font get medium => _robotoMedium ?? pw.Font.courier();
}
