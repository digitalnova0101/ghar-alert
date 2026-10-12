import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_state.dart';
import 'l10n.dart';

const String fcmTopic = 'ghar_alerts';
const int alarmNotifId = 1001;
const int infoNotifId = 1002;
const int quietNotifId = 1003;
const String defaultAlarmChannel = 'ghar_alarm_v1';
const String infoChannelId = 'ghar_info_v1';
const String ackActionId = 'ack';
const String smallIcon = '@drawable/ic_stat_shield';

/// Android ka FLAG_INSISTENT: awaaz tab tak loop mein bajti hai jab tak
/// notification hata na di jaye.
const int _flagInsistent = 4;
const Color _danger = Color(0xFFFF4D4F);
const Color _brand = Color(0xFF7C8CFF);

final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

/// App band ho tab bhi FCM yahan aata hai (alag isolate mein).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await AppState.load();
  await initNotifications();
  await handleRemoteMessage(message);
}

Future<void> initNotifications({DidReceiveNotificationResponseCallback? onTap}) async {
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings(smallIcon),
    ),
    onDidReceiveNotificationResponse: onTap,
  );
}

Future<void> handleRemoteMessage(RemoteMessage message) async {
  final data = message.data;
  switch (data['type']) {
    case 'alert':
      final alertId = data['alertId'] ?? '';
      final camera = data['camera'] ?? 'Camera';
      final reason = data['reason'] ?? tr('alert_default_reason');
      if (data['level'] == 'quiet') {
        await showQuietAlert(alertId: alertId, camera: camera, reason: reason);
      } else {
        await showAlarm(alertId: alertId, camera: camera, reason: reason);
      }
    case 'ack':
      await cancelAlarm();
      await notifications.cancel(id: quietNotifId);
      final by = data['by'] ?? '?';
      if (by != AppState.myName.value) {
        await showInfo(tr('notif_ack_title', {'name': by}), tr('notif_ack_body'));
      }
    case 'summary':
    case 'info':
      await showInfo(data['title'] ?? 'Ghar Alert', data['body'] ?? '');
  }
}

Future<void> showAlarm({
  required String alertId,
  required String camera,
  required String reason,
}) async {
  final channelId = AppState.prefs.getString(Prefs.alarmChannel) ?? defaultAlarmChannel;

  final android = AndroidNotificationDetails(
    channelId,
    tr('channel_alarm'),
    channelDescription: tr('channel_alarm_desc'),
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('siren'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    enableVibration: true,
    vibrationPattern: Int64List.fromList(<int>[0, 800, 400, 800, 400, 800]),
    additionalFlags: Int32List.fromList(<int>[_flagInsistent]),
    ongoing: true,
    autoCancel: false,
    color: _danger,
    colorized: true,
    visibility: NotificationVisibility.public,
    timeoutAfter: 10 * 60 * 1000,
    styleInformation: BigTextStyleInformation(reason),
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        ackActionId,
        tr('btn_ack'),
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
  );

  await notifications.show(
    id: alarmNotifId,
    title: '🚨 $camera',
    body: reason,
    notificationDetails: NotificationDetails(android: android),
    payload: alertId,
  );
}

/// "Ghar pe" mode: siren nahi, normal notification.
Future<void> showQuietAlert({
  required String alertId,
  required String camera,
  required String reason,
}) async {
  final android = AndroidNotificationDetails(
    infoChannelId,
    tr('channel_info'),
    channelDescription: tr('channel_info_desc'),
    importance: Importance.high,
    priority: Priority.high,
    color: _brand,
    styleInformation: BigTextStyleInformation(reason),
  );
  await notifications.show(
    id: quietNotifId,
    title: '👁️ $camera',
    body: reason,
    notificationDetails: NotificationDetails(android: android),
    payload: alertId,
  );
}

Future<void> cancelAlarm() => notifications.cancel(id: alarmNotifId);

Future<void> showInfo(String title, String body) async {
  final android = AndroidNotificationDetails(
    infoChannelId,
    tr('channel_info'),
    channelDescription: tr('channel_info_desc'),
    importance: Importance.high,
    priority: Priority.high,
    color: _brand,
    styleInformation: BigTextStyleInformation(body),
  );
  await notifications.show(
    id: infoNotifId,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(android: android),
  );
}

Future<void> playTestAlarm() => showAlarm(
      alertId: '',
      camera: tr('test_alarm_title'),
      reason: tr('test_alarm_body'),
    );
