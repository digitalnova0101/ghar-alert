import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db.dart';
import '../l10n.dart';
import '../models.dart';
import '../native.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _config = Db.config();

  Future<void> _save(List<Contact> list) async {
    try {
      await Db.setContacts(list);
    } catch (_) {
      if (mounted) showSnack(context, tr('save_failed'));
    }
  }

  Future<void> _add(List<Contact> current) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_contact')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: tr('contact_name_hint')),
            ),
            const SizedBox(height: Sp.m),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              decoration: InputDecoration(hintText: tr('contact_phone_hint')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final n = name.text.trim(), p = phone.text.trim();
    if (n.isEmpty || p.isEmpty) return;
    await _save([...current, Contact(n, p)]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeConfig>(
      stream: _config,
      builder: (context, snap) {
        final list = snap.data?.contacts ?? const <Contact>[];
        return Scaffold(
          appBar: AppBar(title: Text(tr('emergency_contacts'))),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: C.brand,
            foregroundColor: Colors.white,
            onPressed: () => _add(list),
            icon: const Icon(Icons.add_rounded),
            label: Text(tr('add_contact')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.s, Sp.l, 100),
            children: [
              Text(tr('contacts_explain'), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: Sp.l),
              GCard(
                padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.xs),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconBubble(Icons.local_police_rounded, color: C.danger),
                  title: Text(tr('police_112'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(tr('always_shown'), style: Theme.of(context).textTheme.bodySmall),
                  trailing: IconButton(
                    onPressed: () => Native.dial('112'),
                    icon: const Icon(Icons.call_rounded, color: C.danger),
                  ),
                ),
              ),
              const SizedBox(height: Sp.m),
              if (list.isEmpty)
                EmptyState(icon: Icons.contact_phone_rounded, title: tr('no_contacts'))
              else
                GCard(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: Sp.xs),
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const IconBubble(Icons.person_rounded, color: C.safe),
                          title: Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(list[i].phone, style: Theme.of(context).textTheme.bodySmall),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => Native.dial(list[i].phone),
                                icon: const Icon(Icons.call_rounded, color: C.safe),
                              ),
                              IconButton(
                                onPressed: () => _save([...list]..removeAt(i)),
                                icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
