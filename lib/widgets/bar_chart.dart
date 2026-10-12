import 'package:flutter/material.dart';

import '../theme.dart';

class BarDatum {
  BarDatum(this.label, this.value, {this.highlight = false});
  final String label;
  final int value;
  final bool highlight;
}

/// Simple, saaf bar chart (koi extra package nahi).
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.data, this.height = 160, this.color = C.brand});
  final List<BarDatum> data;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = data.fold<int>(0, (m, d) => d.value > m ? d.value : m);
    return SizedBox(
      height: height + 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in data)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.value == 0 ? '' : '${d.value}',
                    style: TextStyle(
                      color: d.highlight ? C.text : C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: maxV == 0 ? 0 : d.value / maxV),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) => Container(
                      height: 6 + (height - 6) * f,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: d.value == 0
                              ? [C.surface2, C.surface2]
                              : [color.withValues(alpha: d.highlight ? 0.9 : 0.45), color],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.label,
                    style: TextStyle(
                      color: d.highlight ? C.text : C.muted,
                      fontSize: 11.5,
                      fontWeight: d.highlight ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
