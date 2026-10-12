import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

enum Category { dog, person, animal, fire, other }

Category categoryFrom(String? v) => switch (v) {
      'dog' => Category.dog,
      'person' => Category.person,
      'animal' => Category.animal,
      'fire' => Category.fire,
      _ => Category.other,
    };

class AlertItem {
  AlertItem({
    required this.id,
    required this.camera,
    required this.reason,
    required this.category,
    required this.level,
    this.createdAt,
    this.image,
    this.ackBy,
    this.ackAt,
  });

  final String id;
  final String camera;
  final String reason;
  final Category category;
  final String level; // 'alarm' | 'quiet'
  final DateTime? createdAt;
  final Uint8List? image;
  final String? ackBy;
  final DateTime? ackAt;

  bool get acked => ackBy != null;

  Duration? get responseTime =>
      (createdAt != null && ackAt != null) ? ackAt!.difference(createdAt!) : null;

  factory AlertItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final img = d['image'];
    return AlertItem(
      id: doc.id,
      camera: (d['camera'] as String?) ?? 'Camera',
      reason: (d['reason'] as String?) ?? '',
      category: categoryFrom(d['category'] as String?),
      level: (d['level'] as String?) ?? 'alarm',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      image: img is Blob ? img.bytes : null,
      ackBy: d['ackBy'] as String?,
      ackAt: (d['ackAt'] as Timestamp?)?.toDate(),
    );
  }
}

class PhoneHealth {
  PhoneHealth({this.battery, this.charging, this.wifi, this.signal});
  final int? battery;
  final bool? charging;
  final String? wifi;
  final int? signal; // dBm

  bool get hasData => battery != null || wifi != null || signal != null;

  factory PhoneHealth.from(Map<String, dynamic>? m) => PhoneHealth(
        battery: (m?['battery'] as num?)?.toInt(),
        charging: m?['charging'] as bool?,
        wifi: m?['wifi'] as String?,
        signal: (m?['signal'] as num?)?.toInt(),
      );
}

class SystemStatus {
  SystemStatus({this.lastSeen, this.cameras = const {}, PhoneHealth? phone})
      : phone = phone ?? PhoneHealth();

  final DateTime? lastSeen;
  final Map<String, bool> cameras;
  final PhoneHealth phone;

  bool get online =>
      lastSeen != null && DateTime.now().difference(lastSeen!).inMinutes < 3;

  factory SystemStatus.fromDoc(DocumentSnapshot<Map<String, dynamic>>? doc) {
    final d = doc?.data();
    final cams = <String, bool>{};
    (d?['cameras'] as Map<String, dynamic>?)?.forEach((k, v) => cams[k] = v == true);
    return SystemStatus(
      lastSeen: (d?['lastSeen'] as Timestamp?)?.toDate(),
      cameras: cams,
      phone: PhoneHealth.from(d?['phone'] as Map<String, dynamic>?),
    );
  }
}

class CameraConfig {
  CameraConfig({this.enabled = true, this.sensitivity = 'medium'});
  final bool enabled;
  final String sensitivity; // low | medium | high

  Map<String, dynamic> toMap() => {'enabled': enabled, 'sensitivity': sensitivity};

  factory CameraConfig.from(Map<String, dynamic>? m) => CameraConfig(
        enabled: (m?['enabled'] as bool?) ?? true,
        sensitivity: (m?['sensitivity'] as String?) ?? 'medium',
      );
}

class Contact {
  Contact(this.name, this.phone);
  final String name;
  final String phone;
  Map<String, dynamic> toMap() => {'name': name, 'phone': phone};
}

/// Pure ghar ki shared settings (Firestore config/main). Sab family ke liye same.
class HomeConfig {
  HomeConfig({
    this.mode = 'away',
    this.nightEnabled = true,
    this.nightStart = '22:00',
    this.nightEnd = '06:00',
    this.summaryEnabled = true,
    this.summaryTime = '21:00',
    this.cameras = const {},
    this.contacts = const [],
  });

  final String mode; // 'away' (bahar: full siren) | 'home' (ghar pe: halka)
  final bool nightEnabled;
  final String nightStart;
  final String nightEnd;
  final bool summaryEnabled;
  final String summaryTime;
  final Map<String, CameraConfig> cameras;
  final List<Contact> contacts;

  bool get isHome => mode == 'home';

  /// Abhi raat wala auto mode chal raha hai?
  bool get nightActive {
    if (!nightEnabled) return false;
    final now = DateTime.now();
    final mins = now.hour * 60 + now.minute;
    final s = _mins(nightStart), e = _mins(nightEnd);
    return s <= e ? (mins >= s && mins < e) : (mins >= s || mins < e);
  }

  /// Is waqt alert aaye to siren bajega?
  bool get sirenNow => !isHome || nightActive;

  static int _mins(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p.first) ?? 0) * 60 + (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
  }

  factory HomeConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>>? doc) {
    final d = doc?.data();
    final night = d?['night'] as Map<String, dynamic>?;
    final summary = d?['summary'] as Map<String, dynamic>?;
    final cams = <String, CameraConfig>{};
    (d?['cameras'] as Map<String, dynamic>?)?.forEach(
        (k, v) => cams[k] = CameraConfig.from(v as Map<String, dynamic>?));
    final contacts = <Contact>[];
    for (final c in (d?['contacts'] as List<dynamic>?) ?? const []) {
      if (c is Map) {
        contacts.add(Contact('${c['name'] ?? ''}', '${c['phone'] ?? ''}'));
      }
    }
    return HomeConfig(
      mode: (d?['mode'] as String?) ?? 'away',
      nightEnabled: (night?['enabled'] as bool?) ?? true,
      nightStart: (night?['start'] as String?) ?? '22:00',
      nightEnd: (night?['end'] as String?) ?? '06:00',
      summaryEnabled: (summary?['enabled'] as bool?) ?? true,
      summaryTime: (summary?['time'] as String?) ?? '21:00',
      cameras: cams,
      contacts: contacts,
    );
  }
}

class Member {
  Member({required this.id, required this.name, this.lastActive});
  final String id;
  final String name;
  final DateTime? lastActive;

  bool get activeNow =>
      lastActive != null && DateTime.now().difference(lastActive!).inMinutes < 10;

  factory Member.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Member(
      id: doc.id,
      name: (d['name'] as String?) ?? '?',
      lastActive: (d['lastActive'] as Timestamp?)?.toDate(),
    );
  }
}

class Snapshot {
  Snapshot({required this.camera, this.image, this.createdAt});
  final String camera;
  final Uint8List? image;
  final DateTime? createdAt;

  factory Snapshot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final img = d['image'];
    return Snapshot(
      camera: (d['camera'] as String?) ?? doc.id,
      image: img is Blob ? img.bytes : null,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
