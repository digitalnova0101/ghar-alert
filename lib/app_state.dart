import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone pe save hone wali settings (har phone ki apni).
class Prefs {
  static const myName = 'my_name';
  static const alarmChannel = 'alarm_channel';
  static const lang = 'lang';
  static const onboarded = 'onboarded';
  static const lockEnabled = 'lock_enabled';
}

class AppState {
  AppState._();

  static late SharedPreferences prefs;

  /// 'hx' = Hinglish, 'en' = English, 'hi' = हिंदी
  static final lang = ValueNotifier<String>('hx');
  static final myName = ValueNotifier<String?>(null);
  static final lockEnabled = ValueNotifier<bool>(false);

  static Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    lang.value = prefs.getString(Prefs.lang) ?? 'hx';
    myName.value = prefs.getString(Prefs.myName);
    lockEnabled.value = prefs.getBool(Prefs.lockEnabled) ?? false;
  }

  static bool get onboarded => prefs.getBool(Prefs.onboarded) ?? false;

  static Future<void> setOnboarded() => prefs.setBool(Prefs.onboarded, true);

  static Future<void> setLang(String v) async {
    await prefs.setString(Prefs.lang, v);
    lang.value = v;
  }

  static Future<void> setName(String v) async {
    await prefs.setString(Prefs.myName, v);
    myName.value = v;
  }

  static Future<void> setLock(bool v) async {
    await prefs.setBool(Prefs.lockEnabled, v);
    lockEnabled.value = v;
  }
}
