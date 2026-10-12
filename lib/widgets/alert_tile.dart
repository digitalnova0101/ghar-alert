import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../screens/alert_screen.dart';
import '../theme.dart';
import 'category_ui.dart';

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});
  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(alert.category);
    return InkWell(
      borderRadius: BorderRadius.circular(Sp.radius),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AlertScreen(alertId: alert.id),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.s),
        child: Row(
          children: [
            Hero(
              tag: 'alert-img-${alert.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Sp.radiusS),
                child: SizedBox(
                  width: 84,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (alert.image != null)
                        Image.memory(alert.image!, fit: BoxFit.cover, gaplessPlayback: true)
                      else
                        Container(color: C.surface2),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(categoryIcon(alert.category), size: 14, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: Sp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.camera} · ${formatTime(alert.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        alert.acked ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        size: 14,
                        color: alert.acked ? C.safe : C.warn,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          alert.acked
                              ? tr('seen_by', {'name': alert.ackBy!})
                              : tr('not_seen'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: alert.acked ? C.safe : C.warn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
