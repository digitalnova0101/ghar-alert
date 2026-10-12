import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarm_service.dart';
import 'app_state.dart';
import 'native.dart';

AndroidFlutterLocalNotificationsPlugin? get androidNotifs =>
    notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

enum Perm { notifications, fullScreen, dnd, battery }

class PermStatus {
  final Map<Perm, bool> granted;
  PermStatus(this.granted);

  bool get complete => granted.values.every((v) => v);
  int get doneCount => granted.values.where((v) => v).length;
  bool operator [](Perm p) => granted[p] ?? false;

  static Future<PermStatus> check() async {
    final map = <Perm, bool>{
      Perm.notifications: await androidNotifs?.areNotificationsEnabled() ?? false,
      Perm.fullScreen: await _safe(Native.canFullScreen, true),
      Perm.dnd: await _safe(Native.hasDndAccess, false),
      Perm.battery: await _safe(Native.isIgnoringBattery, false),
    };
    if (map[Perm.dnd] == true) await refreshAlarmChannel();
    return PermStatus(map);
  }

  static Future<bool> _safe(Future<bool> Function() f, bool fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }
}

/// DND permission milte hi naya channel (DND bypass ke saath) banao.
Future<void> refreshAlarmChannel() async {
  try {
    final id = await Native.setupAlarmChannel();
    await AppState.prefs.setString(Prefs.alarmChannel, id);
  } catch (_) {}
}

Future<void> requestPerm(Perm p) async {
  switch (p) {
    case Perm.notifications:
      final ok = await androidNotifs?.requestNotificationsPermission() ?? false;
      if (!ok) await Native.openAppSettings();
    case Perm.fullScreen:
      await Native.openFullScreenSettings();
    case Perm.dnd:
      await Native.openDndSettings();
    case Perm.battery:
      await Native.requestIgnoreBattery();
  }
}
