import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:translator/translator.dart';
import '../models/language.dart';

class TranslationService {
  static const String _baseTranslationsPath = 'assets/translations';
  static const String _cachedTranslationsKey = 'cached_translations';
  static const String _currentLanguageKey = 'current_language';

  // In-memory cache of translations
  static Map<String, Map<String, String>> _translationsCache = {};

  // Current language
  static Language _currentLanguage = SupportedLanguages.english;

  // Google Translator instance
  static final GoogleTranslator _translator = GoogleTranslator();

  // Initialize the translation service
  static Future<void> initialize() async {
    await _loadCachedTranslations();
    await _loadBaseTranslations();

    // Only load English, French, and Arabic for now to avoid localization errors
    await _ensureTranslationsLoaded('en');
    await _ensureTranslationsLoaded('fr');
    await _ensureTranslationsLoaded('ar');

    // Set English as the default language
    _currentLanguage = SupportedLanguages.english;

    // Save the current language to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _currentLanguageKey, jsonEncode(_currentLanguage.toJson()));
  }

  // Get the current language
  static Language get currentLanguage => _currentLanguage;

  // Set the current language
  static Future<void> setLanguage(Language language) async {
    _currentLanguage = language;

    // Save the current language to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLanguageKey, jsonEncode(language.toJson()));

    // Ensure translations are loaded for this language
    await _ensureTranslationsLoaded(language.code);
  }

  // Translate a string
  static String translate(String key, {Map<String, String>? args}) {
    // Get the translation for the current language
    final translations = _translationsCache[_currentLanguage.code];
    if (translations == null) {
      return key; // Return the key if no translations are available
    }

    // Get the translation for the key
    String translation = translations[key] ?? key;

    // If translation not found, try to get it from English as fallback
    if (translation == key && _currentLanguage.code != 'en') {
      final englishTranslations = _translationsCache['en'];
      if (englishTranslations != null) {
        translation = englishTranslations[key] ?? key;
      }
    }

    // Replace arguments if provided
    if (args != null) {
      args.forEach((argKey, argValue) {
        translation = translation.replaceAll('{$argKey}', argValue);
      });
    }

    return translation;
  }

  // Get number format hint based on current language
  static String getNumberFormatHint() {
    return translate('number_format_hint');
  }

  // Get date format hint based on current language
  static String getDateFormatHint() {
    return translate('date_format_hint');
  }

  // Get time format hint based on current language
  static String getTimeFormatHint() {
    return translate('time_format_hint');
  }

  // This method has been removed as it's no longer needed

  // Load cached translations from shared preferences
  static Future<void> _loadCachedTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTranslationsJson = prefs.getString(_cachedTranslationsKey);

      if (cachedTranslationsJson != null) {
        final cachedTranslationsMap =
            jsonDecode(cachedTranslationsJson) as Map<String, dynamic>;

        _translationsCache = {};
        cachedTranslationsMap.forEach((languageCode, translations) {
          _translationsCache[languageCode] =
              Map<String, String>.from(translations);
        });
      }
    } catch (e) {
      debugPrint('Error loading cached translations: $e');
    }
  }

  // Load base translations from assets
  static Future<void> _loadBaseTranslations() async {
    try {
      // Load English translations as the base
      final englishTranslationsJson =
          await rootBundle.loadString('$_baseTranslationsPath/en.json');
      final englishTranslations =
          jsonDecode(englishTranslationsJson) as Map<String, dynamic>;

      _translationsCache['en'] = Map<String, String>.from(englishTranslations);

      // Save to cache
      await _saveTranslationsToCache();
    } catch (e) {
      debugPrint('Error loading base translations: $e');
    }
  }

  // Ensure translations are loaded for a specific language
  static Future<void> _ensureTranslationsLoaded(String languageCode) async {
    // If translations are already loaded, return
    if (_translationsCache.containsKey(languageCode)) {
      return;
    }

    // Try to load from assets first
    try {
      final translationsJson = await rootBundle
          .loadString('$_baseTranslationsPath/$languageCode.json');
      final translations = jsonDecode(translationsJson) as Map<String, dynamic>;

      _translationsCache[languageCode] = Map<String, String>.from(translations);
      await _saveTranslationsToCache();
      return;
    } catch (e) {
      debugPrint(
          'Translations not found in assets for $languageCode, trying to translate...');
    }

    // If not found in assets, try to translate from English
    await _translateFromEnglish(languageCode);
  }

  // Translate from English to the target language
  static Future<void> _translateFromEnglish(String targetLanguageCode) async {
    // Check if we have English translations
    if (!_translationsCache.containsKey('en')) {
      debugPrint('English translations not found, cannot translate');
      return;
    }

    // Check if we have internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    // If we don't have internet, try to load from local storage
    if (!hasInternet) {
      await _loadTranslationsFromLocalStorage(targetLanguageCode);
      return;
    }

    // Get English translations
    final englishTranslations = _translationsCache['en']!;
    final targetTranslations = <String, String>{};

    // Translate each string
    for (final entry in englishTranslations.entries) {
      try {
        final translation = await _translator.translate(
          entry.value,
          from: 'en',
          to: targetLanguageCode,
        );

        targetTranslations[entry.key] = translation.text;
      } catch (e) {
        debugPrint('Error translating ${entry.key}: $e');
        targetTranslations[entry.key] = entry.value; // Use English as fallback
      }
    }

    // Save the translations
    _translationsCache[targetLanguageCode] = targetTranslations;

    // Save to cache and local storage
    await _saveTranslationsToCache();
    await _saveTranslationsToLocalStorage(
        targetLanguageCode, targetTranslations);
  }

  // Save translations to shared preferences
  static Future<void> _saveTranslationsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert to JSON-compatible format
      final Map<String, dynamic> jsonMap = {};
      _translationsCache.forEach((languageCode, translations) {
        jsonMap[languageCode] = translations;
      });

      await prefs.setString(_cachedTranslationsKey, jsonEncode(jsonMap));
    } catch (e) {
      debugPrint('Error saving translations to cache: $e');
    }
  }

  // Save translations to local storage
  static Future<void> _saveTranslationsToLocalStorage(
    String languageCode,
    Map<String, String> translations,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/translations_$languageCode.json');

      await file.writeAsString(jsonEncode(translations));
    } catch (e) {
      debugPrint('Error saving translations to local storage: $e');
    }
  }

  // Load translations from local storage
  static Future<void> _loadTranslationsFromLocalStorage(
      String languageCode) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/translations_$languageCode.json');

      if (await file.exists()) {
        final translationsJson = await file.readAsString();
        final translations =
            jsonDecode(translationsJson) as Map<String, dynamic>;

        _translationsCache[languageCode] =
            Map<String, String>.from(translations);
      }
    } catch (e) {
      debugPrint('Error loading translations from local storage: $e');
    }
  }
}
