import 'package:flutter/services.dart';

/// Android ke woh kaam jo Flutter plugins se nahi hote (MainActivity.kt mein likhe hain).
class Native {
  static const _ch = MethodChannel('ghar_alert/native');

  /// Alarm channel banata hai (siren, alarm volume, DND bypass agar permission hai).
  /// Jo channel id use karni hai woh return karta hai.
  static Future<String> setupAlarmChannel() async =>
      await _ch.invokeMethod<String>('setupAlarmChannel') ?? 'ghar_alarm_v1';

  static Future<bool> hasDndAccess() async =>
      await _ch.invokeMethod<bool>('hasDndAccess') ?? false;

  static Future<void> openDndSettings() => _ch.invokeMethod('openDndSettings');

  static Future<bool> isIgnoringBattery() async =>
      await _ch.invokeMethod<bool>('isIgnoringBattery') ?? false;

  static Future<void> requestIgnoreBattery() =>
      _ch.invokeMethod('requestIgnoreBattery');

  static Future<bool> canFullScreen() async =>
      await _ch.invokeMethod<bool>('canFullScreen') ?? true;

  static Future<void> openFullScreenSettings() =>
      _ch.invokeMethod('openFullScreenSettings');

  static Future<void> openAppSettings() => _ch.invokeMethod('openAppSettings');

  /// SeeEasy app kholta hai. false = app nahi mila.
  static Future<bool> openSeeEasy() async =>
      await _ch.invokeMethod<bool>('openSeeEasy') ?? false;
}
