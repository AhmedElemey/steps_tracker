import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localizations/app_translations_en.dart';
import '../localizations/app_translations_ar.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  
  Locale _locale = const Locale('en', 'US');
  bool _isRTL = false;

  // Getters
  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  LocalizationService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
      _isRTL = languageCode == 'ar';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      _locale = Locale(languageCode);
      _isRTL = languageCode == 'ar';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLanguage('ar');
    } else {
      setLanguage('en');
    }
  }

  String getText(String key, {Map<String, String>? params}) {
    final translations = _getTranslations();
    String text = translations[key] ?? key;
    
    // Replace placeholders
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return text;
  }

  Map<String, String> _getTranslations() {
    switch (_locale.languageCode) {
      case 'ar':
        return AppTranslationsAr.translations;
      case 'en':
      default:
        return AppTranslationsEn.translations;
    }
  }
}
