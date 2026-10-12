import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// "Swipe karke confirm" button - galti se dabne ka dar nahi.
class SwipeConfirm extends StatefulWidget {
  const SwipeConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.color = C.danger,
    this.icon = Icons.front_hand_rounded,
    this.enabled = true,
  });

  final String label;
  final Future<void> Function() onConfirm;
  final Color color;
  final IconData icon;
  final bool enabled;

  @override
  State<SwipeConfirm> createState() => _SwipeConfirmState();
}

class _SwipeConfirmState extends State<SwipeConfirm> with SingleTickerProviderStateMixin {
  static const _h = 64.0;
  static const _thumb = 56.0;
  double _drag = 0;
  bool _done = false;
  late final AnimationController _back =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _back.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final max = box.maxWidth - _thumb - 8;
      final progress = max <= 0 ? 0.0 : (_drag / max).clamp(0.0, 1.0);
      return Container(
        height: _h,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(_h / 2),
          border: Border.all(color: widget.color.withValues(alpha: 0.5)),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // bhara hua hissa
            Container(
              width: _drag + _thumb + 8,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(_h / 2),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, child) => ShaderMask(
                  shaderCallback: (r) => LinearGradient(
                    colors: const [Colors.white54, Colors.white, Colors.white54],
                    stops: [
                      (_shimmer.value - 0.3).clamp(0.0, 1.0),
                      _shimmer.value,
                      (_shimmer.value + 0.3).clamp(0.0, 1.0),
                    ],
                  ).createShader(r),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: _thumb),
                  child: Opacity(
                    opacity: 1 - progress,
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4 + _drag,
              child: GestureDetector(
                onHorizontalDragUpdate: (!widget.enabled || _done)
                    ? null
                    : (d) => setState(() => _drag = (_drag + d.delta.dx).clamp(0.0, max)),
                onHorizontalDragEnd: (!widget.enabled || _done)
                    ? null
                    : (_) async {
                        if (progress > 0.85) {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _done = true;
                            _drag = max;
                          });
                          await widget.onConfirm();
                        } else {
                          final start = _drag;
                          _back.reset();
                          void tick() => setState(() => _drag = start * (1 - _back.value));
                          _back.addListener(tick);
                          await _back.forward();
                          _back.removeListener(tick);
                        }
                      },
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 16),
                    ],
                  ),
                  child: Icon(_done ? Icons.check_rounded : widget.icon,
                      color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
