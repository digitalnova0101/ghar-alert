import 'package:flutter/services.dart';

/// Android ke woh kaam jo plugins se nahi hote (MainActivity.kt mein likhe hain).
class Native {
  static const _ch = MethodChannel('ghar_alert/native');

  static Future<String> setupAlarmChannel() async =>
      await _ch.invokeMethod<String>('setupAlarmChannel') ?? 'ghar_alarm_v1';

  static Future<bool> hasDndAccess() async =>
      await _ch.invokeMethod<bool>('hasDndAccess') ?? false;

  static Future<void> openDndSettings() => _ch.invokeMethod('openDndSettings');

  static Future<bool> isIgnoringBattery() async =>
      await _ch.invokeMethod<bool>('isIgnoringBattery') ?? false;

  static Future<void> requestIgnoreBattery() => _ch.invokeMethod('requestIgnoreBattery');

  static Future<bool> canFullScreen() async =>
      await _ch.invokeMethod<bool>('canFullScreen') ?? true;

  static Future<void> openFullScreenSettings() => _ch.invokeMethod('openFullScreenSettings');

  static Future<void> openAppSettings() => _ch.invokeMethod('openAppSettings');

  static Future<bool> openSeeEasy() async =>
      await _ch.invokeMethod<bool>('openSeeEasy') ?? false;

  /// Dialer khulta hai number ke saath (call user khud karta hai).
  static Future<void> dial(String number) =>
      _ch.invokeMethod('dial', {'number': number});

  static Future<String> appVersion() async =>
      await _ch.invokeMethod<String>('appVersion') ?? '';
}
