import 'package:flutter/material.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../native.dart';
import '../screens/contacts_screen.dart';
import '../theme.dart';
import 'common.dart';

Future<void> showEmergencySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StreamBuilder<HomeConfig>(
      stream: Db.config(),
      builder: (ctx, snap) {
        final contacts = snap.data?.contacts ?? const <Contact>[];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Sp.l, 0, Sp.l, Sp.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('emergency'), style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(tr('emergency_sub'), style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: Sp.l),
                _CallTile(
                  name: tr('police_112'),
                  phone: '112',
                  color: C.danger,
                  icon: Icons.local_police_rounded,
                ),
                for (final c in contacts)
                  _CallTile(name: c.name, phone: c.phone, color: C.safe, icon: Icons.person_rounded),
                const SizedBox(height: Sp.s),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactsScreen()));
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(contacts.isEmpty ? tr('add_contacts') : tr('edit_contacts')),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.name, required this.phone, required this.color, required this.icon});
  final String name;
  final String phone;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s),
      child: GCard(
        padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.m),
        onTap: () => Native.dial(phone),
        child: Row(
          children: [
            IconBubble(icon, color: color),
            const SizedBox(width: Sp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(phone, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.call_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
