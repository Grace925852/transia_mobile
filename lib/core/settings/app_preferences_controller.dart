import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController._();

  static final AppPreferencesController instance =
      AppPreferencesController._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _themeKey = 'app_theme_mode';
  static const String _languageKey = 'app_language_code';

  bool _isDarkMode = false;
  String _languageCode = 'fr';
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;
  bool get isLoaded => _isLoaded;

  bool get isRtl => _languageCode == 'ar';

  Future<void> load() async {
    final storedTheme = await _storage.read(key: _themeKey);
    final storedLanguage = await _storage.read(key: _languageKey);

    _isDarkMode = storedTheme == 'dark';
    _languageCode = _isSupportedLanguage(storedLanguage) ? storedLanguage! : 'fr';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _storage.write(key: _themeKey, value: value ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    if (!_isSupportedLanguage(value)) return;

    _languageCode = value;
    await _storage.write(key: _languageKey, value: value);
    notifyListeners();
  }

  bool _isSupportedLanguage(String? code) {
    return code == 'fr' || code == 'en' || code == 'es' || code == 'ar';
  }

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    switch (_languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      case 'ar':
        return ar;
      case 'fr':
      default:
        return fr;
    }
  }

  String get languageLabel {
    switch (_languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'ar':
        return 'العربية';
      case 'fr':
      default:
        return 'Français';
    }
  }
}