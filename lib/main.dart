import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alarm_service.dart';
import 'app_state.dart';
import 'db.dart';
import 'permissions.dart';
import 'screens/alert_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  await AppState.load();
  await initNotifications(onTap: _onNotificationTap);
  await refreshAlarmChannel();
  await _connectFirebase();

  // App alarm notification se khula? (lock screen pe full-screen alert)
  final launch = await notifications.getNotificationAppLaunchDetails();
  Widget home = const SplashScreen();
  final resp = launch?.notificationResponse;
  if ((launch?.didNotificationLaunchApp ?? false) && (resp?.payload?.isNotEmpty ?? false)) {
    home = AlertScreen(alertId: resp!.payload!, autoAck: resp.actionId == ackActionId);
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
  Db.touchMember().ignore();

  FirebaseMessaging.onMessage.listen((message) async {
    await handleRemoteMessage(message);
    if (message.data['type'] == 'alert' && message.data['level'] != 'quiet') {
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

class GharAlertApp extends StatefulWidget {
  const GharAlertApp({super.key, required this.home});
  final Widget home;

  @override
  State<GharAlertApp> createState() => _GharAlertAppState();
}

class _GharAlertAppState extends State<GharAlertApp> {
  @override
  void initState() {
    super.initState();
    AppState.lang.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    AppState.lang.removeListener(_rebuildAll);
    super.dispose();
  }

  /// Bhasha badalne pe har screen dobara banao (navigation waisi hi rahe).
  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghar Alert',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      home: widget.home,
    );
  }
}
