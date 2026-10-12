import 'package:flutter/material.dart';

import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bar_chart.dart';
import '../widgets/category_ui.dart';
import '../widgets/common.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  late final DateTime _start = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).subtract(const Duration(days: 6));
  }();
  late final _stream = Db.alertsSince(_start);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<AlertItem>>(
        stream: _stream,
        builder: (context, snap) {
          final list = snap.data ?? const <AlertItem>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, Sp.xxl),
            children: [
              Text(tr('tab_stats'), style: Theme.of(context).textTheme.headlineMedium),
              Text(tr('last_7_days'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: Sp.l),
              _summary(list),
              SectionTitle(tr('alerts_per_day')),
              GCard(child: BarChart(data: _perDay(list))),
              SectionTitle(tr('by_type')),
              _categories(list),
              SectionTitle(tr('by_camera')),
              _cameras(list),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(List<AlertItem> list) {
    final seen = list.where((a) => a.acked).length;
    final times = list.map((a) => a.responseTime).whereType<Duration>().toList();
    final avg = times.isEmpty
        ? null
        : Duration(seconds: times.map((d) => d.inSeconds).reduce((a, b) => a + b) ~/ times.length);

    Widget stat(String value, String label, Color color, IconData icon) => Expanded(
          child: GCard(
            padding: const EdgeInsets.all(Sp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: Sp.s),
                Text(value,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(label, maxLines: 2, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );

    return Row(
      children: [
        stat('${list.length}', tr('total_alerts'), C.brand, Icons.notifications_rounded),
        const SizedBox(width: Sp.s),
        stat(list.isEmpty ? '—' : '${(seen * 100 / list.length).round()}%', tr('seen_rate'), C.safe,
            Icons.visibility_rounded),
        const SizedBox(width: Sp.s),
        stat(avg == null ? '—' : shortDuration(avg), tr('avg_response'), C.warn, Icons.timer_rounded),
      ],
    );
  }

  List<BarDatum> _perDay(List<AlertItem> list) {
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysHi = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
    final names = isHindi ? daysHi : daysEn;
    final counts = List<int>.filled(7, 0);
    for (final a in list) {
      if (a.createdAt == null) continue;
      final day = DateTime(a.createdAt!.year, a.createdAt!.month, a.createdAt!.day);
      final i = day.difference(_start).inDays;
      if (i >= 0 && i < 7) counts[i]++;
    }
    return [
      for (var i = 0; i < 7; i++)
        BarDatum(
          i == 6 ? tr('today') : names[_start.add(Duration(days: i)).weekday - 1],
          counts[i],
          highlight: i == 6,
        ),
    ];
  }

  Widget _categories(List<AlertItem> list) {
    final counts = <Category, int>{};
    for (final a in list) {
      counts[a.category] = (counts[a.category] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return GCard(child: Text(tr('no_data_yet'), style: Theme.of(context).textTheme.bodySmall));
    }
    final total = list.length;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return GCard(
      child: Column(
        children: [
          for (final e in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  IconBubble(categoryIcon(e.key), color: categoryColor(e.key), size: 34),
                  const SizedBox(width: Sp.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(categoryLabel(e.key),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value / total,
                            minHeight: 6,
                            backgroundColor: C.surface2,
                            color: categoryColor(e.key),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cameras(List<AlertItem> list) {
    final counts = <String, int>{};
    for (final a in list) {
      counts[a.camera] = (counts[a.camera] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return GCard(child: Text(tr('no_data_yet'), style: Theme.of(context).textTheme.bodySmall));
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return GCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.s),
      child: Column(
        children: [
          for (final e in sorted)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const IconBubble(Icons.videocam_rounded, color: C.info, size: 34),
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text(tr('n_alerts', {'n': '${e.value}'}),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
