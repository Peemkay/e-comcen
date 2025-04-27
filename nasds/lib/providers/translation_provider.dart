import 'package:flutter/material.dart';
import '../models/language.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  Language _currentLanguage = SupportedLanguages.english;
  bool _isLoading = false;

  // Get the current language
  Language get currentLanguage => _currentLanguage;

  // Check if translations are being loaded
  bool get isLoading => _isLoading;

  // Get the list of supported languages
  List<Language> get supportedLanguages =>
      SupportedLanguages.supportedLanguages;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await TranslationService.initialize();
    _currentLanguage = TranslationService.currentLanguage;

    _isLoading = false;
    notifyListeners();
  }

  // Change the current language
  Future<void> changeLanguage(Language language) async {
    if (_currentLanguage == language) return;

    // For now, only allow English, French, and Arabic to avoid localization errors
    if (language.code != 'en' &&
        language.code != 'fr' &&
        language.code != 'ar') {
      // Use English as fallback
      language = SupportedLanguages.english;
    }

    _isLoading = true;
    notifyListeners();

    await TranslationService.setLanguage(language);
    _currentLanguage = language;

    _isLoading = false;
    notifyListeners();
  }

  // Translate a string
  String translate(String key, {Map<String, String>? args}) {
    return TranslationService.translate(key, args: args);
  }
}
