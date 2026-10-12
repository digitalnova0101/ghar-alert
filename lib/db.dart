import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_state.dart';
import 'models.dart';

/// Firestore ke saare reads/writes ek jagah.
class Db {
  Db._();
  static final _f = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _config =>
      _f.collection('config').doc('main');

  static Stream<SystemStatus> status() => _f
      .collection('status')
      .doc('system')
      .snapshots()
      .map(SystemStatus.fromDoc)
      .handleError((_) {});

  static Stream<HomeConfig> config() =>
      _config.snapshots().map(HomeConfig.fromDoc).handleError((_) {});

  static Stream<List<AlertItem>> alerts({int limit = 100}) => _f
      .collection('alerts')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(AlertItem.fromDoc).toList());

  static Stream<List<AlertItem>> alertsSince(DateTime since) => _f
      .collection('alerts')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(AlertItem.fromDoc).toList());

  static Stream<AlertItem?> alert(String id) => _f
      .collection('alerts')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? AlertItem.fromDoc(d) : null);

  static Stream<List<Member>> members() => _f
      .collection('members')
      .orderBy('lastActive', descending: true)
      .snapshots()
      .map((q) => q.docs.map(Member.fromDoc).toList());

  static Stream<List<Snapshot>> snapshots() => _f
      .collection('snapshots')
      .snapshots()
      .map((q) => q.docs.map(Snapshot.fromDoc).toList()
        ..sort((a, b) => a.camera.compareTo(b.camera)));

  static String get _me => AppState.myName.value ?? 'Koi';

  /// "Main dekh raha hoon" - sirf pehla insaan likh sakta hai.
  static Future<void> acknowledge(String alertId) async {
    final ref = _f.collection('alerts').doc(alertId);
    await _f.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists && snap.data()?['ackBy'] == null) {
        tx.update(ref, {'ackBy': _me, 'ackAt': FieldValue.serverTimestamp()});
      }
    });
  }

  static Future<void> _setConfig(Map<String, dynamic> data) => _config.set({
        ...data,
        'updatedBy': _me,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  static Future<void> setMode(String mode) => _setConfig({'mode': mode});

  static Future<void> setNight({bool? enabled, String? start, String? end}) =>
      _setConfig({
        'night': {
          'enabled': ?enabled,
          'start': ?start,
          'end': ?end,
        }
      });

  static Future<void> setSummary({bool? enabled, String? time}) => _setConfig({
        'summary': {
          'enabled': ?enabled,
          'time': ?time,
        }
      });

  static Future<void> setCamera(String name, CameraConfig c) =>
      _setConfig({'cameras': {name: c.toMap()}});

  static Future<void> setContacts(List<Contact> list) =>
      _setConfig({'contacts': list.map((c) => c.toMap()).toList()});

  static Future<void> requestSnapshot() => _f.collection('requests').doc('snapshot').set({
        'requestedAt': FieldValue.serverTimestamp(),
        'by': _me,
      });

  /// Family list ke liye: main kaun hoon, kab active tha.
  static Future<void> touchMember() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = AppState.myName.value;
    if (uid == null || name == null) return;
    await _f.collection('members').doc(uid).set({
      'name': name,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
