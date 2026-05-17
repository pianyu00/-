import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'models/app_themes.dart';
import 'pages/splash_page.dart';
import 'providers/app_settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettingsProvider()..loadSettings(),
      child: const AccountBookApp(),
    ),
  );
}

class AccountBookApp extends StatelessWidget {
  const AccountBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final themeConfig = appThemes[settings.themeIndex];

    return MaterialApp(
      title: '轻记账',
      debugShowCheckedModeBanner: false,
      theme: themeConfig.themeData,
      darkTheme: themeConfig.darkThemeData,
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home:
          settings.loaded
              ? const SplashPage()
              : const SizedBox.shrink(),
    );
  }
}
