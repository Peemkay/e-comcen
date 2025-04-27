import '../services/translation_service.dart';

extension TranslationExtension on String {
  /// Translates the string using the current language
  String tr({Map<String, String>? args}) {
    return TranslationService.translate(this, args: args);
  }
}

extension StringExtension on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Converts a string to title case (capitalizes each word)
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates a string to a specified length and adds an ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Checks if a string is a valid email address
  bool isValidEmail() {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Checks if a string is a valid phone number
  bool isValidPhone() {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(this);
  }

  /// Removes all whitespace from a string
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Converts a string to camelCase
  String toCamelCase() {
    if (isEmpty) return this;
    final words = split(RegExp(r'[\s_-]'));
    final result = words.first.toLowerCase() +
        words.skip(1).map((word) => word.capitalize()).join('');
    return result;
  }
}
