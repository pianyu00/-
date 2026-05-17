import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spring bounce tap wrapper — scales down 10% on press with elastic bounce.
class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BounceTap({super.key, required this.child, this.onTap});

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _a = CurvedAnimation(parent: _c, curve: Curves.elasticInOut);
  }

  void _down(_) => _c.forward();
  void _up(_) => _c.reverse();
  void _cancel() => _c.reverse();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _a,
        builder: (ctx, child) =>
            Transform.scale(scale: 1.0 - _a.value * 0.1, child: child),
        child: widget.child,
      ),
    );
  }
}
