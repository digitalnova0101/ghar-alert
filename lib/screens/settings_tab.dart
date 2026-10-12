import 'package:flutter/material.dart';

import '../alarm_service.dart';
import '../app_state.dart';
import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../native.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cameras_screen.dart';
import 'contacts_screen.dart';
import 'lock_gate.dart';
import 'permissions_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _config = Db.config();
  String _version = '';

  @override
  void initState() {
    super.initState();
    Native.appVersion().then((v) {
      if (mounted) setState(() => _version = v);
    }).catchError((_) {});
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  Future<void> _save(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {
      if (mounted) showSnack(context, tr('save_failed'));
    }
  }

  Future<String?> _pickTime(String current) async {
    final p = current.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(p.first) ?? 22, minute: int.tryParse(p.last) ?? 0),
    );
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<HomeConfig>(
        stream: _config,
        builder: (context, snap) {
          final cfg = snap.data ?? HomeConfig();
          return ListView(
            padding: const EdgeInsets.fromLTRB(Sp.l, Sp.m, Sp.l, Sp.xxl),
            children: [
              Text(tr('tab_settings'), style: Theme.of(context).textTheme.headlineMedium),
              SectionTitle(tr('profile')),
              _group([
                ValueListenableBuilder<String?>(
                  valueListenable: AppState.myName,
                  builder: (context, name, _) => _tile(
                    icon: Icons.person_rounded,
                    color: C.brand,
                    title: tr('your_name'),
                    subtitle: name ?? '—',
                    onTap: () => askName(context, current: name),
                  ),
                ),
                _tile(
                  icon: Icons.translate_rounded,
                  color: C.info,
                  title: tr('language'),
                  subtitle: langName(AppState.lang.value),
                  onTap: () => showLanguageSheet(context),
                ),
              ]),
              SectionTitle(tr('security')),
              _group([
                ValueListenableBuilder<bool>(
                  valueListenable: AppState.lockEnabled,
                  builder: (context, on, _) => _switchTile(
                    icon: Icons.fingerprint_rounded,
                    color: C.safe,
                    title: tr('app_lock'),
                    subtitle: tr('app_lock_sub'),
                    value: on,
                    onChanged: (v) async {
                      if (v) {
                        if (!await canUseLock()) {
                          if (context.mounted) showSnack(context, tr('lock_unsupported'));
                          return;
                        }
                        if (!await authenticate()) return;
                      }
                      await AppState.setLock(v);
                    },
                  ),
                ),
              ]),
              SectionTitle(tr('alarm_rules')),
              _group([
                _switchTile(
                  icon: Icons.nightlight_round,
                  color: C.brand,
                  title: tr('night_mode'),
                  subtitle: tr('night_mode_sub'),
                  value: cfg.nightEnabled,
                  onChanged: (v) => _save(() => Db.setNight(enabled: v)),
                ),
                if (cfg.nightEnabled)
                  _tile(
                    icon: Icons.schedule_rounded,
                    color: C.brand,
                    title: tr('night_hours'),
                    subtitle: '${hhmmLabel(cfg.nightStart)} → ${hhmmLabel(cfg.nightEnd)}',
                    onTap: () async {
                      final s = await _pickTime(cfg.nightStart);
                      if (s == null || !mounted) return;
                      final e = await _pickTime(cfg.nightEnd);
                      if (e == null) return;
                      await _save(() => Db.setNight(start: s, end: e));
                    },
                  ),
                _switchTile(
                  icon: Icons.summarize_rounded,
                  color: C.warn,
                  title: tr('daily_summary'),
                  subtitle: cfg.summaryEnabled
                      ? tr('daily_summary_at', {'t': hhmmLabel(cfg.summaryTime)})
                      : tr('daily_summary_sub'),
                  value: cfg.summaryEnabled,
                  onChanged: (v) => _save(() => Db.setSummary(enabled: v)),
                  onTap: cfg.summaryEnabled
                      ? () async {
                          final t = await _pickTime(cfg.summaryTime);
                          if (t != null) await _save(() => Db.setSummary(time: t));
                        }
                      : null,
                ),
              ]),
              SectionTitle(tr('system')),
              _group([
                _tile(
                  icon: Icons.videocam_rounded,
                  color: C.info,
                  title: tr('cameras'),
                  subtitle: tr('cameras_sub'),
                  onTap: () => _push(const CamerasScreen()),
                ),
                _tile(
                  icon: Icons.contact_phone_rounded,
                  color: C.danger,
                  title: tr('emergency_contacts'),
                  subtitle: tr('n_contacts', {'n': '${cfg.contacts.length}'}),
                  onTap: () => _push(const ContactsScreen()),
                ),
                _tile(
                  icon: Icons.verified_user_rounded,
                  color: C.safe,
                  title: tr('permissions'),
                  subtitle: tr('permissions_sub'),
                  onTap: () => _push(const PermissionsScreen()),
                ),
                _tile(
                  icon: Icons.campaign_rounded,
                  color: C.warn,
                  title: tr('test_alarm'),
                  subtitle: tr('test_alarm_sub'),
                  onTap: () async {
                    await playTestAlarm();
                    if (context.mounted) showSnack(context, tr('test_alarm_hint'));
                  },
                ),
              ]),
              const SizedBox(height: Sp.xl),
              Center(
                child: Text('Ghar Alert ${_version.isEmpty ? '' : 'v$_version'}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return GCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: 2),
      leading: IconBubble(icon, color: color, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null ? null : Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.l, vertical: 2),
      leading: IconBubble(icon, color: color, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: onTap ?? () => onChanged(!value),
    );
  }
}

/// Naam poochne wala dialog (onboarding aur settings dono mein).
Future<void> askName(BuildContext context, {String? current}) async {
  final controller = TextEditingController(text: current ?? '');
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('your_name')),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 30,
        decoration: InputDecoration(hintText: tr('name_hint')),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(tr('save')),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty) return;
  await AppState.setName(name);
  await Db.touchMember();
}

Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in supportedLangs)
            ListTile(
              title: Text(langName(code), style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: AppState.lang.value == code
                  ? const Icon(Icons.check_circle_rounded, color: C.safe)
                  : null,
              onTap: () {
                AppState.setLang(code);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: Sp.l),
        ],
      ),
    ),
  );
}
