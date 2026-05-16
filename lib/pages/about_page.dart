import 'package:flutter/material.dart';
import '../utils/strings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(S.t(context, 'about'))),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero header ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.08),
                  primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Column(
              children: [
                // App icon with glow
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (ctx, val, child) => Transform.scale(
                    scale: val,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          size: 44, color: primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (ctx, val, child) => Opacity(
                    opacity: val,
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Text(S.t(context, 'home_title'),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(S.t(context, 'version'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Info cards ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                _infoCard(context,
                  icon: Icons.person_outline,
                  label: S.t(context, 'developer'),
                  value: 'CQUPT-KEIKEI',
                  color: primary,
                ),
                const SizedBox(height: 10),
                _infoCard(context,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: '1987780650@qq.com',
                  color: primary,
                  onTap: () {/* copy / launch email */},
                ),
                const SizedBox(height: 10),
                _infoCard(context,
                  icon: Icons.code_outlined,
                  label: S.t(context, 'tech_stack'),
                  value: '',
                  color: primary,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _chip('Flutter', primary),
                      const SizedBox(width: 6),
                      _chip('SQLite', Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Slogan ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              S.t(context, 'app_slogan'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.5),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                    if (value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(value,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(ctx).colorScheme.onSurface)),
                      ),
                    if (trailing != null) trailing,
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
