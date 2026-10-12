import 'package:flutter/material.dart';

import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/alert_tile.dart';
import '../widgets/category_ui.dart';
import '../widgets/common.dart';

class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  final _stream = Db.alerts(limit: 150);
  String _filter = 'all'; // all | unseen | <category name>

  bool _match(AlertItem a) => switch (_filter) {
        'all' => true,
        'unseen' => !a.acked,
        _ => a.category.name == _filter,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<AlertItem>>(
        stream: _stream,
        builder: (context, snap) {
          final all = snap.data ?? const <AlertItem>[];
          final list = all.where(_match).toList();
          final unseen = all.where((a) => !a.acked).length;

          final children = <Widget>[];
          String? lastDay;
          for (final a in list) {
            final day = a.createdAt == null ? '' : _dayLabel(a.createdAt!);
            if (day != lastDay) {
              children.add(SectionTitle(day));
              lastDay = day;
            }
            children.add(AlertTile(alert: a));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(tr('tab_alerts'),
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      if (unseen > 0)
                        Pill(tr('n_unseen', {'n': '$unseen'}),
                            color: C.warn, icon: Icons.visibility_off_rounded),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
                    children: [
                      _chip('all', tr('filter_all'), Icons.all_inclusive_rounded, C.brand),
                      _chip('unseen', tr('filter_unseen'), Icons.visibility_off_rounded, C.warn),
                      for (final c in Category.values)
                        _chip(c.name, categoryLabel(c), categoryIcon(c), categoryColor(c)),
                    ],
                  ),
                ),
              ),
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (list.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.verified_user_rounded,
                    title: _filter == 'all' ? tr('no_alerts_yet') : tr('no_match'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.xxl),
                  sliver: SliverList.list(children: children),
                ),
            ],
          );
        },
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return tr('today');
    if (day == today.subtract(const Duration(days: 1))) return tr('yesterday');
    return dayMonth(d);
  }

  Widget _chip(String key, String label, IconData icon, Color color) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: Sp.s),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon, size: 16, color: selected ? color : C.muted),
        label: Text(label),
        selectedColor: color.withValues(alpha: 0.18),
        side: BorderSide(color: selected ? color : C.border),
        onSelected: (_) => setState(() => _filter = key),
      ),
    );
  }
}
