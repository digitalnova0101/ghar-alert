import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../native.dart';
import '../permissions.dart';
import '../theme.dart';
import '../widgets/alert_tile.dart';
import '../widgets/breathing_shield.dart';
import '../widgets/common.dart';
import '../widgets/emergency_sheet.dart';
import 'cameras_screen.dart';
import 'permissions_screen.dart';
import 'snapshot_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  final _status = Db.status();
  final _config = Db.config();
  final _latest = Db.alerts(limit: 1);
  Timer? _ticker;
  PermStatus? _perms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _checkPerms();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPerms();
  }

  Future<void> _checkPerms() async {
    final p = await PermStatus.check();
    if (mounted) setState(() => _perms = p);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemStatus>(
      stream: _status,
      builder: (context, statusSnap) {
        final status = statusSnap.data ?? SystemStatus();
        return StreamBuilder<HomeConfig>(
          stream: _config,
          builder: (context, cfgSnap) {
            final cfg = cfgSnap.data ?? HomeConfig();
            return SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, Sp.xxl),
                children: [
                  _header(),
                  const SizedBox(height: Sp.l),
                  if (_perms != null && !_perms!.complete) ...[
                    _setupBanner(_perms!),
                    const SizedBox(height: Sp.m),
                  ],
                  _hero(status, cfg),
                  SectionTitle(tr('mode')),
                  _modeSwitch(cfg),
                  if (cfg.nightEnabled) ...[
                    const SizedBox(height: Sp.s),
                    _nightNote(cfg),
                  ],
                  SectionTitle(tr('quick_actions')),
                  _quickActions(),
                  SectionTitle(tr('cameras'),
                      action: tr('manage'),
                      onAction: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const CamerasScreen()))),
                  _cameras(status, cfg),
                  SectionTitle(tr('watcher_phone')),
                  _health(status),
                  SectionTitle(tr('latest_alert'), action: tr('see_all'), onAction: widget.onSeeAll),
                  _latestAlert(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _header() {
    return ValueListenableBuilder<String?>(
      valueListenable: AppState.myName,
      builder: (context, name, _) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting(), style: Theme.of(context).textTheme.bodySmall),
                Text(name ?? 'Ghar Alert', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          IconButton.filledTonal(
            style: IconButton.styleFrom(backgroundColor: C.surface2),
            tooltip: tr('live'),
            onPressed: () async {
              final ok = await Native.openSeeEasy();
              if (!ok && mounted) showSnack(context, tr('seeeasy_missing'));
            },
            icon: const Icon(Icons.videocam_rounded, color: C.text),
          ),
        ],
      ),
    );
  }

  Widget _setupBanner(PermStatus p) {
    return GCard(
      borderColor: C.warn.withValues(alpha: 0.5),
      gradient: C.offGradient,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PermissionsScreen()))
          .then((_) => _checkPerms()),
      child: Row(
        children: [
          const IconBubble(Icons.warning_amber_rounded, color: C.warn),
          const SizedBox(width: Sp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('setup_incomplete'), style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(tr('setup_progress', {'n': '${p.doneCount}', 't': '${p.granted.length}'}),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.warn),
        ],
      ),
    );
  }

  Widget _hero(SystemStatus s, HomeConfig cfg) {
    final online = s.online;
    final color = online ? C.safe : C.warn;
    return GCard(
      gradient: online ? C.safeGradient : C.offGradient,
      borderColor: color.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(Sp.s, Sp.l, Sp.l, Sp.l),
      child: Row(
        children: [
          BreathingShield(
            color: color,
            icon: online ? Icons.shield_rounded : Icons.shield_outlined,
            animate: online,
            size: 64,
          ),
          const SizedBox(width: Sp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online ? tr('status_watching') : tr('status_offline'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  online
                      ? tr('last_check', {'t': timeAgo(s.lastSeen)})
                      : tr('offline_hint', {'t': timeAgo(s.lastSeen)}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Sp.s),
                Pill(
                  cfg.sirenNow ? tr('siren_on') : tr('siren_off'),
                  color: cfg.sirenNow ? C.danger : C.info,
                  icon: cfg.sirenNow ? Icons.campaign_rounded : Icons.notifications_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSwitch(HomeConfig cfg) {
    Widget tile(String mode, IconData icon, String title, String sub, Color color) {
      final selected = cfg.mode == mode;
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : C.surface,
            borderRadius: BorderRadius.circular(Sp.radius),
            border: Border.all(color: selected ? color : C.border, width: selected ? 1.6 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Sp.radius),
            onTap: selected
                ? null
                : () async {
                    HapticFeedback.selectionClick();
                    try {
                      await Db.setMode(mode);
                    } catch (_) {
                      if (mounted) showSnack(context, tr('save_failed'));
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(Sp.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, color: selected ? color : C.muted),
                    const Spacer(),
                    if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
                  ]),
                  const SizedBox(height: Sp.m),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(sub, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('home', Icons.home_rounded, tr('mode_home'), tr('mode_home_sub'), C.info),
        const SizedBox(width: Sp.m),
        tile('away', Icons.directions_car_rounded, tr('mode_away'), tr('mode_away_sub'), C.danger),
      ],
    );
  }

  Widget _nightNote(HomeConfig cfg) {
    final active = cfg.nightActive;
    return Row(
      children: [
        Icon(Icons.nightlight_round, size: 16, color: active ? C.brand : C.faint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            active
                ? tr('night_active', {'e': hhmmLabel(cfg.nightEnd)})
                : tr('night_scheduled', {'s': hhmmLabel(cfg.nightStart), 'e': hhmmLabel(cfg.nightEnd)}),
            style: TextStyle(color: active ? C.brand : C.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _quickActions() {
    Widget action(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
          child: GCard(
            padding: const EdgeInsets.symmetric(vertical: Sp.l, horizontal: Sp.s),
            onTap: onTap,
            child: Column(
              children: [
                IconBubble(icon, color: color, size: 44),
                const SizedBox(height: Sp.s),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        action(Icons.photo_camera_rounded, tr('snapshot_now'), C.brand, () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SnapshotScreen()));
        }),
        const SizedBox(width: Sp.s),
        action(Icons.videocam_rounded, tr('live_view'), C.safe, () async {
          final ok = await Native.openSeeEasy();
          if (!ok && mounted) showSnack(context, tr('seeeasy_missing'));
        }),
        const SizedBox(width: Sp.s),
        action(Icons.sos_rounded, tr('emergency'), C.danger, () => showEmergencySheet(context)),
      ],
    );
  }

  Widget _cameras(SystemStatus s, HomeConfig cfg) {
    if (s.cameras.isEmpty) {
      return GCard(
        child: Text(tr('no_cameras_yet'), style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Wrap(
      spacing: Sp.s,
      runSpacing: Sp.s,
      children: [
        for (final e in s.cameras.entries)
          _cameraChip(e.key, e.value && s.online, cfg.cameras[e.key]?.enabled ?? true),
      ],
    );
  }

  Widget _cameraChip(String name, bool live, bool enabled) {
    final color = !enabled ? C.faint : (live ? C.safe : C.warn);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.s),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live && enabled)
            const PulseDot(size: 7)
          else
            Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(enabled ? Icons.videocam_off_rounded : Icons.pause_circle_rounded,
                  size: 14, color: color),
            ),
          const SizedBox(width: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (!enabled) ...[
            const SizedBox(width: 6),
            Text(tr('paused'), style: const TextStyle(color: C.faint, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _health(SystemStatus s) {
    final p = s.phone;
    if (!p.hasData) {
      return GCard(
        child: Row(
          children: [
            const IconBubble(Icons.phone_android_rounded, color: C.muted),
            const SizedBox(width: Sp.m),
            Expanded(child: Text(tr('health_missing'), style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
    }
    final batt = p.battery ?? 0;
    final battColor = batt <= 20 && p.charging != true ? C.danger : (batt <= 40 ? C.warn : C.safe);
    return GCard(
      child: Row(
        children: [
          Expanded(
            child: _metric(
              icon: p.charging == true
                  ? Icons.battery_charging_full_rounded
                  : (batt > 50 ? Icons.battery_5_bar_rounded : Icons.battery_2_bar_rounded),
              color: battColor,
              value: p.battery == null ? '—' : '$batt%',
              label: p.charging == true ? tr('charging') : tr('on_battery'),
            ),
          ),
          Container(width: 1, height: 40, color: C.border),
          Expanded(
            child: _metric(
              icon: Icons.wifi_rounded,
              color: _signalColor(p.signal),
              value: p.wifi?.isNotEmpty == true ? p.wifi! : 'Wi-Fi',
              label: _signalLabel(p.signal),
            ),
          ),
        ],
      ),
    );
  }

  Color _signalColor(int? dbm) {
    if (dbm == null) return C.muted;
    if (dbm >= -60) return C.safe;
    if (dbm >= -75) return C.warn;
    return C.danger;
  }

  String _signalLabel(int? dbm) {
    if (dbm == null) return tr('signal_unknown');
    if (dbm >= -60) return tr('signal_good');
    if (dbm >= -75) return tr('signal_ok');
    return tr('signal_weak');
  }

  Widget _metric({required IconData icon, required Color color, required String value, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: Sp.s),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _latestAlert() {
    return StreamBuilder<List<AlertItem>>(
      stream: _latest,
      builder: (context, snap) {
        final list = snap.data ?? const <AlertItem>[];
        if (list.isEmpty) {
          return GCard(
            child: Row(
              children: [
                const IconBubble(Icons.verified_user_rounded, color: C.safe),
                const SizedBox(width: Sp.m),
                Expanded(child: Text(tr('no_alerts_yet'))),
              ],
            ),
          );
        }
        return GCard(
          padding: const EdgeInsets.symmetric(horizontal: Sp.m, vertical: Sp.xs),
          child: AlertTile(alert: list.first),
        );
      },
    );
  }
}
