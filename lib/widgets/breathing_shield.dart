import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Home screen ka bada shield: online ho to "saans leta" hai.
class BreathingShield extends StatefulWidget {
  const BreathingShield({
    super.key,
    required this.color,
    required this.icon,
    this.animate = true,
    this.size = 92,
  });

  final Color color;
  final IconData icon;
  final bool animate;
  final double size;

  @override
  State<BreathingShield> createState() => _BreathingShieldState();
}

class _BreathingShieldState extends State<BreathingShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant BreathingShield old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) {
      _c.stop();
      _c.value = 0.25;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.7,
      height: s * 1.7,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final breath = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              // bahar jaati lehrein
              for (final offset in [0.0, 0.5])
                Opacity(
                  opacity: widget.animate ? (1 - ((t + offset) % 1)) * 0.5 : 0,
                  child: Container(
                    width: s * (1 + 0.7 * ((t + offset) % 1)),
                    height: s * (1 + 0.7 * ((t + offset) % 1)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color.withValues(alpha: 0.6), width: 1.5),
                    ),
                  ),
                ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    widget.color.withValues(alpha: 0.35),
                    widget.color.withValues(alpha: 0.08),
                  ]),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25 + 0.25 * breath),
                      blurRadius: 24 + 16 * breath,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: 1 + 0.05 * breath,
                  child: Icon(widget.icon, color: widget.color, size: s * 0.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
