import 'package:flutter/services.dart';

/// Siren jo alarm volume pe bajta hai (notification sound pe nirbhar nahi).
/// App band ho tab bhi chalta hai (background FCM handler se).
class Siren {
  static const _ch = MethodChannel('ghar_alert/siren');

  static Future<void> start({String title = '', String body = ''}) async {
    try {
      await _ch.invokeMethod('start', {'title': title, 'body': body});
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }

  static Future<bool> isPlaying() async {
    try {
      return await _ch.invokeMethod<bool>('isPlaying') ?? false;
    } catch (_) {
      return false;
    }
  }
}
