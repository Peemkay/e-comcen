import 'package:pdf/pdf.dart';

/// A stub implementation of the printing package for platforms where it's not supported
/// This provides the same API as the printing package but with stub implementations
/// that show appropriate messages to the user.

/// Stub class for Printing
class Printing {
  /// Shows a dialog indicating that printing is not supported on this platform
  static Future<bool> layoutPdf({
    required Future<Uint8List> Function(PdfPageFormat format) onLayout,
    String? name,
  }) async {
    // This is a stub implementation that will show a message to the user
    throw UnsupportedError(
      'Printing is not supported on Windows in this build due to dependency issues.',
    );
  }
}
