import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  final _members = Db.members();
  final _alerts = Db.alerts(limit: 150);

  static const _avatarColors = [C.brand, C.safe, C.warn, C.info, Color(0xFFA78BFA), Color(0xFFF472B6)];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Member>>(
        stream: _members,
        builder: (context, mSnap) {
          final members = mSnap.data ?? const <Member>[];
          return StreamBuilder<List<AlertItem>>(
            stream: _alerts,
            builder: (context, aSnap) {
              final alerts = aSnap.data ?? const <AlertItem>[];
              final seenCount = <String, int>{};
              final lastSeen = <String, DateTime>{};
              for (final a in alerts) {
                if (a.ackBy == null) continue;
                seenCount[a.ackBy!] = (seenCount[a.ackBy!] ?? 0) + 1;
                final t = a.ackAt;
                if (t != null && (lastSeen[a.ackBy!] == null || t.isAfter(lastSeen[a.ackBy!]!))) {
                  lastSeen[a.ackBy!] = t;
                }
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, Sp.xxl),
                children: [
                  Text(tr('tab_family'), style: Theme.of(context).textTheme.headlineMedium),
                  Text(tr('family_sub', {'n': '${members.length}'}),
                      style: Theme.of(context).textTheme.bodySmall),
                  SectionTitle(tr('members')),
                  if (members.isEmpty)
                    GCard(child: Text(tr('no_members'), style: Theme.of(context).textTheme.bodySmall))
                  else
                    GCard(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.xs),
                      child: Column(
                        children: [
                          for (var i = 0; i < members.length; i++) ...[
                            if (i > 0) const Divider(),
                            _memberRow(members[i], i, seenCount[members[i].name] ?? 0,
                                lastSeen[members[i].name]),
                          ],
                        ],
                      ),
                    ),
                  SectionTitle(tr('invite')),
                  GCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const IconBubble(Icons.person_add_alt_1_rounded, color: C.safe),
                        const SizedBox(width: Sp.m),
                        Expanded(
                          child: Text(tr('invite_text'), style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _memberRow(Member m, int i, int seen, DateTime? lastAck) {
    final color = _avatarColors[m.name.hashCode.abs() % _avatarColors.length];
    final isMe = m.name == AppState.myName.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.m),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(
                  m.name.isEmpty ? '?' : m.name.characters.first.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              if (m.activeNow)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: C.safe,
                      shape: BoxShape.circle,
                      border: Border.all(color: C.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: Sp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '${m.name} (${tr('you')})' : m.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  m.activeNow ? tr('active_now') : tr('last_active', {'t': timeAgo(m.lastActive)}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (lastAck != null)
                  Text(tr('last_ack', {'t': timeAgo(lastAck)}),
                      style: const TextStyle(color: C.safe, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$seen', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(tr('alerts_seen'), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
