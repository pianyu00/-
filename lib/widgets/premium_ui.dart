import 'package:flutter/material.dart';
import '../models/app_themes.dart';

/// Ambient radial glow behind a child widget
class AmbientGlow extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double opacity;
  final Alignment alignment;

  const AmbientGlow({
    super.key,
    required this.child,
    this.color = AppColors.emerald,
    this.radius = 150,
    this.opacity = 0.15,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: radius / 200,
                  colors: [
                    color.withValues(alpha: opacity),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Subtle breathing opacity animation — makes the UI feel alive
class BreathingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BreathingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<BreathingWidget> createState() => _BreathingWidgetState();
}

class _BreathingWidgetState extends State<BreathingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Opacity(opacity: _animation.value, child: child),
      child: widget.child,
    );
  }
}

/// Premium glass-morphism container for dark mode
class PremiumGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Color? tintColor;
  final Border? border;

  const PremiumGlass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.boxShadow,
    this.onTap,
    this.tintColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        tintColor ??
        (isDark ? AppColors.darkCard : AppColors.glassWhite);
    final bdr =
        border ??
        Border.all(
          color: isDark ? AppColors.frostBorder : AppColors.glassBorder,
        );
    final shadow = boxShadow ?? (isDark ? AppShadows.cardDark : AppShadows.soft);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: bdr,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(onTap: onTap, child: _buildPadding())
              : _buildPadding(),
        ),
      ),
    );
  }

  Widget _buildPadding() {
    return Padding(padding: padding ?? const EdgeInsets.all(16), child: child);
  }
}

/// Staggered entrance animation for list items
class StaggerItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const StaggerItem({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<StaggerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacityAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value.dy * 20),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Animated progress bar with soft glow sweep effect
class GlowProgressBar extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  final double borderRadius;

  const GlowProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.borderRadius = 3,
  });

  @override
  State<GlowProgressBar> createState() => _GlowProgressBarState();
}

class _GlowProgressBarState extends State<GlowProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = widget.value.clamp(0.0, 1.0);
    final color = widget.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        child: Stack(
          children: [
            // Filled progress (no animation, just gradient)
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.55),
                      color.withValues(alpha: 0.85),
                      color,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Water flow animation (only on filled portion)
            if (v > 0.02)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _flowController,
                    builder: (_, __) {
                      final flow = _flowController.value;
                      return LayoutBuilder(
                        builder: (ctx, constraints) {
                          final w = constraints.maxWidth;
                          if (w <= 0) return const SizedBox.shrink();
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // ── Wave 1: bright highlight ──
                              Positioned(
                                left: _waveOffset(flow, w, 60, 1.0),
                                width: 60,
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.40),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // ── Wave 2: secondary highlight ──
                              Positioned(
                                left: _waveOffset(flow, w, 40, 0.65),
                                width: 40,
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.18),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // ── Wave 3: subtle shimmer ──
                              Positioned(
                                left: _waveOffset(flow, w, 25, 0.35),
                                width: 25,
                                top: 0,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.08),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Continuously scrolling wave offset that wraps around seamlessly.
  /// [flow] goes from 0→1, [widthPx] is the wave width, [speed] controls
  /// relative speed of this wave layer.
  double _waveOffset(double flow, double parentW, double widthPx, double speed) {
    final scrollRange = parentW + widthPx;
    final rawPos = flow * speed * scrollRange;
    final modPos = rawPos % scrollRange;
    return modPos - widthPx;
  }
}
