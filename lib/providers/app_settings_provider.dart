import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized app settings with ChangeNotifier for Provider.
class AppSettingsProvider extends ChangeNotifier {
  int _themeIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;
  String _currencySymbol = '¥';
  String _dateFormat = 'yyyy-MM-dd';
  String _language = 'zh';
  bool _loaded = false;

  // Getters
  int get themeIndex => _themeIndex;
  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get dateFormat => _dateFormat;
  String get language => _language;
  bool get loaded => _loaded;

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// Load settings from SharedPreferences.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeIndex = prefs.getInt('theme_index') ?? 0;
    _themeMode = _parseThemeMode(prefs.getString('theme_mode'));
    _currencySymbol = prefs.getString('currency_symbol') ?? '¥';
    _dateFormat = prefs.getString('date_format') ?? 'yyyy-MM-dd';
    _language = prefs.getString('language') ?? 'zh';
    _loaded = true;
    notifyListeners();
  }

  Future<void> changeTheme(int index) async {
    if (_themeIndex == index) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
    _themeIndex = index;
    notifyListeners();
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = mode == ThemeMode.system
        ? 'system'
        : mode == ThemeMode.light
            ? 'light'
            : 'dark';
    await prefs.setString('theme_mode', modeStr);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> changeCurrency(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
  }

  Future<void> changeDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    _dateFormat = format;
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    _language = lang;
    notifyListeners();
  }
}
