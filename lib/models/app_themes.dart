import 'package:flutter/material.dart';

// ── Premium Design Tokens ──
class AppColors {
  // Fintech greens
  static const green50 = Color(0xFFECFDF5);
  static const green100 = Color(0xFFD1FAE5);
  static const green200 = Color(0xFFA7F3D0);
  static const green400 = Color(0xFF34D399);
  static const green500 = Color(0xFF10B981);
  static const green600 = Color(0xFF059669);
  static const green700 = Color(0xFF047857);
  static const green800 = Color(0xFF065F46);
  static const green900 = Color(0xFF064E3B);

  // Neutrals
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  // Semantic
  static const expense = Color(0xFFEF4444);
  static const income = Color(0xFF10B981);
  static const premiumGreen = Color(0xFF059669);
  static const cardBorder = Color(0x0D000000);
  static const shimmer = Color(0xFFE2E8F0);

  // Glass
  static const glassWhite = Color(0xCCFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
  static const darkGlass = Color(0xCC1A1A2E);
  static const darkGlassBorder = Color(0x33FFFFFF);

  // ── Dark Luxury Palette ──
  static const darkBg = Color(0xFF0A0E0F);
  static const darkSurface = Color(0xFF121618);
  static const darkCard = Color(0xFF1A1E20);
  static const darkCardElevated = Color(0xFF22262A);
  static const darkDivider = Color(0x1AFFFFFF);

  // Emerald glow system
  static const emerald = Color(0xFF00D68F);
  static const emeraldDark = Color(0xFF00A87A);
  static const emeraldGlow = Color(0x1A00D68F);
  static const emeraldGlowMedium = Color(0x0D00D68F);
  static const emeraldGlowStrong = Color(0x3300D68F);

  // Frost glass
  static const frostBorder = Color(0x1AFFFFFF);
  static const frostHighlight = Color(0x08FFFFFF);

  // Semantic dark
  static const expenseDark = Color(0xFFFF453A);
  static const incomeDark = Color(0xFF30D158);

  // Light mode semantic
  static const textPrimary = Color(0xFF202124);
  static const expenseLight = Color(0xFFEA4335);
  static const incomeLight = Color(0xFF34A853);
  static const expenseAmtLight = Color(0xFFDC2626);
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> large = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.premiumGreen.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> dark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Premium dark card shadows
  static List<BoxShadow> cardDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> cardDarkElevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.06),
      blurRadius: 48,
      offset: const Offset(0, -4),
    ),
  ];

  // Glow effects
  static List<BoxShadow> glowPremium = [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.2),
      blurRadius: 32,
      spreadRadius: 4,
      offset: const Offset(0, 0),
    ),
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.1),
      blurRadius: 64,
      spreadRadius: 16,
      offset: const Offset(0, 0),
    ),
  ];
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 28.0;
  static const full = 999.0;
}

// ── Theme Config ──
class ThemeConfig {
  final String name;
  final Color seedColor;
  final IconData icon;
  final LinearGradient backgroundGradient;
  final LinearGradient cardGradient;

  // Per-theme dark mode colors
  final Color darkBgColor;
  final Color darkSurfaceColor;
  final Color darkCardColor;
  final LinearGradient darkBackgroundGradient;

  const ThemeConfig({
    required this.name,
    required this.seedColor,
    required this.icon,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.darkBgColor,
    required this.darkSurfaceColor,
    required this.darkCardColor,
    required this.darkBackgroundGradient,
  });

  /// Ensure the seed color is toned to a readable primary for each brightness.
  Color _primaryForBrightness(Brightness brightness) {
    final hsl = HSLColor.fromColor(seedColor);
    if (brightness == Brightness.light) {
      // Darken very light seeds so they contrast on white
      if (hsl.lightness > 0.55) {
        return hsl.withLightness(0.40).toColor();
      }
    } else {
      // Lighten very dark seeds so they show on near-black
      if (hsl.lightness < 0.25) {
        return hsl.withLightness(0.35).toColor();
      }
    }
    return seedColor;
  }

  ThemeData get themeData {
    final primary = _primaryForBrightness(Brightness.light);
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          primary: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          titleTextStyle: const TextStyle(
            color: AppColors.gray900,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primary,
          unselectedItemColor: AppColors.gray400,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.gray100,
          thickness: 1,
          space: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.gray900,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.gray900,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.gray900,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.gray900,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: AppColors.gray900,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            color: AppColors.gray700,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.gray600,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
            letterSpacing: 0.3,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
  }

  ThemeData get darkThemeData {
    final primary = _primaryForBrightness(Brightness.dark);
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          primary: primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: darkBgColor,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkCardColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primary,
          unselectedItemColor: AppColors.gray500,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 0.5,
          space: 0,
        ),
        textTheme: TextTheme(
          headlineLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Colors.white,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.frostBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.frostBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.emerald.withValues(alpha: 0.5)),
          ),
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        ),
      );
  }
}

