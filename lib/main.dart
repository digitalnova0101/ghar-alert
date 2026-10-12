import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_service.dart';
import 'native.dart';
import 'screens/alert_screen.dart';
import 'screens/home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await initNotifications(onTap: _onNotificationTap);

  // Siren wala alarm channel (DND permission mili ho to DND bypass bhi)
  try {
    final channelId = await Native.setupAlarmChannel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.alarmChannel, channelId);
  } catch (_) {}

  await _connectFirebase();

  // Kya app alarm notification se khula? (lock screen full-screen alert)
  final launch = await notifications.getNotificationAppLaunchDetails();
  Widget home = const HomeScreen();
  final resp = launch?.notificationResponse;
  if ((launch?.didNotificationLaunchApp ?? false) &&
      (resp?.payload?.isNotEmpty ?? false)) {
    home = AlertScreen(
      alertId: resp!.payload!,
      autoAck: resp.actionId == ackActionId,
    );
  }

  runApp(GharAlertApp(home: home));
}

Future<void> _connectFirebase() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Auth error: $e');
  }
  try {
    await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
  } catch (e) {
    debugPrint('Topic error: $e');
  }

  // App khula ho tab alert aaye
  FirebaseMessaging.onMessage.listen((message) async {
    await handleRemoteMessage(message);
    if (message.data['type'] == 'alert') {
      _openAlert(message.data['alertId'] ?? '', autoAck: false);
    }
  });
}

void _onNotificationTap(NotificationResponse response) {
  final id = response.payload;
  if (id == null || id.isEmpty) return;
  _openAlert(id, autoAck: response.actionId == ackActionId);
}

void _openAlert(String alertId, {required bool autoAck}) {
  if (alertId.isEmpty) return;
  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (_) => AlertScreen(alertId: alertId, autoAck: autoAck),
  ));
}

class GharAlertApp extends StatelessWidget {
  const GharAlertApp({super.key, required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghar Alert',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC62828),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFFC62828),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
