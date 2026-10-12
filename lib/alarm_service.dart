import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String fcmTopic = 'ghar_alerts';
const int alarmNotifId = 1001;
const int infoNotifId = 1002;
const String defaultAlarmChannel = 'ghar_alarm_v1';
const String infoChannelId = 'ghar_info_v1';
const String ackActionId = 'ack';

/// Android ka FLAG_INSISTENT: awaaz tab tak loop mein bajti hai jab tak
/// notification hata na di jaye.
const int _flagInsistent = 4;

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class Prefs {
  static const myName = 'my_name';
  static const alarmChannel = 'alarm_channel';
}

/// App band ho tab bhi FCM yahan aata hai (alag isolate mein).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await initNotifications();
  await handleRemoteMessage(message);
}

Future<void> initNotifications({
  DidReceiveNotificationResponseCallback? onTap,
}) async {
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: onTap,
  );
}

Future<void> handleRemoteMessage(RemoteMessage message) async {
  final data = message.data;
  final type = data['type'];
  if (type == 'alert') {
    await showAlarm(
      alertId: data['alertId'] ?? '',
      camera: data['camera'] ?? 'Camera',
      reason: data['reason'] ?? 'Kuch gadbad dikh rahi hai',
    );
  } else if (type == 'ack') {
    await cancelAlarm();
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString(Prefs.myName);
    final by = data['by'] ?? 'Koi';
    if (by != me) {
      await showInfo('👀 $by dekh raha hai', 'Alarm band kar diya gaya hai.');
    }
  }
}

Future<void> showAlarm({
  required String alertId,
  required String camera,
  required String reason,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final channelId = prefs.getString(Prefs.alarmChannel) ?? defaultAlarmChannel;

  final android = AndroidNotificationDetails(
    channelId,
    'Ghar ka alarm',
    channelDescription: 'Camera mein khatra dikhne par tez alarm',
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
    visibility: NotificationVisibility.public,
    timeoutAfter: 10 * 60 * 1000, // 10 min baad apne aap band
    styleInformation: BigTextStyleInformation(reason),
    actions: const <AndroidNotificationAction>[
      AndroidNotificationAction(
        ackActionId,
        'Main dekh raha hoon',
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

Future<void> cancelAlarm() => notifications.cancel(id: alarmNotifId);

Future<void> showInfo(String title, String body) async {
  const android = AndroidNotificationDetails(
    infoChannelId,
    'Ghar alert updates',
    channelDescription: 'Kisne alert dekha, system ki jaankari',
    importance: Importance.high,
    priority: Priority.high,
  );
  await notifications.show(
    id: infoNotifId,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: android),
  );
}