// ── Premium Theme Configurations ──
final List<ThemeConfig> appThemes = [
  // ═══════════════════════════════════════════════════
  // 1. Neo Mint — deep emerald + vibrant mint #00E5B8
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '霓虹薄荷',
    seedColor: const Color(0xFF00E5B8),
    icon: Icons.spa,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD4F5E8), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFD4F5E8).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF1A3A32),
    darkSurfaceColor: const Color(0xFF244840),
    darkCardColor: const Color(0xFF2E5850),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A3A32), Color(0xFF1A3A32), Color(0xFF244840)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 2. Coral Red — warm coral + soft pink #FF6B6B
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '珊瑚红',
    seedColor: const Color(0xFFFF6B6B),
    icon: Icons.favorite,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE8E8), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFFFE8E8).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF2E1414),
    darkSurfaceColor: const Color(0xFF3D1E1E),
    darkCardColor: const Color(0xFF4A2828),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E1414), Color(0xFF2E1414), Color(0xFF3D1E1E)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 3. Cyber Glass — deep purple-blue + neon cyan #00F0FF
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '赛博朋克',
    seedColor: const Color(0xFF00F0FF),
    icon: Icons.blur_on,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE4DEFF), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFE4DEFF).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF1E1540),
    darkSurfaceColor: const Color(0xFF2E2050),
    darkCardColor: const Color(0xFF3E2E60),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E1540), Color(0xFF1E1540), Color(0xFF2E2050)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 4. Warm Ember — warm dark amber + soft gold #FFB74D
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '琥珀金',
    seedColor: const Color(0xFFFFB74D),
    icon: Icons.whatshot,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFFFF3E0).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF2E1F14),
    darkSurfaceColor: const Color(0xFF3D2E24),
    darkCardColor: const Color(0xFF4A382E),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E1F14), Color(0xFF2E1F14), Color(0xFF3D2E24)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 5. Sakura Night — soft pink-purple + sakura pink #FF9ECF
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '樱花夜',
    seedColor: const Color(0xFFFF9ECF),
    icon: Icons.local_florist,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCE4EC), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFFCE4EC).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF2E1D30),
    darkSurfaceColor: const Color(0xFF3D2A40),
    darkCardColor: const Color(0xFF4A3648),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E1D30), Color(0xFF2E1D30), Color(0xFF3D2A40)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 6. Royal Purple — deep purple + lavender #7C4DFF
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '星空紫',
    seedColor: const Color(0xFF7C4DFF),
    icon: Icons.auto_awesome,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEDE7FF), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFEDE7FF).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF1E1433),
    darkSurfaceColor: const Color(0xFF2E1E45),
    darkCardColor: const Color(0xFF3D2A58),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E1433), Color(0xFF1E1433), Color(0xFF2E1E45)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 7. Obsidian Luxe — pure obsidian black + luxurious gold #FFD700
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '黑曜金',
    seedColor: const Color(0xFFFFD700),
    icon: Icons.diamond,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF8E1), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFFFF8E1).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF1E1C18),
    darkSurfaceColor: const Color(0xFF2E2A24),
    darkCardColor: const Color(0xFF3D3830),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E1C18), Color(0xFF1E1C18), Color(0xFF2E2A24)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 8. Electric Pulse — cosmic dark + electric cyan #00F5FF & magenta
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '电子脉冲',
    seedColor: const Color(0xFF00F5FF),
    icon: Icons.bolt,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD4FAFF), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFD4FAFF).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF1E0F3A),
    darkSurfaceColor: const Color(0xFF2E1E4A),
    darkCardColor: const Color(0xFF3E2E58),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E0F3A), Color(0xFF1E0F3A), Color(0xFF2E1E4A)],
    ),
  ),

  // ═══════════════════════════════════════════════════
  // 9. Warm Orange — warm amber orange + soft peach #FF9100
  // ═══════════════════════════════════════════════════
  ThemeConfig(
    name: '暖阳橙',
    seedColor: const Color(0xFFFF9100),
    icon: Icons.wb_sunny,
    backgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF0E0), Color(0xFFFFFFFF)],
    ),
    cardGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, const Color(0xFFFFF0E0).withValues(alpha: 0.7)],
    ),
    darkBgColor: const Color(0xFF2E1C0E),
    darkSurfaceColor: const Color(0xFF3D2A1A),
    darkCardColor: const Color(0xFF4A3628),
    darkBackgroundGradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E1C0E), Color(0xFF2E1C0E), Color(0xFF3D2A1A)],
    ),
  ),
];

// ── Premium Utility Widgets ──

/// Glassmorphism card with backdrop blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tintColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.tintColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        tintColor ??
        (isDark
            ? const Color(0xCC1E1E2E)
            : const Color(0xCCFFFFFF));
    final borderColor =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow:
            shadows ??
            (isDark ? AppShadows.dark : AppShadows.medium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Premium card with subtle gradient overlay
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = AppRadius.lg,
    this.color,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        color ??
        (isDark
            ? const Color.fromRGBO(30, 30, 40, 0.8)
            : Colors.white);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? (isDark ? AppShadows.dark : AppShadows.soft),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
