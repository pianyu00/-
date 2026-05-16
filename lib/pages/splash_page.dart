import 'package:flutter/material.dart';
import '../utils/strings.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  final void Function(int) onThemeChanged;
  final int currentThemeIndex;

  const SplashPage({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeIndex,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1100), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, a1, a2) => HomePage(
          onThemeChanged: widget.onThemeChanged,
          currentThemeIndex: widget.currentThemeIndex,
        ),
        transitionsBuilder: (ctx, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  String _greeting(BuildContext ctx) {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return S.t(ctx, 'good_morning');
    if (h >= 12 && h < 18) return S.t(ctx, 'good_afternoon');
    if (h >= 18 && h < 22) return S.t(ctx, 'good_evening');
    return S.t(ctx, 'good_night');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon style
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 48,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.t(context, 'home_title'),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _greeting(context),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
