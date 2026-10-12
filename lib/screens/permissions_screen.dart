import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../l10n.dart';
import '../native.dart';
import '../permissions.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Permissions ki checklist (onboarding aur settings dono mein).
class PermissionsList extends StatefulWidget {
  const PermissionsList({super.key, this.onChanged});
  final ValueChanged<PermStatus>? onChanged;

  @override
  State<PermissionsList> createState() => _PermissionsListState();
}

class _PermissionsListState extends State<PermissionsList> with WidgetsBindingObserver {
  PermStatus? _s;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await PermStatus.check();
    if (!mounted) return;
    setState(() => _s = s);
    widget.onChanged?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) return const Center(child: CircularProgressIndicator());
    Perm? next;
    for (final p in Perm.values) {
      if (!s[p]) {
        next = p;
        break;
      }
    }
    return Column(
      children: [
        _item(s, Perm.notifications, Icons.notifications_active_rounded, tr('perm_notif'), tr('perm_notif_sub'), next),
        _item(s, Perm.fullScreen, Icons.fullscreen_rounded, tr('perm_full'), tr('perm_full_sub'), next),
        _item(s, Perm.dnd, Icons.do_not_disturb_off_rounded, tr('perm_dnd'), tr('perm_dnd_sub'), next),
        _item(s, Perm.battery, Icons.battery_saver_rounded, tr('perm_battery'), tr('perm_battery_sub'), next),
        const SizedBox(height: Sp.s),
        GCard(
          onTap: Native.openAppSettings,
          child: Row(
            children: [
              const IconBubble(Icons.rocket_launch_rounded, color: C.brand),
              const SizedBox(width: Sp.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('perm_autostart'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(tr('perm_autostart_sub'), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: C.muted, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(PermStatus s, Perm p, IconData icon, String title, String sub, Perm? next) {
    final ok = s[p];
    final isNext = next == p;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.s),
      child: GCard(
        borderColor: isNext ? C.brand : (ok ? C.safe.withValues(alpha: 0.35) : null),
        onTap: ok ? null : () => requestPerm(p).then((_) => _refresh()),
        child: Row(
          children: [
            IconBubble(ok ? Icons.check_rounded : icon, color: ok ? C.safe : (isNext ? C.brand : C.muted)),
            const SizedBox(width: Sp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (!ok)
              Text(tr('allow'), style: TextStyle(color: isNext ? C.brand : C.muted, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('permissions'))),
      body: ListView(
        padding: const EdgeInsets.all(Sp.l),
        children: [
          Text(tr('perm_explain'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Sp.l),
          const PermissionsList(),
          const SizedBox(height: Sp.l),
          OutlinedButton.icon(
            onPressed: () async {
              await playTestAlarm();
              if (context.mounted) showSnack(context, tr('test_alarm_hint'));
            },
            icon: const Icon(Icons.campaign_rounded),
            label: Text(tr('test_alarm')),
          ),
        ],
      ),
    );
  }
}
