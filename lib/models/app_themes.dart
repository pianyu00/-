import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final Color seedColor;
  final IconData icon;

  const ThemeConfig(this.name, this.seedColor, this.icon);

  ThemeData get themeData => ThemeData(
        colorSchemeSeed: seedColor,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      );

  ThemeData get darkThemeData => ThemeData(
        colorSchemeSeed: seedColor,
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: seedColor.withValues(alpha: 0.85),
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1E1E20),
          surfaceTintColor: const Color(0xFF1E1E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF121213),
      );
}

final List<ThemeConfig> appThemes = [
  // ── 简约百搭 ──
  ThemeConfig('薄荷绿', const Color(0xFF5FB5A0), Icons.eco),
  ThemeConfig('雾霾蓝', const Color(0xFF7DA6D8), Icons.water_drop),
  ThemeConfig('燕麦米白', const Color(0xFFCBA882), Icons.wb_sunny),

  // ── 温柔治愈 ──
  ThemeConfig('豆沙粉', const Color(0xFFD4A0A0), Icons.favorite),
  ThemeConfig('芋泥紫', const Color(0xFFBBA9D1), Icons.window),

  // ── 小众高级 ──
  ThemeConfig('青瓷青', const Color(0xFF7EC4B0), Icons.spa),
  ThemeConfig('鼠尾草绿', const Color(0xFF94A882), Icons.forest),

  // ── 商务专业 ──
  ThemeConfig('深海蓝', const Color(0xFF2E6F95), Icons.waves),
  ThemeConfig('深墨绿', const Color(0xFF3D8B6E), Icons.park),
];
