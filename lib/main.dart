import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_themes.dart';
import 'pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AccountBookApp());
}

class AccountBookApp extends StatefulWidget {
  const AccountBookApp({super.key});

  static AccountBookAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<AccountBookAppState>();
  }

  @override
  State<AccountBookApp> createState() => AccountBookAppState();
}

class AccountBookAppState extends State<AccountBookApp> {
  int _themeIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeIndex = prefs.getInt('theme_index') ?? 0;
      _themeMode = _parseThemeMode(prefs.getString('theme_mode'));
      _currencySymbol = prefs.getString('currency_symbol') ?? '¥';
      _dateFormat = prefs.getString('date_format') ?? 'yyyy-MM-dd';
      _language = prefs.getString('language') ?? 'zh';
      _loaded = true;
    });
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
    setState(() => _themeIndex = index);
  }

  void changeThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    setState(() => _themeMode = mode);
  }

  void changeCurrency(String symbol) {
    _currencySymbol = symbol;
    setState(() {});
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('currency_symbol', symbol);
    });
  }

  void changeDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    setState(() => _dateFormat = format);
  }

  void changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻记账',
      debugShowCheckedModeBanner: false,
      theme: appThemes[_themeIndex].themeData,
      darkTheme: appThemes[_themeIndex].darkThemeData,
      themeMode: _themeMode,
      locale: Locale(_language),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home:
          _loaded
              ? SplashPage(
                onThemeChanged: changeTheme,
                currentThemeIndex: _themeIndex,
              )
              : const SizedBox.shrink(),
    );
  }
}
