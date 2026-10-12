import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../alarm_service.dart';
import '../name_dialog.dart';
import '../native.dart';

AndroidFlutterLocalNotificationsPlugin? get _androidNotifs =>
    notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

class SetupStatus {
  bool notifications = false;
  bool fullScreen = false;
  bool dnd = false;
  bool battery = false;

  bool get complete => notifications && fullScreen && dnd && battery;

  static Future<SetupStatus> check() async {
    final s = SetupStatus();
    s.notifications = await _androidNotifs?.areNotificationsEnabled() ?? false;
    s.fullScreen = await Native.canFullScreen();
    s.dnd = await Native.hasDndAccess();
    s.battery = await Native.isIgnoringBattery();
    return s;
  }
}

/// Test alarm: 2 baar beep ke baad "Main dekh raha hoon" dabake band karo.
Future<void> playTestAlarm() => showAlarm(
      alertId: '',
      camera: 'Test alarm',
      reason: 'Sab theek hai. Band karne ke liye "Main dekh raha hoon" dabao.',
    );

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  SetupStatus? _status;
  String? _name;

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
    // Settings se wapas aaye to dobara check karo
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await SetupStatus.check();
    if (s.dnd) {
      // DND permission milte hi naya channel (DND bypass ke saath) banao
      final id = await Native.setupAlarmChannel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Prefs.alarmChannel, id);
    }
    final name = await getMyName();
    if (mounted) {
      setState(() {
        _status = s;
        _name = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Yeh sab ✅ hone chahiye, tabhi silent phone pe bhi alarm bajega.',
                  ),
                ),
                _item(
                  ok: s.notifications,
                  title: 'Notifications',
                  subtitle: 'Alert dikhane ki permission',
                  onFix: () => _androidNotifs?.requestNotificationsPermission(),
                ),
                _item(
                  ok: s.fullScreen,
                  title: 'Full-screen alert',
                  subtitle: 'Lock screen pe call jaisi screen khule',
                  onFix: Native.openFullScreenSettings,
                ),
                _item(
                  ok: s.dnd,
                  title: 'Do Not Disturb mein bhi bajao',
                  subtitle: 'List mein "Ghar Alert" ko allow karo',
                  onFix: Native.openDndSettings,
                ),
                _item(
                  ok: s.battery,
                  title: 'Battery restriction hatao',
                  subtitle: 'Warna phone app ko sula deta hai',
                  onFix: Native.requestIgnoreBattery,
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch_outlined),
                  title: const Text('Auto-start (Realme/Oppo/Vivo/Mi)'),
                  subtitle: const Text(
                    'App info → Battery/Auto launch mein "Allow" karo. '
                    'Isse band app bhi alert pe jaag jayega.',
                  ),
                  trailing: TextButton(
                    onPressed: Native.openAppSettings,
                    child: const Text('Kholo'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Aapka naam'),
                  subtitle: Text(_name ?? 'Abhi set nahi hai'),
                  trailing: TextButton(
                    onPressed: () async {
                      final n = await askMyName(context, current: _name);
                      if (mounted) setState(() => _name = n);
                    },
                    child: const Text('Badlo'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () async {
                      await playTestAlarm();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Phone silent karke bhi test karo'),
                        action: SnackBarAction(
                          label: 'Band karo',
                          onPressed: cancelAlarm,
                        ),
                      ));
                    },
                    icon: const Icon(Icons.campaign),
                    label: const Text('Alarm test karo'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _item({
    required bool ok,
    required String title,
    required String subtitle,
    required VoidCallback onFix,
  }) {
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.error,
        color: ok ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ok
          ? null
          : FilledButton.tonal(onPressed: onFix, child: const Text('Theek karo')),
    );
  }
}
